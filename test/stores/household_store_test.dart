import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/stores/household_store.dart';
import 'package:smart_kitchen_mobile/stores/submission_state.dart';

import '../helpers/fake_http_adapter.dart';
import '../helpers/onboarding_harness.dart';
import '../helpers/secure_storage_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storageChannel = FakeSecureStorageChannel();

  setUp(storageChannel.install);
  tearDown(storageChannel.uninstall);

  Map<String, dynamic> validPreview() => <String, dynamic>{
        'householdName': 'Gia đình Nguyễn',
        'ownerName': 'Phúc',
        'memberCount': 3,
        'expiresAt': '2026-09-20T10:00:00Z',
        'isValid': true,
      };

  Future<void> signIn(
    OnboardingHarness harness, {
    String? householdId,
  }) =>
      harness.sessionStore.setSession(
        accessToken: fakeJwt(<String, dynamic>{
          'sub': 'u1',
          'household_id': householdId,
          'role': 'MEMBER',
          'provider': 'EMAIL',
        }),
        refreshToken: 'r1',
        user: const UserSummary(id: 'u1'),
      );

  // Guard §20 — ba nhánh này KHÔNG được gộp; gộp lại thì hai trong ba sẽ sai.
  group('Bảng định tuyến join (Flow 8)', () {
    test('chưa đăng nhập → qrJoin', () {
      final harness = OnboardingHarness(
        FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null))),
      );

      expect(harness.householdStore.joinRoute, JoinRoute.qrJoin);
      expect(harness.householdStore.asksForDisplayName, isTrue);
    });

    test('đã đăng nhập, chưa có household → householdJoin', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null))),
      );
      await signIn(harness);

      expect(harness.householdStore.joinRoute, JoinRoute.householdJoin);
      expect(harness.householdStore.asksForDisplayName, isFalse);
    });

    test('đã có household → blocked', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null))),
      );
      await signIn(harness, householdId: 'h1');

      expect(harness.householdStore.joinRoute, JoinRoute.blocked);
    });

    test('S8.7 — nhánh blocked KHÔNG gọi BE', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(200, successEnvelope(validPreview())),
        ),
      );
      await signIn(harness, householdId: 'h1');
      await harness.householdStore.loadPreview('DEMO1234');
      final requestsBefore = harness.adapter.requests.length;

      final ok = await harness.householdStore.confirmJoin();

      expect(ok, isFalse);
      expect(harness.adapter.requests.length, requestsBefore);
    });

    test('chưa đăng nhập → gọi /auth/qr-join, không phải /households/join',
        () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((RequestOptions options) async {
          if (options.path.startsWith('/api/v1/households/invites/')) {
            return jsonResponse(200, successEnvelope(validPreview()));
          }
          return jsonResponse(
            201,
            successEnvelope(<String, dynamic>{
              ...sessionData(householdId: 'h1', role: 'MEMBER'),
              'householdId': 'h1',
              'role': 'MEMBER',
              'requiresProfileCompletion': true,
            }),
          );
        }),
      );

      await harness.householdStore.loadPreview('DEMO1234');
      final ok = await harness.householdStore.confirmJoin(displayName: 'Bé Na');

      expect(ok, isTrue);
      expect(harness.adapter.countPath('/api/v1/auth/qr-join'), 1);
      expect(harness.adapter.countPath('/api/v1/households/join'), 0);
      expect(harness.householdStore.requiresProfileCompletion, isTrue);
    });

    test('đã đăng nhập chưa có household → gọi /households/join + refresh',
        () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((RequestOptions options) async {
          if (options.path.startsWith('/api/v1/households/invites/')) {
            return jsonResponse(200, successEnvelope(validPreview()));
          }
          if (options.path == '/api/v1/auth/refresh') {
            return jsonResponse(
              200,
              successEnvelope(<String, dynamic>{
                'accessToken': fakeJwt(<String, dynamic>{
                  'sub': 'u1',
                  'household_id': 'h1',
                  'role': 'MEMBER',
                }),
                'refreshToken': 'r2',
                'expiresIn': 900,
              }),
            );
          }
          return jsonResponse(
            200,
            successEnvelope(<String, dynamic>{
              'householdId': 'h1',
              'householdName': 'Gia đình Nguyễn',
              'role': 'MEMBER',
              'requiresTokenRefresh': true,
            }),
          );
        }),
      );
      await signIn(harness);

      await harness.householdStore.loadPreview('DEMO1234');
      final ok = await harness.householdStore.confirmJoin();

      expect(ok, isTrue);
      expect(harness.adapter.countPath('/api/v1/households/join'), 1);
      expect(harness.adapter.countPath('/api/v1/auth/qr-join'), 0);
      // S8.11 — phải refresh, nếu không claim household vẫn là null.
      expect(harness.adapter.countPath('/api/v1/auth/refresh'), 1);
      expect(harness.sessionStore.householdId, 'h1');
    });
  });

  group('Flow 8 — preview', () {
    test('mã sai định dạng không chạm BE', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null))),
      );

      final ok = await harness.householdStore.loadPreview('ABC');

      expect(ok, isFalse);
      expect(harness.adapter.requests, isEmpty);
    });

    test('S8.6 — isValid:false trong body 200 vẫn là thất bại', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(
            200,
            successEnvelope(<String, dynamic>{
              ...validPreview(),
              'isValid': false,
            }),
          ),
        ),
      );

      final ok = await harness.householdStore.loadPreview('DEMO1234');

      expect(ok, isFalse);
      expect(
        (harness.householdStore.previewState as SubmissionFailure).code,
        'ERR_HH_002',
      );
    });

    test('mã được chuẩn hoá thành chữ hoa trước khi gọi', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(200, successEnvelope(validPreview())),
        ),
      );

      await harness.householdStore.loadPreview('demo1234');

      expect(
        harness.adapter.requests.single.path,
        '/api/v1/households/invites/DEMO1234',
      );
    });
  });

  group('Flow 8 — join race (S8.9)', () {
    test('ERR_HH_005 giữ nguyên code để view hiện đúng copy', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((RequestOptions options) async {
          if (options.path.startsWith('/api/v1/households/invites/')) {
            return jsonResponse(200, successEnvelope(validPreview()));
          }
          return jsonResponse(
            400,
            errorEnvelope('ERR_HH_005', 'Invite has already been used'),
          );
        }),
      );
      await signIn(harness);

      await harness.householdStore.loadPreview('DEMO1234');
      final ok = await harness.householdStore.confirmJoin();

      expect(ok, isFalse);
      expect(
        (harness.householdStore.joinState as SubmissionFailure).code,
        'ERR_HH_005',
      );
    });
  });

  group('Flow 7 — tạo household', () {
    test('tên rỗng không chạm BE', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null))),
      );

      final ok = await harness.householdStore.createHousehold('   ');

      expect(ok, isFalse);
      expect(harness.adapter.requests, isEmpty);
    });

    test('thành công → trả inviteCode và refresh claim household', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((RequestOptions options) async {
          if (options.path == '/api/v1/auth/refresh') {
            return jsonResponse(
              200,
              successEnvelope(<String, dynamic>{
                'accessToken': fakeJwt(<String, dynamic>{
                  'sub': 'u1',
                  'household_id': 'h1',
                  'role': 'OWNER',
                }),
                'refreshToken': 'r2',
                'expiresIn': 900,
              }),
            );
          }
          return jsonResponse(
            201,
            successEnvelope(<String, dynamic>{
              'id': 'h1',
              'name': 'Gia đình Nguyễn',
              'ownerId': 'u1',
              'inviteCode': 'ABCD1234',
              'createdAt': '2026-09-15T10:00:00Z',
            }),
          );
        }),
      );
      await signIn(harness);

      final ok = await harness.householdStore.createHousehold('Gia đình Nguyễn');

      expect(ok, isTrue);
      expect(harness.householdStore.createdHousehold?.inviteCode, 'ABCD1234');
      expect(harness.sessionStore.householdId, 'h1');
    });

    test('S7.3 — ERR_HH_003 giữ code để view redirect về Flow 6', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(
            409,
            errorEnvelope('ERR_HH_003', 'User already belongs to a household'),
          ),
        ),
      );
      await signIn(harness);

      await harness.householdStore.createHousehold('Nhà mới');

      expect(
        (harness.householdStore.createState as SubmissionFailure).code,
        'ERR_HH_003',
      );
    });
  });
}
