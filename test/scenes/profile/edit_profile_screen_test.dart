import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/avatar_image_processor.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/profile_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/edit_profile_phase.dart';
import 'package:smart_kitchen_mobile/scenes/profile/edit_profile_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/profile_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';

import '../../helpers/secure_storage_channel.dart';

/// EditProfileScreen — state E2–E8 (profile-family-screens.md §10.2).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();

  late _FakeProfileApi api;
  late _FakePicker picker;
  late SessionStore session;

  setUp(() {
    storageChannel.install();
    Get.testMode = true;
    api = _FakeProfileApi();
    picker = _FakePicker();
    session = SessionStore(TokenStorage(), AuthRefreshUseCase(Dio()));
    session.currentUser =
        const UserSummary(id: 'me', fullName: 'Nguyen A', email: 'a@b.c');
    Get.put<ProfileStore>(ProfileStore(_UnusedHealthApi(), api, _UnusedCache(),
        session, const _PassThroughProcessor()));
  });

  tearDown(() {
    Get.reset();
    storageChannel.uninstall();
  });

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.light,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Text('profile-home')),
    ));
    Get.to<void>(() => EditProfileScreen(imagePicker: picker));
    await tester.pumpAndSettle();
  }

  AppButton saveButton(WidgetTester tester) => tester.widget<AppButton>(
      find.byKey(const ValueKey<String>('edit-profile-save')));

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('edit-profile-save')));
    await tester.pump();
  }

  Future<void> pickAvatar(WidgetTester tester) async {
    await tester
        .tap(find.byKey(const ValueKey<String>('edit-profile-change-avatar')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey<String>('edit-profile-source-gallery')));
    await tester.pumpAndSettle();
  }

  Finder nameField() => find.byKey(const ValueKey<String>('edit-profile-name'));

  testWidgets('E2 — chưa đổi gì → Lưu disabled; đổi tên → enabled',
      (tester) async {
    await openScreen(tester);

    expect(find.text('Nguyen A'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(nameField(), 'Nguyen B');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets(
      'E3 — tên trống sau trim / > 100 ký tự → lỗi inline, không gọi API',
      (tester) async {
    await openScreen(tester);

    await tester.enterText(nameField(), '   ');
    await tester.pump();
    await tapSave(tester);
    expect(find.text('Họ và tên không được để trống'), findsOneWidget);

    await tester.enterText(nameField(), 'x' * 101);
    await tester.pump();
    await tapSave(tester);
    expect(find.text('Họ và tên tối đa 100 ký tự'), findsOneWidget);

    expect(api.uploadCalls, 0);
    expect(api.updateCalls, isEmpty);
  });

  testWidgets('E2b → E6 → E4 → E5: chọn ảnh, tải lên, lưu, về + toast',
      (tester) async {
    final upload = Completer<FileUploadResult>();
    final update = Completer<UserSummary>();
    api
      ..uploadCompleter = upload
      ..updateCompleter = update;
    await openScreen(tester);

    await pickAvatar(tester);
    expect(find.text('Ảnh mới — chưa lưu'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNotNull);

    await tapSave(tester);
    expect(find.text('Đang tải ảnh lên…'), findsOneWidget); // E6
    expect(saveButton(tester).onPressed, isNull);

    upload.complete(const FileUploadResult(key: 'k', url: 'http://x/k.jpg'));
    await tester.pump();
    // E4 — mockup: nút disabled có chữ "Đang lưu…" nhìn thấy được (L1).
    expect(find.text('Đang lưu…'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);

    update.complete(const UserSummary(
        id: 'me', fullName: 'Nguyen A', avatarUrl: 'http://x/k.jpg'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing); // E5 — Get.back
    expect(find.text('Đã cập nhật hồ sơ'), findsOneWidget);
    expect(api.updateCalls.single, <String?>[null, 'http://x/k.jpg']);
    expect(session.currentUser?.avatarUrl, 'http://x/k.jpg');
  });

  testWidgets('E7 — lỗi ảnh: banner theo mã, giữ tên, bỏ preview ảnh mới',
      (tester) async {
    api.uploadError = BusinessException('ERR_FILE_TOO_LARGE', 'too large');
    await openScreen(tester);

    await tester.enterText(nameField(), 'Nguyễn Văn A');
    await pickAvatar(tester);
    await tapSave(tester);
    await tester.pumpAndSettle();

    // §12: không nêu con số (giới hạn client 500KB ≠ BE 2MB) — fix M4.
    expect(find.text('Ảnh quá lớn. Hãy chọn ảnh khác.'), findsOneWidget);
    expect(find.textContaining('MB'), findsNothing);
    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.text('Ảnh mới — chưa lưu'), findsNothing);
    expect(api.updateCalls, isEmpty);
  });

  testWidgets(
      'M2 — rời màn khi đang tải ảnh: ảnh bị bỏ KHÔNG được lưu, '
      'mở lại màn không bị luồng cũ ghi đè', (tester) async {
    final upload = Completer<FileUploadResult>();
    api.uploadCompleter = upload;
    await openScreen(tester);

    await pickAvatar(tester);
    await tapSave(tester);
    expect(find.text('Đang tải ảnh lên…'), findsOneWidget); // E6

    Get.back<void>(); // rời màn giữa chừng
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsNothing);

    // Mở lại màn trong khi upload cũ còn treo — phải lưu được bình thường.
    Get.to<void>(() => EditProfileScreen(imagePicker: picker));
    await tester.pumpAndSettle();
    expect(find.text('Đang tải ảnh lên…'), findsNothing);

    upload.complete(const FileUploadResult(key: 'k', url: 'http://x/old.jpg'));
    await tester.pumpAndSettle();

    final store = Get.find<ProfileStore>();
    expect(api.updateCalls, isEmpty, reason: 'không PUT ảnh đã bị bỏ');
    expect(store.pendingAvatarUrl, isNull);
    expect(store.editProfilePhase, isA<EditIdle>());
    expect(session.currentUser?.avatarUrl, isNull);
    expect(find.byType(EditProfileScreen), findsOneWidget,
        reason: 'luồng cũ không được đẩy EditSuccess → Get.back màn mới');

    // Màn mới vẫn lưu được (khoá double-submit không kẹt).
    await tester.enterText(nameField(), 'Nguyen B');
    await tester.pump();
    await tapSave(tester);
    await tester.pumpAndSettle();
    expect(api.updateCalls.single, <String?>['Nguyen B', null]);
  });

  testWidgets('E8 — PUT lỗi sau upload: banner + "Thử lại" chỉ PUT lại',
      (tester) async {
    api.updateError = NetworkException();
    await openScreen(tester);

    await pickAvatar(tester);
    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(
        find.text('Ảnh đã tải lên nhưng chưa lưu được hồ sơ. '
            'Kiểm tra kết nối và thử lại.'),
        findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Ảnh mới — chưa lưu'), findsOneWidget);

    api.updateError = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(api.uploadCalls, 1, reason: 'Guard 1 — không upload lần 2');
    expect(api.updateCalls, hasLength(2));
    expect(find.byType(EditProfileScreen), findsNothing);
  });

  testWidgets(
      'E8 biến thể — ERR_VALIDATION_FAILED fullName → lỗi inline, không banner',
      (tester) async {
    api.updateError = ValidationException(
      'ERR_VALIDATION_FAILED',
      'Validation failed',
      fieldErrors: const <String, String>{'fullName': 'too long'},
    );
    await openScreen(tester);

    await tester.enterText(nameField(), 'Nguyen C');
    await tester.pump();
    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(find.text('Họ và tên tối đa 100 ký tự'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('edit-profile-error-banner')),
        findsNothing);
  });
}

class _FakeProfileApi implements ProfileApi {
  @override
  Future<UserSummary> getMe() => throw UnimplementedError();
  Completer<FileUploadResult>? uploadCompleter;
  Completer<UserSummary>? updateCompleter;
  Object? uploadError;
  Object? updateError;
  int uploadCalls = 0;
  final List<List<String?>> updateCalls = <List<String?>>[];

  @override
  Future<FileUploadResult> uploadAvatar(Uint8List jpegBytes) async {
    uploadCalls++;
    if (uploadError != null) throw uploadError!;
    final completer = uploadCompleter;
    if (completer != null) return completer.future;
    return const FileUploadResult(key: 'k', url: 'http://x/k.jpg');
  }

  @override
  Future<UserSummary> updateMe({String? fullName, String? avatarUrl}) async {
    updateCalls.add(<String?>[fullName, avatarUrl]);
    if (updateError != null) throw updateError!;
    final completer = updateCompleter;
    if (completer != null) return completer.future;
    return UserSummary(
        id: 'me', fullName: fullName ?? 'Nguyen A', avatarUrl: avatarUrl);
  }
}

class _FakePicker implements AvatarImagePicker {
  @override
  Future<Uint8List?> pick(AvatarImageSource source) async =>
      Uint8List.fromList(<int>[1, 2, 3]);
}

class _PassThroughProcessor implements AvatarImageProcessor {
  const _PassThroughProcessor();

  @override
  Future<Uint8List> process(Uint8List picked) async => picked;
}

class _UnusedHealthApi implements HealthApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedCache implements ReadCacheDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
