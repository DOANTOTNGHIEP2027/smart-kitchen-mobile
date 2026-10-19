import '../network/api_response.dart';
import 'engine/ai_task.dart';

enum AISource { cloud, onDevice }

/// Envelope thống nhất cho kết quả AI từ cloud HOẶC on-device (§7). KHÔNG thêm
/// field vào `ApiResponse<T>` (Guard #5) — đó là breaking change cho mọi API.
class AIResult<T> {
  const AIResult._({
    required this.success,
    this.data,
    this.error,
    required this.source,
    this.confidence,
    required this.modelUsed,
    this.latencyMs,
  });

  final bool success;
  final T? data;
  final ApiError? error;
  final AISource source;
  final double? confidence;

  /// vd. "cloud:receipt-ocr-relay#38" | "on-device:rule_based_selection@v1".
  final String modelUsed;
  final int? latencyMs;

  /// Điều kiện DUY NHẤT để hiện banner/badge offline (§9.3). Kết quả lỗi
  /// (`success == false`) KHÔNG phải degraded — đó là error state riêng.
  bool get isDegraded => success && source == AISource.onDevice;

  /// BE hiện KHÔNG forward confidence xuống FE (be-ai-contract §14) → null.
  factory AIResult.fromCloud(T data, {required String modelUsed, int? latencyMs}) =>
      AIResult<T>._(
        success: true,
        data: data,
        source: AISource.cloud,
        modelUsed: modelUsed,
        latencyMs: latencyMs,
      );

  factory AIResult.fromOnDevice({
    required T data,
    double? confidence,
    required String modelUsed,
    required int latencyMs,
  }) =>
      AIResult<T>._(
        success: true,
        data: data,
        source: AISource.onDevice,
        confidence: confidence,
        modelUsed: modelUsed,
        latencyMs: latencyMs,
      );

  /// Model on-device thiếu/hỏng VÀ đang offline — task không dùng được.
  /// Mã FE-local `ERR_ONDEVICE_*`, không dùng `ERR_AI_*` (Guard #4, D6).
  factory AIResult.unavailable(AITask task) => AIResult<T>._(
        success: false,
        error: ApiError(
          code: errModelUnavailable,
          message: 'On-device model for ${task.assetDir} is unavailable',
        ),
        source: AISource.onDevice,
        modelUsed: 'on-device:unavailable',
      );

  /// Model ĐÃ sẵn sàng nhưng `run()` thất bại — KHÁC [AIResult.unavailable].
  factory AIResult.inferenceFailed(AITask task) => AIResult<T>._(
        success: false,
        error: ApiError(
          code: errInferenceFailed,
          message: 'On-device inference failed for ${task.assetDir}',
        ),
        source: AISource.onDevice,
        modelUsed: 'on-device:inference-failed',
      );

  static const String errModelUnavailable = 'ERR_ONDEVICE_MODEL_UNAVAILABLE';
  static const String errInferenceFailed = 'ERR_ONDEVICE_INFERENCE_FAILED';
}
