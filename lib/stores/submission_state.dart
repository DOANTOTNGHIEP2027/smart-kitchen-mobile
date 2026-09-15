import '../data/network/api_exception.dart';

/// State của một thao tác **gửi form** (fe-onboarding.md §18).
///
/// Khác `ViewState<T>` của shell — cái đó dành cho màn hình fetch
/// list/detail, ngữ nghĩa empty/error của nó không ánh xạ gọn vào "form đang
/// submit". Flow hướng-submission (register, login, OTP, tạo/join household,
/// upgrade) dùng kiểu này.
sealed class SubmissionState {
  const SubmissionState();

  bool get isBusy => this is SubmissionInProgress;
}

class SubmissionIdle extends SubmissionState {
  const SubmissionIdle();
}

class SubmissionInProgress extends SubmissionState {
  const SubmissionInProgress();
}

class SubmissionFailure extends SubmissionState {
  const SubmissionFailure(this.error);

  final ApiException error;

  /// Rẽ nhánh theo `code`, KHÔNG theo `message` (fe-onboarding.md §18).
  String get code => error.code;
}

class SubmissionSuccess extends SubmissionState {
  const SubmissionSuccess();
}
