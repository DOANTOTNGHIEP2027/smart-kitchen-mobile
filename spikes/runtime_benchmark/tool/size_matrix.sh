#!/usr/bin/env bash
# App size impact (§4.3 metric 3): build APK release arm64 cho app rỗng
# baseline và app rỗng + ĐÚNG 1 plugin runtime, so kích thước.
# iOS: cần macOS — chạy với PLATFORM=ios (đo thư mục Runner.app sau `flutter build ios --release --no-codesign`).
#
# Dùng: bash tool/size_matrix.sh [thư_mục_làm_việc]
# Kết quả: size_matrix.json trong thư mục làm việc.
set -euo pipefail

PLATFORM="${PLATFORM:-android}"
WORK="${1:-$(mktemp -d)}"
mkdir -p "$WORK"

# Cùng version đã ghim ở pubspec.yaml của spike.
declare -A DEPS=(
  [baseline]=""
  [tflite_flutter]="tflite_flutter: 0.12.1"
  [flutter_onnxruntime]="flutter_onnxruntime: 1.9.0"
  [google_mlkit_text_recognition]="google_mlkit_text_recognition: 0.17.1"
)

measure() {
  local name="$1" dep="$2" app="$WORK/size_$1"
  rm -rf "$app"
  flutter create "$app" --platforms "$PLATFORM" --project-name "size_$name" --empty >/dev/null
  if [[ -n "$dep" ]]; then
    # Chèn dep ngay dưới `sdk: flutter` đầu tiên của khối dependencies.
    awk -v d="  $dep" '{print} /^dependencies:/{f=1} f&&/sdk: flutter/{print d; f=0}' \
      "$app/pubspec.yaml" > "$app/pubspec.tmp" && mv "$app/pubspec.tmp" "$app/pubspec.yaml"
  fi
  (cd "$app" && flutter pub get >/dev/null)
  if [[ "$PLATFORM" == ios ]]; then
    (cd "$app" && flutter build ios --release --no-codesign >/dev/null)
    du -sk "$app/build/ios/iphoneos/Runner.app" | awk '{print $1 * 1024}'
  else
    (cd "$app" && flutter build apk --release --split-per-abi --target-platform android-arm64 >/dev/null)
    wc -c < "$app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" | tr -d ' '
  fi
}

declare -A SIZE
for name in baseline tflite_flutter flutter_onnxruntime google_mlkit_text_recognition; do
  echo ">> $name" >&2
  SIZE[$name]=$(measure "$name" "${DEPS[$name]}")
done

{
  echo "{"
  echo "  \"platform\": \"$PLATFORM\","
  echo "  \"baselineBytes\": ${SIZE[baseline]},"
  echo "  \"impactBytes\": {"
  echo "    \"tflite_flutter\": $(( SIZE[tflite_flutter] - SIZE[baseline] )),"
  echo "    \"flutter_onnxruntime\": $(( SIZE[flutter_onnxruntime] - SIZE[baseline] )),"
  echo "    \"google_mlkit_text_recognition\": $(( SIZE[google_mlkit_text_recognition] - SIZE[baseline] ))"
  echo "  }"
  echo "}"
} | tee "$WORK/size_matrix.json"
