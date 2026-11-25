import 'dart:convert';

import 'ai_task.dart';

/// `assets/models/<task>/v<N>/metadata.json` (on-device-ai-runtime.md §5.4).
///
/// Checksum (§5.4.2):
/// - payload đã ship (`tflite`/`onnx`/`rules-only`): SHA-256 của [payloadFile]
///   (OD-25);
/// - `mlkit-bundled`: SHA-256 của [canonicalManifestJson] — metadata chuẩn hoá,
///   bỏ chính field `checksumSha256` (file không thể chứa hash của chính nó);
/// - khai [payloadFile] nhưng `checksumSha256 == null`: payload CHƯA ship →
///   manifest hợp lệ, task unavailable (`payloadNotShipped`).
class ModelManifest {
  const ModelManifest({
    required this.task,
    required this.modelVersion,
    required this.appMinVersion,
    required this.runtime,
    required this.outputType,
    required this.quantization,
    this.payloadFile,
    this.checksumSha256,
    this.inputShape,
    this.inputDType,
    this.preprocessing,
    this.outputShape,
    this.labelMapFile,
  });

  final AITask task;
  final int modelVersion;
  final String appMinVersion;

  /// `tflite` | `onnx` | `mlkit-bundled` | `rules-only`.
  final String runtime;
  final String? payloadFile;

  /// Chữ thường; `null` = payload chưa ship.
  final String? checksumSha256;
  final List<int>? inputShape;
  final String? inputDType;
  final Map<String, String>? preprocessing;
  final List<int>? outputShape;
  final String outputType;
  final String? labelMapFile;
  final String quantization;

  static const String mlkitBundled = 'mlkit-bundled';

  static const Set<String> knownRuntimes = <String>{
    'tflite',
    'onnx',
    mlkitBundled,
    'rules-only',
  };

  static const Set<String> knownQuantizations = <String>{
    'n/a',
    'none',
    'int8',
    'fp16',
    'dynamic-range',
  };

  /// `outputType` bắt buộc theo task (§5.4.1).
  static const Map<AITask, String> outputTypes = <AITask, String>{
    AITask.receiptOcr: 'ocr_text_lines',
    AITask.calorieEstimate: 'kcal_estimate',
    AITask.repetitionScore: 'repetition_scores',
    AITask.ruleBasedSelection: 'meal_selection',
  };

  static const List<String> _requiredKeys = <String>[
    'task',
    'modelVersion',
    'appMinVersion',
    'runtime',
    'payloadFile',
    'checksumSha256',
    'inputShape',
    'inputDType',
    'preprocessing',
    'outputShape',
    'outputType',
    'labelMapFile',
    'quantization',
  ];

