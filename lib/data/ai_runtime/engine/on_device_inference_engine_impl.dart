import 'dart:convert';

import '../tasks/calorie_estimate_task.dart';
import '../tasks/meal_selection_task.dart';
import '../tasks/repetition_score_task.dart';
import 'ai_task.dart';
import 'model_registry.dart';
import 'on_device_inference_engine.dart';

/// Engine on-device hiện tại: task 4 (rule-based), task 2 (tra bảng calo —
/// §6.5.5) và task 3 (chấm điểm lặp — port công thức BE, §6.6.4) là Dart
/// thuần, chạy thật khi có payload. Receipt OCR báo "model chưa có" cho tới khi
/// runtime được chốt bằng benchmark thiết bị thật (§4.3, Guard #2 — Slice 2/3).
class OnDeviceInferenceEngineImpl implements OnDeviceInferenceEngine {
  OnDeviceInferenceEngineImpl(this._registry);

  final ModelRegistry _registry;
  OnDeviceMealSelectionRuleEngine? _rules;
  CalorieLookupEngine? _calories;
  bool _repetitionRulesVerified = false;

  @override
  Future<void> loadIfNeeded(AITask task) async {
    switch (task) {
      case AITask.ruleBasedSelection:
        if (_rules != null) return;
        final bytes = _registry.payloadFor(task);
        if (bytes == null) {
          throw OnDeviceInferenceException(task, 'rules_config.json missing',
              modelUnavailable: true);
        }
        try {
          _rules = OnDeviceMealSelectionRuleEngine.fromConfig(bytes);
        } catch (e) {
          throw OnDeviceInferenceException(task, 'rules_config.json invalid: $e',
              modelUnavailable: true);
        }
      case AITask.calorieEstimate:
        if (_calories != null) return;
        final bytes = _registry.payloadFor(task);
        if (bytes == null) {
          throw OnDeviceInferenceException(task, 'nutrition_table.json missing',
              modelUnavailable: true);
        }
        try {
          _calories = CalorieLookupEngine(NutritionTable.fromJson(bytes));
        } catch (e) {
          throw OnDeviceInferenceException(
              task, 'nutrition_table.json invalid: $e',
              modelUnavailable: true);
        }
      case AITask.repetitionScore:
        if (_repetitionRulesVerified) return;
        final bytes = _registry.payloadFor(task);
        if (bytes == null) {
          throw OnDeviceInferenceException(task, 'repetition_rules.json missing',
              modelUnavailable: true);
        }
        try {
          // Payload chỉ được KIỂM khớp hằng Dart — không đọc giá trị (§6.6.1).
          RepetitionRules.verifyPayload(jsonDecode(utf8.decode(bytes)));
        } catch (e) {
          throw OnDeviceInferenceException(
              task, 'repetition_rules.json invalid: $e',
              modelUnavailable: true);
        }
        _repetitionRulesVerified = true;
      case AITask.receiptOcr:
        throw OnDeviceInferenceException(task, 'no NN runtime selected yet',
            modelUnavailable: true);
    }
  }

  @override
  Future<InferenceOutput> run(AITask task, InferenceInput input) async {
    await loadIfNeeded(task);
    if (task == AITask.ruleBasedSelection && input is MealSelectionInput) {
      return MealSelectionOutput(_rules!.select(input.candidates, input.constraints));
    }
    if (task == AITask.calorieEstimate && input is CalorieEstimateInput) {
      return _calories!.estimate(input.items);
    }
    if (task == AITask.repetitionScore && input is RepetitionScoreInput) {
      return RepetitionScoreOutput(RepetitionScorer.score(
          input.candidates, input.history, input.referenceDay));
    }
    throw OnDeviceInferenceException(task, 'unsupported input ${input.runtimeType}');
  }
}
