# smart_kitchen_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Cấu hình Firebase / Google Sign-In (#16)

`android/app/google-services.json` **không được commit** (đã có trong `.gitignore`).

1. Xin file `google-services.json` của project Firebase từ người quản lý (hoặc tải ở
   Firebase Console → Project settings → app Android `com.smartkitchen.mobile`).
2. Đặt vào `android/app/google-services.json`.
3. Thêm SHA-1 của debug keystore vào Firebase Console (Project settings → app Android →
   *Add fingerprint*), lấy bằng:
   ```bash
   cd android && ./gradlew signingReport      # Windows: gradlew.bat signingReport
   ```
4. Thêm SHA-1 xong thì **tải lại** `google-services.json` (file mới có OAuth client của
   SHA-1 đó) và thay file cũ. Thiếu bước này Google Sign-In báo `sign_in_failed`.

Không có file thì app **vẫn build và chạy được**: plugin `google-services` không được
apply, `Firebase.initializeApp()` lỗi và app dùng `UnavailableGoogleAuthGateway` — nút
Google báo không khả dụng, đăng nhập bằng email + OTP vẫn hoạt động.

iOS chưa được cấu hình (repo chưa có thư mục `ios/`).
