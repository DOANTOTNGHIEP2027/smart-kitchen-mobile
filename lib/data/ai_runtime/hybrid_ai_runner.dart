import '../network/api_exception.dart';
import 'ai_result.dart';
import 'connectivity/connectivity_gate.dart';
import 'engine/ai_task.dart';
import 'engine/model_registry.dart';
import 'engine/on_device_inference_engine.dart';

/// Bảng quyết định cloud ↔ on-device (§8) viết MỘT lần cho mọi repository —
/// không chép lại logic ở từng task.
///
/// | Device | Cloud | Hành vi |
/// |---|---|---|
/// | Offline (biết trước) | không gọi | on-device |
/// | Online | thành công | `fromCloud` |
/// | Online | NetworkException + re-check offline | on-device |
/// | Online | NetworkException + re-check VẪN online | rethrow (Guard #1) |
/// | Online | lỗi có response (4xx/5xx/ERR_AI_*) | rethrow — không fallback |
class HybridAIRunner {
  HybridAIRunner(this._gate, this._engine, this._registry);

  final ConnectivityGate _gate;
  final OnDeviceInferenceEngine _engine;
  final ModelRegistry _registry;

  Future<AIResult<T>> run<T>({
    required AITask task,
    required Future<T> Function()? cloud,
    required String cloudModelUsed,
    required InferenceInput input,
    required T Function(InferenceOutput output) fromOutput,
  }) async {
    if (cloud == null || await _gate.isDeviceOffline()) {
      return runOnDevice(task: task, input: input, fromOutput: fromOutput);
    }
    final stopwatch = Stopwatch()..start();
    try {
      final data = await cloud();
      return AIResult<T>.fromCloud(data,
          modelUsed: cloudModelUsed, latencyMs: stopwatch.elapsedMilliseconds);
    } on NetworkException {
      // NetworkException CHƯA đủ để kết luận offline — re-verify đúng lúc này,
      // nếu không BE/AI outage thật bị che sau UX "chế độ offline" (Guard #1).
      if (await _gate.isDeviceOffline()) {
        return runOnDevice(task: task, input: input, fromOutput: fromOutput);
      }
      rethrow;
    }
  }

  /// Chạy on-device; không bao giờ throw lên UI — lỗi thành `AIResult` lỗi với
  /// đúng 1 trong 2 mã `ERR_ONDEVICE_*` (Guard #4).
  Future<AIResult<T>> runOnDevice<T>({
    required AITask task,
    required InferenceInput input,
    required T Function(InferenceOutput output) fromOutput,
  }) async {
    if (!_registry.isAvailable(task)) return AIResult<T>.unavailable(task);
    final stopwatch = Stopwatch()..start();
    try {
      await _engine.loadIfNeeded(task);
      final output = await _engine.run(task, input);
      return AIResult<T>.fromOnDevice(
        data: fromOutput(output),
        confidence: output.confidence,
        modelUsed: _registry.manifestFor(task).modelUsed,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } on OnDeviceInferenceException catch (e) {
      return e.modelUnavailable
          ? AIResult<T>.unavailable(task)
          : AIResult<T>.inferenceFailed(task);
    } catch (_) {
      return AIResult<T>.inferenceFailed(task);
    }
  }
}
