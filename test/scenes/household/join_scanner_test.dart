import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';

import '../onboarding_harness.dart';

/// Nhánh camera của màn tham gia (fe-onboarding.md S8.1, S8.2, §12b).
void main() {
  const permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
  late OnboardingHarness h;

  setUp(() => h = OnboardingHarness());
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissions, null);
    Get.reset();
  });

  void mockCamera({required bool granted}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissions, (call) async {
      if (call.method == 'requestPermissions') {
        final requested = List<int>.from(call.arguments as List);
        // PermissionStatus: 0 = denied, 1 = granted.
        return <int, int>{for (final p in requested) p: granted ? 1 : 0};
      }
      return null;
    });
  }

  Finder button(String label) =>
      find.byWidgetPredicate((w) => w is AppButton && w.label == label);

  testWidgets('S8.2: từ chối quyền camera → giải thích + mở cài đặt + nhập tay',
      (tester) async {
    mockCamera(granted: false);
    await h.pump(tester, AppRoutes.qrJoin);

    expect(find.text('Cần quyền camera để quét mã QR'), findsOneWidget);
    expect(button('Mở cài đặt'), findsOneWidget);

    await tester.tap(button('Nhập mã thủ công'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('join-code')), findsOneWidget);

    await tester.tap(button('Quét lại'));
    await tester.pumpAndSettle();
    expect(find.text('Cần quyền camera để quét mã QR'), findsOneWidget,
        reason: 'quét lại xin quyền lần nữa, vẫn bị từ chối');
  });

  group('quét QR (camera được cấp quyền)', () {
    MobileScanner scanner(WidgetTester tester) =>
        tester.widget<MobileScanner>(find.byType(MobileScanner));

    Future<void> scan(WidgetTester tester, String raw) async {
      scanner(tester).onDetect!(
          BarcodeCapture(barcodes: <Barcode>[Barcode(rawValue: raw)]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('QR lạ → S8.14, không gọi API, camera vẫn quét', (tester) async {
      mockCamera(granted: true);
      await h.signIn();
      await h.pump(tester, AppRoutes.qrJoin);
      expect(find.byType(MobileScanner), findsOneWidget);

      await scan(tester, 'https://evil.example.com/join/ABC12345');
      expect(find.byKey(const ValueKey('join-qr-invalid')), findsOneWidget);
      expect(find.text('Mã QR không hợp lệ'), findsOneWidget);
      expect(h.householdApi.previewCodes, isEmpty);
      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('QR hợp lệ quét 2 lần liên tiếp → điền mã + preview đúng 1 lần',
        (tester) async {
      mockCamera(granted: true);
      await h.signIn();
      await h.pump(tester, AppRoutes.qrJoin);

      final onDetect = scanner(tester).onDetect!;
      const capture = BarcodeCapture(barcodes: <Barcode>[
        Barcode(rawValue: 'https://app.smartkitchen.vn/join/abc12345'),
      ]);
      onDetect(capture);
      onDetect(capture); // frame kế tiếp vẫn thấy cùng mã
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('join-code')), findsOneWidget);
      expect(h.householdApi.previewCodes, <String>['ABC12345']);
      expect(find.text('Nhà An'), findsOneWidget);
    });

    testWidgets('lỗi camera: quyền → S8.2 copy, lỗi khác → S8.15 copy',
        (tester) async {
      mockCamera(granted: true);
      await h.signIn();
      await h.pump(tester, AppRoutes.qrJoin);
      final builder = scanner(tester).errorBuilder!;
      final ctx = tester.element(find.byType(MobileScanner));

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Column(children: <Widget>[
          Expanded(child: builder(ctx, const MobileScannerException(
              errorCode: MobileScannerErrorCode.permissionDenied))),
          Expanded(child: builder(ctx, const MobileScannerException(
              errorCode: MobileScannerErrorCode.unsupported))),
        ]),
      ));
      expect(find.byKey(const ValueKey('join-camera-permission')), findsOneWidget);
      expect(find.byKey(const ValueKey('join-camera-unavailable')), findsOneWidget);
      expect(find.text('Cần quyền camera để quét mã QR'), findsOneWidget);
      expect(find.text('Không mở được camera trên thiết bị này'), findsOneWidget);
    });
  });
}
