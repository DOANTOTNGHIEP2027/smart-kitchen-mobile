import '../../../data/network/api_exception.dart';

/// Trạng thái luồng 2 bước của EditProfileScreen (profile-family-screens.md
/// §8, §10.2): [upload ảnh] `POST /api/v1/files` → `PUT /api/v1/users/me`.
///
/// Tách bước upload khỏi bước lưu để UI biết lỗi thuộc bước nào (E7 vs E8)
/// và để "Thử lại" sau E8 chỉ gọi lại PUT (Guard 1).
sealed class EditProfilePhase {
  const EditProfilePhase();
}

/// E2/E2b — form chưa gửi.
class EditIdle extends EditProfilePhase {
  const EditIdle();
}

/// E6 — đang nén + tải ảnh lên.
class EditUploading extends EditProfilePhase {
  const EditUploading();
}

/// E4 — đang `PUT /users/me`.
class EditSaving extends EditProfilePhase {
  const EditSaving();
}

/// E7 — lỗi ở bước ảnh. [code] = mã BE hoặc mã client cùng nghĩa
/// (`ERR_FILE_INVALID` / `ERR_FILE_TOO_LARGE` / `ERR_NETWORK` / ...).
class EditUploadError extends EditProfilePhase {
  const EditUploadError(this.code);
  final String code;
}

/// E8 — lỗi ở bước PUT; `pendingAvatarUrl` (nếu có) được giữ lại.
class EditSaveError extends EditProfilePhase {
  const EditSaveError(this.error);
  final ApiException error;
}

/// E5 — lưu xong, `SessionStore.currentUser` đã được cập nhật.
class EditSuccess extends EditProfilePhase {
  const EditSuccess();
}

/// Validate tên — trả mã lỗi (trùng tên key l10n) hoặc `null`.
/// BE chỉ có `@Size(max=100)` và NHẬN chuỗi rỗng → FE là lớp chặn duy nhất
/// cho tên trống/toàn khoảng trắng (Guard 15). [name] được trim ở đây.
String? validateFullName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return profileNameRequiredCode;
  if (trimmed.length > maxFullNameLength) return profileNameTooLongCode;
  return null;
}

const int maxFullNameLength = 100;
const String profileNameRequiredCode = 'profileNameRequired';
const String profileNameTooLongCode = 'profileNameTooLong';
