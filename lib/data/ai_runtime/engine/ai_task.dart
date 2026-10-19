/// 4 tác vụ AI có đường on-device (on-device-ai-runtime.md §6).
enum AITask {
  receiptOcr('receipt_ocr'),
  calorieEstimate('calorie_estimate'),
  repetitionScore('repetition_score'),
  ruleBasedSelection('rule_based_selection');

  const AITask(this.assetDir);

  /// Thư mục dưới `assets/models/` — trùng giá trị `task` trong metadata.json.
  final String assetDir;
}
