import 'ai_task.dart';

/// Input/output trừu tượng — mỗi task tự định nghĩa lớp con (§4.1).
abstract class InferenceInput {}

abstract class InferenceOutput {
  /// `null` cho task không có khái niệm confidence (rule-based — tất định).
  double? get confidence;
}

/// Lỗi suy luận on-device. [modelUnavailable] tách 2 nguyên nhân khác nhau
/// (Guard #4): model thiếu/hỏng ≠ model sẵn sàng nhưng chạy lỗi.
class OnDeviceInferenceException implements Exception {
  const OnDeviceInferenceException(this.task, this.message,
      {this.modelUnavailable = false});

  final AITask task;
  final String message;
  final bool modelUnavailable;

  @override
  String toString() => 'OnDeviceInferenceException(${task.name}): $message';
}

/// Seam độc lập runtime (§4.1). Runtime NN cụ thể (`tflite_flutter` /
/// `onnxruntime_flutter` / ML Kit) CHỈ được chốt sau benchmark thiết bị thật
/// (§4.3, Guard #2) — mọi phần khác chỉ phụ thuộc interface này.
abstract class OnDeviceInferenceEngine {
  /// Nạp model cho [task] nếu chưa nạp — no-op nếu đã sẵn sàng.
  Future<void> loadIfNeeded(AITask task);

  /// Chạy 1 lệnh suy luận. Ném [OnDeviceInferenceException] khi thất bại —
  /// KHÔNG bao giờ trả output rỗng/giả để che lỗi.
  Future<InferenceOutput> run(AITask task, InferenceInput input);
}
