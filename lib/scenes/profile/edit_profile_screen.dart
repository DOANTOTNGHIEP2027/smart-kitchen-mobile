import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../data/network/api_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feature_banner.dart';
import 'api/avatar_image_processor.dart';
import 'domain/edit_profile_phase.dart';
import 'stores/profile_store.dart';
import 'widgets/profile_avatar.dart';
import '../../widgets/feedback/app_toast.dart';

/// Sửa tên + ảnh đại diện — luồng 2 bước `POST /api/v1/files` →
/// `PUT /api/v1/users/me` (profile-family-screens.md §10.2, D11, Guard 1/15).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.imagePicker});

  /// Inject cho test; mặc định dùng `image_picker` thật.
  final AvatarImagePicker? imagePicker;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileStore store = Get.find<ProfileStore>();
  late final AvatarImagePicker picker =
      widget.imagePicker ?? DeviceAvatarImagePicker();
  late final String initialName = store.currentUser?.fullName?.trim() ?? '';
  late final TextEditingController nameController =
      TextEditingController(text: initialName);

  /// Ảnh vừa chọn (chưa nén) — preview E2b.
  Uint8List? pickedAvatar;

  /// Mã lỗi validate tên phía client (E3), null = hợp lệ.
  String? nameErrorCode;

  @override
  void initState() {
    super.initState();
    nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    nameController.dispose();
    // Rời màn: bỏ pendingAvatarUrl + phase (file đã upload thành mồ côi — chấp nhận).
    store.discardEditSession();
    super.dispose();
  }

  bool get _nameChanged => nameController.text.trim() != initialName;

  void _onNameChanged() {
    // Sửa tên sau lỗi validate của BE → bỏ lỗi inline cũ.
    final phase = store.editProfilePhase;
    if (phase is EditSaveError && phase.error is ValidationException) {
      store.clearEditProfileError();
    }
    // Bỏ lỗi E3 + cập nhật trạng thái enable của nút Lưu.
    setState(() => nameErrorCode = null);
  }

  Future<void> _pickAvatar() async {
    final l10n = context.l10n;
    final source = await showModalBottomSheet<AvatarImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              key: const ValueKey<String>('edit-profile-source-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.profileAvatarGallery),
              onTap: () =>
                  Navigator.of(sheetContext).pop(AvatarImageSource.gallery),
            ),
            ListTile(
              key: const ValueKey<String>('edit-profile-source-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.profileAvatarCamera),
              onTap: () =>
                  Navigator.of(sheetContext).pop(AvatarImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final bytes = await picker.pick(source);
      if (bytes == null || !mounted) return; // huỷ chọn → không đổi gì
      store.onAvatarRepicked(); // ảnh mới ⇒ bỏ pendingAvatarUrl cũ + banner lỗi
      setState(() => pickedAvatar = bytes);
    } on AvatarPermissionDeniedException {
      AppToast.show(l10n.profileAvatarPermissionDenied,
          type: AppToastType.error);
    } catch (_) {
      AppToast.show(l10n.genericRetryError, type: AppToastType.error);
    }
  }

  Future<void> _save() async {
    final newName = _nameChanged ? nameController.text.trim() : null;
    if (newName != null) {
      final code = validateFullName(newName);
      if (code != null) {
        setState(() => nameErrorCode = code); // E3 — không gọi API
        return;
      }
    }
    final savedText = context.l10n.profileSavedToast;
    final ok =
        await store.saveProfile(newFullName: newName, rawAvatar: pickedAvatar);
    if (!mounted) return;
    if (ok) {
      Get.back<void>();
      AppToast.show(savedText, type: AppToastType.success); // E5
      return;
    }
    if (store.editProfilePhase is EditUploadError) {
      setState(() => pickedAvatar = null); // E7 — avatar quay về ảnh cũ
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.profileEditTitle,
      body: Observer(builder: (_) {
        final phase = store.editProfilePhase;
        final user = store.currentUser;
        final uploading = phase is EditUploading;
        final saving = phase is EditSaving;
        final busy = uploading || saving;
        final banner = _bannerMessage(l10n, phase, store.pendingAvatarUrl);
        final inlineError = _inlineNameError(l10n, phase);
        final isRetry = phase is EditSaveError && banner != null;
        final canSave = !busy &&
            (_nameChanged ||
                pickedAvatar != null ||
                store.pendingAvatarUrl != null);
        return ListView(
          padding: const EdgeInsets.all(AppDimens.lg),
          children: <Widget>[
            if (banner != null) ...<Widget>[
              FeatureBanner(
                key: const ValueKey<String>('edit-profile-error-banner'),
                message: banner,
              ),
              const SizedBox(height: AppDimens.md),
            ],
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  ProfileAvatar(
                    avatarUrl: user?.avatarUrl,
                    fullName: user?.fullName,
                    previewBytes: pickedAvatar,
                  ),
                  if (uploading)
                    const SizedBox(
                      width: ProfileAvatar.defaultSize,
                      height: ProfileAvatar.defaultSize,
                      child: CircularProgressIndicator(
                        key: ValueKey<String>('edit-profile-uploading'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            if (uploading)
              Text(l10n.profileAvatarUploading, textAlign: TextAlign.center)
            else if (pickedAvatar != null)
              Text(l10n.profileAvatarNewUnsaved, textAlign: TextAlign.center),
            Center(
              child: TextButton.icon(
                key: const ValueKey<String>('edit-profile-change-avatar'),
                onPressed: busy ? null : _pickAvatar,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(pickedAvatar == null
                    ? l10n.profileChangeAvatar
                    : l10n.profileAvatarPickAnother),
              ),
            ),
            const SizedBox(height: AppDimens.md),
            TextField(
              key: const ValueKey<String>('edit-profile-name'),
              controller: nameController,
              enabled: !busy,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.fullName,
                prefixIcon: const Icon(Icons.person_outline),
                errorText: nameErrorCode != null
                    ? _nameErrorText(l10n, nameErrorCode!)
                    : inlineError,
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            AppButton(
              key: const ValueKey<String>('edit-profile-save'),
              label: saving
                  ? l10n.profileSaving
                  : isRetry
                      ? l10n.profileSaveRetry
                      : l10n.profileSave,
              // E4 — mockup vẽ nút disabled có CHỮ "Đang lưu…" (không spinner):
              // `canSave` đã false khi `saving` nên nút tự disabled.
              onPressed: canSave ? _save : null,
            ),
          ],
        );
      }),
    );
  }
}

String _nameErrorText(AppLocalizations l10n, String code) => switch (code) {
      profileNameTooLongCode => l10n.profileNameTooLong,
      _ => l10n.profileNameRequired,
    };

/// `ERR_VALIDATION_FAILED` có `fieldErrors.fullName` → lỗi inline (E8 biến
/// thể), không banner (§12).
String? _inlineNameError(AppLocalizations l10n, EditProfilePhase phase) {
  if (phase is! EditSaveError) return null;
  final error = phase.error;
  if (error is ValidationException &&
      error.fieldErrors?.containsKey('fullName') == true) {
    return l10n.profileNameTooLong;
  }
  return null;
}

/// Copy banner E7/E8 theo bảng §12 — không bao giờ hiện `message` tiếng Anh
/// của BE; mã lạ → `genericRetryError`.
String? _bannerMessage(
    AppLocalizations l10n, EditProfilePhase phase, String? pendingAvatarUrl) {
  return switch (phase) {
    EditUploadError(:final code) => _codeMessage(l10n, code),
    EditSaveError(:final error) =>
      _saveErrorMessage(l10n, error, pendingAvatarUrl),
    _ => null,
  };
}

String? _saveErrorMessage(
    AppLocalizations l10n, ApiException error, String? pendingAvatarUrl) {
  if (error is ValidationException &&
      error.fieldErrors?.containsKey('fullName') == true) {
    return null; // hiển thị inline
  }
  if (error is AuthExpiredException) return l10n.sessionExpiredError;
  if (pendingAvatarUrl != null) return l10n.profileSaveErrorAfterUpload;
  return _codeMessage(l10n, error.code);
}

String _codeMessage(AppLocalizations l10n, String code) => switch (code) {
      'ERR_FILE_INVALID' => l10n.avatarErrorInvalid,
      'ERR_FILE_TOO_LARGE' => l10n.avatarErrorTooLarge,
      'ERR_NETWORK' => l10n.networkError,
      _ => l10n.genericRetryError,
    };
