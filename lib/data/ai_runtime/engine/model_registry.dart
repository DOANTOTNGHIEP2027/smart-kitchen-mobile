import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../utils/sha256.dart';
import 'ai_task.dart';
import 'model_manifest.dart';

/// Đọc asset theo đường dẫn — inject để test không cần rootBundle thật.
typedef AssetBytesLoader = Future<ByteData> Function(String path);

/// Vì sao một task không khả dụng on-device — chỉ để log/test, UI không đổi
/// (on-device-ai-runtime.md §5.4.7).
enum ModelUnavailableReason {
  notBootstrapped,
  missing,
  invalidManifest,
  appTooOld,
  checksumMismatch,
  payloadNotShipped,
}

class _Unavailable implements Exception {
  const _Unavailable(this.reason, this.detail);
  final ModelUnavailableReason reason;
  final String detail;
}

/// Task → manifest + trạng thái khả dụng (§5.3, §5.4). Asset đều nằm sẵn trong
/// app bundle — KHÔNG tải qua network (Guard #6).
///
/// `isAvailable` = package HỢP LỆ, không đảm bảo engine chạy được (§5.4.4).
class ModelRegistry {
  ModelRegistry({
    required this.appVersion,
    AssetBytesLoader? loader,
    this.modelVersions = defaultVersions,
  }) : _load = loader ?? rootBundle.load;

  /// Version đang ship của mỗi task — đổi khi thêm thư mục `v<N>` mới.
  static const Map<AITask, int> defaultVersions = <AITask, int>{
    AITask.receiptOcr: 1,
    AITask.calorieEstimate: 1,
    AITask.repetitionScore: 2, // v2 rules-only (#120, §6.6.4)
    AITask.ruleBasedSelection: 1,
  };

  /// So với `appMinVersion` của từng manifest (§5.4.3).
  final String appVersion;
  final AssetBytesLoader _load;
  final Map<AITask, int> modelVersions;
  final Map<AITask, ModelManifest> _manifests = <AITask, ModelManifest>{};
  final Map<AITask, Uint8List> _payloads = <AITask, Uint8List>{};
  final Map<AITask, ModelUnavailableReason> _reasons =
      <AITask, ModelUnavailableReason>{};

  String _dir(AITask task) => 'assets/models/${task.assetDir}/v${modelVersions[task]}';

  /// Đọc + verify MỌI task song song. Lỗi ở 1 task chỉ tắt on-device của đúng
  /// task đó — không throw, không crash app (Guard #7).
  Future<void> bootstrap() async {
    await Future.wait<void>(AITask.values.map(_bootstrapTask));
  }

  Future<void> _bootstrapTask(AITask task) async {
    try {
      final manifest = await _loadAndVerify(task);
      _manifests[task] = manifest;
      _reasons.remove(task);
    } catch (error) {
      _manifests.remove(task);
      _payloads.remove(task);
      _reasons[task] = error is _Unavailable
          ? error.reason
          : ModelUnavailableReason.invalidManifest;
    }
  }

  /// Thứ tự kiểm theo §5.4.2 — gặp lỗi đầu tiên thì dừng.
  Future<ModelManifest> _loadAndVerify(AITask task) async {
    final dir = _dir(task);
    final metaBytes = await _read('$dir/metadata.json');

    final Map<String, dynamic> json;
    final ModelManifest manifest;
    try {
      json = jsonDecode(utf8.decode(metaBytes)) as Map<String, dynamic>;
      manifest = ModelManifest.fromJson(task, json);
      if (manifest.modelVersion != modelVersions[task]) {
        throw FormatException('modelVersion ${manifest.modelVersion} != $dir');
      }
      if (!ModelManifest.semver.hasMatch(appVersion)) {
        throw FormatException('app version $appVersion is not x.y.z');
      }
    } catch (error) {
      throw _Unavailable(ModelUnavailableReason.invalidManifest, '$error');
    }

    if (_compareSemver(appVersion, manifest.appMinVersion) < 0) {
      throw _Unavailable(ModelUnavailableReason.appTooOld,
          'app $appVersion < ${manifest.appMinVersion}');
    }

    if (manifest.isMlkitBundled) {
      if (sha256Hex(ModelManifest.canonicalManifestJson(json)) !=
          manifest.checksumSha256) {
        throw const _Unavailable(
            ModelUnavailableReason.checksumMismatch, 'metadata checksum');
      }
    } else if (!manifest.payloadShipped) {
      throw const _Unavailable(
          ModelUnavailableReason.payloadNotShipped, 'payload not shipped');
    }

    final labelMap = manifest.labelMapFile;
    if (labelMap != null) await _read('$dir/$labelMap');

    if (manifest.payloadShipped) {
      final payload = await _read('$dir/${manifest.payloadFile}');
      if (sha256Hex(payload) != manifest.checksumSha256) {
        throw const _Unavailable(
            ModelUnavailableReason.checksumMismatch, 'payload checksum');
      }
      _payloads[task] = payload;
    }
    return manifest;
  }

  Future<Uint8List> _read(String path) async {
    try {
      final raw = await _load(path);
      return raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes);
    } catch (error) {
      throw _Unavailable(ModelUnavailableReason.missing, '$path: $error');
    }
  }

  static int _compareSemver(String a, String b) {
    final pa = a.split('.').map(int.parse).toList();
    final pb = b.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      final c = pa[i].compareTo(pb[i]);
      if (c != 0) return c;
    }
    return 0;
  }

  bool isAvailable(AITask task) => _manifests.containsKey(task);

  /// `null` khi task khả dụng.
  ModelUnavailableReason? unavailableReason(AITask task) => isAvailable(task)
      ? null
      : _reasons[task] ?? ModelUnavailableReason.notBootstrapped;

  /// Chỉ gọi sau khi [isAvailable] == true.
  ModelManifest manifestFor(AITask task) => _manifests[task]!;

  /// Payload đã verify checksum (vd. rules_config.json) — `null` nếu không có.
  Uint8List? payloadFor(AITask task) => _payloads[task];
}
