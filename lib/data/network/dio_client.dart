import 'package:dio/dio.dart';

import '../../app/env_config.dart';
import '../auth/token_storage.dart';
import 'interceptors/auth_header_interceptor.dart';
import 'interceptors/error_mapping_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/token_refresh_interceptor.dart';

/// Dio client dùng chung của toàn app (fe-app-shell.md §7.3).
///
/// Feature inject qua `Get.find<DioClient>().dio` — không khởi tạo thêm một
/// [Dio] thứ hai ở bất kỳ đâu.
class DioClient {
  DioClient._(this.dio);

  final Dio dio;

  static const Set<String> publicPaths = <String>{
    '/api/v1/auth/google',
    '/api/v1/auth/email/register',
    '/api/v1/auth/email/send-otp',
    '/api/v1/auth/email/verify-otp',
    '/api/v1/auth/email/login',
    '/api/v1/auth/email/forgot-password',
    '/api/v1/auth/email/reset-password',
    '/api/v1/auth/refresh',
    '/api/v1/auth/qr-join',
    // GET /api/v1/households/invites/{code} cũng public nhưng path-templated,
    // khớp theo prefix trong AuthHeaderInterceptor (§7.4).
  };

  static DioClient build({required TokenStorage tokenStorage, Dio? dio}) {
    final instance = dio ??
        Dio(BaseOptions(
          baseUrl: EnvConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          contentType: Headers.jsonContentType,
        ));

    // ⚠️ THỨ TỰ NÀY LOAD-BEARING — không đổi nếu chưa đọc hết ghi chú này.
    //
    // Yêu cầu (fe-app-shell.md §7.3): TokenRefreshInterceptor phải là
    // interceptor NHÌN THẤY ERROR ĐẦU TIÊN, nếu không ErrorMappingInterceptor
    // sẽ `handler.reject()` mọi 401 trước và âm thầm vô hiệu hóa cơ chế
    // refresh (D9 — từng là blocker trong review).
    //
    // Cách Dio thực sự đạt yêu cầu đó: `DioMixin.fetch` build cả ba flow
    // (request / response / error) bằng cách duyệt `interceptors` theo ĐÚNG
    // THỨ TỰ LIST — "the processors (interceptors) execute in FIFO order"
    // (dio-5.11.1/lib/src/dio_mixin.dart:527, vòng lặp error ở dòng 577).
    // KHÔNG có chuyện error unwind ngược lại. Vì vậy TokenRefreshInterceptor
    // phải đứng TRƯỚC ErrorMappingInterceptor trong list.
    //
    // §7.3 của thiết kế mô tả Dio chạy onError theo thứ tự ngược và vì thế
    // kết luận thứ tự ngược lại; kết luận đó sai với dio 5.x đã verify bằng
    // source + test `interceptor_pipeline_test.dart`. Ý định của §7.3 được
    // giữ nguyên, chỉ thứ tự list là sửa lại.
    instance.interceptors.addAll(<Interceptor>[
      AuthHeaderInterceptor(tokenStorage, publicPaths: publicPaths),
      TokenRefreshInterceptor(instance, tokenStorage, publicPaths: publicPaths),
      ErrorMappingInterceptor(),
      if (EnvConfig.isDev) LoggingInterceptor(),
    ]);

    return DioClient._(instance);
  }
}
