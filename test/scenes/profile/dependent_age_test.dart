import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/scenes/profile/dependent_list_screen.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/secure_storage_channel.dart';

/// OD-18: ngày sinh ở tương lai (BE trả sai) → KHÔNG hiện "-1 tuổi".
void main() {
  final storage = FakeSecureStorageChannel();
  setUpAll(storage.install);
  tearDownAll(storage.uninstall);
  tearDown(Get.reset);

  Future<void> pumpWith(WidgetTester tester, String dob) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(<Map<String, dynamic>>[
            <String, dynamic>{'id': 'd1', 'displayName': 'Bé Na', 'dateOfBirth': dob, 'dietType': 'NONE', 'allergens': <dynamic>[]},
          ])));
    Get.put<DioClient>(DioClient.build(tokenStorage: TokenStorage(), dio: dio));
    await tester.pumpAppWidget(const DependentListScreen(), wrapInScaffold: false);
    await tester.pumpAndSettle();
    expect(find.text('Bé Na'), findsOneWidget);
  }

  testWidgets('ngày sinh tương lai → chỉ hiện ngày, không có tuổi âm', (tester) async {
    final future = DateTime.now().add(const Duration(days: 400));
    await pumpWith(tester, '${future.year}-${future.month.toString().padLeft(2, '0')}-01');
    expect(find.textContaining('tuổi'), findsNothing);
    expect(find.textContaining('-1'), findsNothing);
  });

  testWidgets('ngày sinh hợp lệ → vẫn hiện "<n> tuổi · Sinh …"', (tester) async {
    await pumpWith(tester, '2020-01-01');
    expect(find.textContaining('tuổi · Sinh'), findsOneWidget);
  });
}
