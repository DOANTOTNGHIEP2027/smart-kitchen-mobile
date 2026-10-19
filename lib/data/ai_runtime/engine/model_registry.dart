import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../utils/sha256.dart';
import 'ai_task.dart';
import 'model_manifest.dart';

/// Đọc asset theo đường dẫn — inject để test không cần rootBundle thật.
typedef AssetBytesLoader = Future<ByteData> Function(String path);

/// Task → manifest + trạng thái khả dụng (§5.3). Asset đều nằm sẵn trong app
/// bundle — KHÔNG tải qua network (Guard #6).
class ModelRegistry {
  ModelRegistry({AssetBytesLoader? loader, this.modelVersions = defaultVersions})
      : _load = loader ?? rootBundle.load;

  /// Version đang ship của mỗi task — đổi khi thêm thư mục `v<N>` mới.
  static const Map<AITask, int> defaultVersions = <AITask, int>{
    AITask.receiptOcr: 1,
    AITask.calorieEstimate: 1,
    AITask.repetitionScore: 1,
    AITask.ruleBasedSelection: 1,
  };

  final AssetBytesLoader _load;
  final Map<AITask, int> modelVersions;
  final Map<AITask, ModelManifest> _manifests = <AITask, ModelManifest>{};
  final Map<AITask, Uint8List> _payloads = <AITask, Uint8List>{};

  String _dir(AITask task) => 'assets/models/${task.assetDir}/v${modelVersions[task]}';

  /// Đọc + verify checksum MỌI task. Lỗi ở 1 task chỉ tắt on-device của đúng
  /// task đó — không throw, không crash app (Guard #7).
  Future<void> bootstrap() async {
    // Các task độc lập nhau — nạp song song thay vì tuần tự.
    await Future.wait<void>(AITask.values.map(_bootstrapTask));
  }

  Future<void> _bootstrapTask(AITask task) async {
    try {
      final meta = await _load('${_dir(task)}/metadata.json');
      final manifest = ModelManifest.fromJson(
        task,
        jsonDecode(utf8.decode(meta.buffer.asUint8List(meta.offsetInBytes, meta.lengthInBytes)))
            as Map<String, dynamic>,
      );
      if (manifest.modelVersion != modelVersions[task]) {
        throw FormatException('modelVersion ${manifest.modelVersion} != ${_dir(task)}');
      }
      if (manifest.payloadFile != null) {
        final raw = await _load('${_dir(task)}/${manifest.payloadFile}');
        final bytes = raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes);
        if (sha256Hex(bytes) != manifest.checksumSha256) {
          throw FormatException('checksum mismatch for ${task.assetDir}');
        }
        _payloads[task] = bytes;
      }
      _manifests[task] = manifest;
    } catch (_) {
      _manifests.remove(task);
      _payloads.remove(task);
    }
  }

  bool isAvailable(AITask task) => _manifests.containsKey(task);

  /// Chỉ gọi sau khi [isAvailable] == true.
  ModelManifest manifestFor(AITask task) => _manifests[task]!;

  /// Payload đã verify checksum (vd. rules_config.json) — `null` nếu không có.
  Uint8List? payloadFor(AITask task) => _payloads[task];
}
