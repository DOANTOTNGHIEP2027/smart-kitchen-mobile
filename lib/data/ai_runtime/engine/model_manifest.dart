import 'ai_task.dart';

/// `assets/models/<task>/v<N>/metadata.json` (on-device-ai-runtime.md §5.2).
///
/// [payloadFile] + [checksumSha256] = file dữ liệu chính của package (model
/// binary / rules_config.json / nutrition_table.json) và SHA-256 của NÓ — không
/// phải của chính metadata.json (checksum trong file tự mô tả chính nó là vòng
/// tròn). `mlkit-bundled` không có payload trong assets → cả hai null.
class ModelManifest {
  const ModelManifest({
    required this.task,
    required this.modelVersion,
    required this.runtime,
    this.payloadFile,
    this.checksumSha256,
  });

  final AITask task;
  final int modelVersion;

  /// `tflite` | `onnx` | `mlkit-bundled` | `rules-only`.
  final String runtime;
  final String? payloadFile;
  final String? checksumSha256;

  static const Set<String> knownRuntimes = <String>{
    'tflite',
    'onnx',
    'mlkit-bundled',
    'rules-only',
  };

  /// Ném [FormatException] khi manifest sai — registry bắt và degrade đúng
  /// task đó (Guard #7).
  factory ModelManifest.fromJson(AITask task, Map<String, dynamic> json) {
    if (json['task'] != task.assetDir) {
      throw FormatException('manifest task ${json['task']} != ${task.assetDir}');
    }
    final runtime = json['runtime'] as String;
    if (!knownRuntimes.contains(runtime)) {
      throw FormatException('unknown runtime $runtime');
    }
    final payload = json['payloadFile'] as String?;
    final checksum = json['checksumSha256'] as String?;
    if (runtime != 'mlkit-bundled' && (payload == null || checksum == null)) {
      throw const FormatException('payloadFile + checksumSha256 required');
    }
    return ModelManifest(
      task: task,
      modelVersion: (json['modelVersion'] as num).toInt(),
      runtime: runtime,
      payloadFile: payload,
      checksumSha256: checksum?.toLowerCase(),
    );
  }

  String get modelUsed => 'on-device:${task.assetDir}@v$modelVersion';
}
