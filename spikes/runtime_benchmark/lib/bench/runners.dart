import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'model_config.dart';

/// Một cấu hình runtime × delegate cần đo. Spike — không phải code production.
abstract class RuntimeRunner {
  /// `runtime/delegate`, vd. `tflite/gpu` — khoá trong báo cáo + crash ledger.
  String get id;

  /// Nạp model + chuẩn bị input. Delegate không hỗ trợ trên máy ⇒ ném lỗi.
  Future<void> load();

  /// Đúng một lệnh suy luận, chờ xong output.
  Future<void> inferOnce();

  Future<void> dispose();
}

enum TfliteDelegate { cpu, gpu, nnapi, coreml }

class TfliteRunner implements RuntimeRunner {
  TfliteRunner(this.delegate);

  final TfliteDelegate delegate;
  Interpreter? _interp;
  Delegate? _delegate;

  @override
  String get id => 'tflite/${delegate.name}';

  @override
  Future<void> load() async {
    final options = InterpreterOptions()..threads = kCpuThreads;
    switch (delegate) {
      case TfliteDelegate.cpu:
        break;
      case TfliteDelegate.gpu:
        // Android: GpuDelegateV2 (OpenCL/GL). iOS: GpuDelegate = Metal.
        _delegate = Platform.isAndroid ? GpuDelegateV2() : GpuDelegate();
        options.addDelegate(_delegate!);
      case TfliteDelegate.nnapi:
        options.useNnApiForAndroid = true;
      case TfliteDelegate.coreml:
        _delegate = CoreMlDelegate();
        options.addDelegate(_delegate!);
    }
    final interp = await Interpreter.fromAsset(kTfliteAsset, options: options);
    _interp = interp;
    final input = interp.getInputTensor(0);
    if (input.shape.any((d) => d <= 0)) {
      interp.resizeInputTensor(0, kOcrInputShapeNhwc);
    }
    interp.allocateTensors();
    // Nội dung tensor không ảnh hưởng latency của mạng tích chập — dùng 0.
    final t = interp.getInputTensor(0);
    t.data = Uint8List(t.numBytes());
  }

  @override
  Future<void> inferOnce() async {
    final interp = _interp!;
    interp.invoke();
    // Chạm output để chắc kết quả đã về bộ nhớ CPU (GPU delegate).
    interp.getOutputTensor(0).data.length;
  }

  @override
  Future<void> dispose() async {
    _interp?.close();
    _delegate?.delete();
    _interp = null;
    _delegate = null;
  }
}

enum OnnxProvider { cpu, nnapi, coreml }

class OnnxRunner implements RuntimeRunner {
  OnnxRunner(this.provider);

  final OnnxProvider provider;
  OrtSession? _session;
  OrtValue? _input;

  @override
  String get id => 'onnx/${provider.name}';

  @override
  Future<void> load() async {
    final ort = OnnxRuntime();
    final wanted = switch (provider) {
      OnnxProvider.cpu => OrtProvider.CPU,
      OnnxProvider.nnapi => OrtProvider.NNAPI,
      OnnxProvider.coreml => OrtProvider.CORE_ML,
    };
    final available = await ort.getAvailableProviders();
    if (!available.contains(wanted)) {
      throw UnsupportedError('$wanted không có trên máy này: $available');
    }
    final session = await ort.createSessionFromAsset(
      kOnnxAsset,
      options: OrtSessionOptions(
        intraOpNumThreads: kCpuThreads,
        // CPU luôn là fallback cho node mà EP không nhận.
        providers: wanted == OrtProvider.CPU ? [wanted] : [wanted, OrtProvider.CPU],
      ),
    );
    _session = session;
    // iOS không trả shape qua getInputInfo ⇒ dùng shape cấu hình cố định.
    final n = kOcrInputShapeNchw.reduce((a, b) => a * b);
    _input = await OrtValue.fromList(Float32List(n), kOcrInputShapeNchw);
  }

  @override
  Future<void> inferOnce() async {
    final session = _session!;
    final out = await session.run({session.inputNames.first: _input!});
    for (final v in out.values) {
      await v.dispose();
    }
  }

  @override
  Future<void> dispose() async {
    await _input?.dispose();
    await _session?.close();
    _input = null;
    _session = null;
  }
}

/// ML Kit Text Recognition (Latin) — gói `com.google.mlkit:text-recognition`
/// là biến thể BUNDLED (model nằm trong APK), không tải qua Play Services.
class MlkitRunner implements RuntimeRunner {
  TextRecognizer? _recognizer;
  String? _imagePath;

  @override
  String get id => 'mlkit/bundled';

  @override
  Future<void> load() async {
    final bytes = await rootBundle.load(kReceiptImageAsset);
    final file = File('${(await getTemporaryDirectory()).path}/receipt_sample.jpg');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    _imagePath = file.path;
    _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  @override
  Future<void> inferOnce() async {
    await _recognizer!.processImage(InputImage.fromFilePath(_imagePath!));
  }

  @override
  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}

/// Bộ cấu hình theo nền tảng (§4.2): Android GPU/NNAPI, iOS Metal/CoreML.
List<RuntimeRunner> runnersForPlatform() => Platform.isIOS
    ? [
        TfliteRunner(TfliteDelegate.cpu),
        TfliteRunner(TfliteDelegate.gpu),
        TfliteRunner(TfliteDelegate.coreml),
        OnnxRunner(OnnxProvider.cpu),
        OnnxRunner(OnnxProvider.coreml),
        MlkitRunner(),
      ]
    : [
        TfliteRunner(TfliteDelegate.cpu),
        TfliteRunner(TfliteDelegate.gpu),
        TfliteRunner(TfliteDelegate.nnapi),
        OnnxRunner(OnnxProvider.cpu),
        OnnxRunner(OnnxProvider.nnapi),
        MlkitRunner(),
      ];
