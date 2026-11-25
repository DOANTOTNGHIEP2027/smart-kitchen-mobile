# repetition_score

## v2
- Port công thức BE `MealRepetitionScorer` (#120, on-device-ai-runtime.md §6.6), runtime `rules-only`; thay `tflite` của v1 — model chưa train.
- `repetition_rules.json` chỉ là bản khai hằng số có checksum (window 14 ngày, ≤7 ngày → 1.0, 8–14 ngày → 0.5); nguồn sự thật là `RepetitionRules` trong Dart. Đổi ngưỡng ⇒ sửa Dart + khớp BE + tạo v3.