  /// Semver `x.y.z` — dùng chung cho `appMinVersion` và version app (§5.4.3).
  static final RegExp semver =
      RegExp(r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$');
  static final RegExp _sha256 = RegExp(r'^[0-9a-fA-F]{64}$');
  static final RegExp _fileName = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$');
  static const int _maxSafeInt = 9007199254740992; // 2^53

  bool get isMlkitBundled => runtime == mlkitBundled;

  /// Payload có trong bundle (§5.4.2) — `mlkit-bundled` không có payload.
  bool get payloadShipped => !isMlkitBundled && checksumSha256 != null;

  String get modelUsed => 'on-device:${task.assetDir}@v$modelVersion';

  /// Ném [FormatException] khi manifest sai — registry bắt và degrade đúng
  /// task đó (Guard #7).
  factory ModelManifest.fromJson(AITask task, Map<String, dynamic> json) {
    _checkPortable(json);
    for (final key in _requiredKeys) {
      if (!json.containsKey(key)) throw FormatException('missing field $key');
    }
    final taskName = _string(json, 'task');
    if (taskName != task.assetDir) {
      throw FormatException('manifest task $taskName != ${task.assetDir}');
    }
    final version = _int(json, 'modelVersion');
    if (version < 1) throw FormatException('modelVersion $version < 1');
    final appMin = _string(json, 'appMinVersion');
    if (!semver.hasMatch(appMin)) {
      throw FormatException('appMinVersion $appMin is not x.y.z');
    }
    final runtime = _string(json, 'runtime');
    if (!knownRuntimes.contains(runtime)) {
      throw FormatException('unknown runtime $runtime');
    }
    final payload = _fileOrNull(json, 'payloadFile');
    final rawChecksum = _stringOrNull(json, 'checksumSha256');
    if (rawChecksum != null && !_sha256.hasMatch(rawChecksum)) {
      throw const FormatException('checksumSha256 is not 64 hex chars');
    }
    final checksum = rawChecksum?.toLowerCase();
    if (runtime == mlkitBundled) {
      if (payload != null) {
        throw const FormatException('mlkit-bundled must not have payloadFile');
      }
      if (checksum == null) {
        throw const FormatException('mlkit-bundled requires checksumSha256');
      }
    } else if (payload == null) {
      throw FormatException('$runtime requires payloadFile');
    }
    final inputShape = _shapeOrNull(json, 'inputShape');
    final outputShape = _shapeOrNull(json, 'outputShape');
    final inputDType = _stringOrNull(json, 'inputDType');
    final shipped = runtime != mlkitBundled && checksum != null;
    final nnShipped = (runtime == 'tflite' || runtime == 'onnx') && shipped;
    if (nnShipped) {
      if (inputShape == null || outputShape == null || inputDType == null) {
        throw FormatException(
            '$runtime with shipped payload requires inputShape/outputShape/inputDType');
      }
    }
    final outputType = _string(json, 'outputType');
    if (outputType != outputTypes[task]) {
      throw FormatException('outputType $outputType != ${outputTypes[task]}');
    }
    final quantization = _string(json, 'quantization');
    if (!knownQuantizations.contains(quantization)) {
      throw FormatException('unknown quantization $quantization');
    }
    // `n/a` khi và chỉ khi không có model NN đã ship (§5.4.1).
    if (nnShipped == (quantization == 'n/a')) {
      throw FormatException(
          'quantization $quantization does not match $runtime (shipped: $shipped)');
    }
    return ModelManifest(
      task: task,
      modelVersion: version,
      appMinVersion: appMin,
      runtime: runtime,
      payloadFile: payload,
      checksumSha256: checksum,
      inputShape: inputShape,
      inputDType: inputDType,
      preprocessing: _preprocessingOrNull(json),
      outputShape: outputShape,
      outputType: outputType,
      labelMapFile: _fileOrNull(json, 'labelMapFile'),
      quantization: quantization,
    );
  }

  /// Dạng chuẩn hoá để tính checksum `mlkit-bundled` (§5.4.2): bỏ
  /// `checksumSha256` ở cấp gốc, key sắp tăng dần mọi cấp, không khoảng
  /// trắng, UTF-8. Nguồn sự thật — script sinh checksum phải khớp hàm này.
  static List<int> canonicalManifestJson(Map<String, dynamic> json) {
    final withoutChecksum = Map<String, dynamic>.of(json)
      ..remove('checksumSha256');
    return utf8.encode(jsonEncode(_sorted(withoutChecksum)));
  }

  static Object? _sorted(Object? value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return <String, Object?>{for (final k in keys) k: _sorted(value[k])};
    }
    if (value is List) return value.map(_sorted).toList();
    return value;
  }

  /// ASCII in được, không `double`, số nguyên trong ±2^53 (§5.4.1) — để dạng
  /// chuẩn hoá giống nhau ở Dart và Python.
  static void _checkPortable(Object? value) {
    if (value is Map) {
      value.forEach((k, v) {
        if (k is! String) throw const FormatException('keys must be strings');
        _checkAscii(k);
        _checkPortable(v);
      });
    } else if (value is List) {
      value.forEach(_checkPortable);
    } else if (value is String) {
      _checkAscii(value);
    } else if (value is double) {
      throw const FormatException('manifest must not contain doubles');
    } else if (value is int) {
      if (value.abs() > _maxSafeInt) {
        throw const FormatException('integer out of ±2^53');
      }
    }
  }

  static void _checkAscii(String s) {
    for (final unit in s.codeUnits) {
      if (unit < 0x20 || unit > 0x7E) {
        throw const FormatException('manifest must be printable ASCII');
      }
    }
  }

  static String _string(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is! String) throw FormatException('$key must be a string');
    return v;
  }

  static String? _stringOrNull(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return null;
    if (v is! String) throw FormatException('$key must be a string or null');
    return v;
  }

  static int _int(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is! int) throw FormatException('$key must be an int');
    return v;
  }

  static String? _fileOrNull(Map<String, dynamic> json, String key) {
    final v = _stringOrNull(json, key);
    if (v == null) return null;
    if (!_fileName.hasMatch(v) ||
        v.contains('..') ||
        v == 'metadata.json' ||
        v == 'CHANGELOG.md') {
      throw FormatException('$key "$v" is not a valid package file name');
    }
    return v;
  }

  static List<int>? _shapeOrNull(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return null;
    if (v is! List || v.isEmpty) {
      throw FormatException('$key must be a non-empty int list or null');
    }
    return v.map((e) {
      if (e is! int || (e < 1 && e != -1)) {
        throw FormatException('$key has invalid dimension $e');
      }
      return e;
    }).toList(growable: false);
  }

  static Map<String, String>? _preprocessingOrNull(Map<String, dynamic> json) {
    final v = json['preprocessing'];
    if (v == null) return null;
    if (v is! Map) throw const FormatException('preprocessing must be an object');
    return v.map((k, value) {
      if (value is! String) {
        throw const FormatException('preprocessing values must be strings');
      }
      return MapEntry(k as String, value);
    });
  }
}
