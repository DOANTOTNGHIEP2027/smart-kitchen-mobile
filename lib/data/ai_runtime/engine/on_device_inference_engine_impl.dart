import '../tasks/meal_selection_task.dart';
import 'ai_task.dart';
import 'model_registry.dart';
import 'on_device_inference_engine.dart';

/// Engine on-device hiện tại: CHỈ task 4 (rule-based, Dart thuần) chạy thật.
/// 3 task NN (receipt OCR, calorie, repetition) báo "model chưa có" cho tới khi
/// runtime được chốt bằng benchmark thiết bị thật (§4.3, Guard #2 — Slice 2/3).
class OnDeviceInferenceEngineImpl implements OnDeviceInferenceEngine {
  OnDeviceInferenceEngineImpl(this._registry);

  final ModelRegistry _registry;
  OnDeviceMealSelectionRuleEngine? _rules;

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
      case AITask.receiptOcr:
      case AITask.calorieEstimate:
      case AITask.repetitionScore:
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
    throw OnDeviceInferenceException(task, 'unsupported input ${input.runtimeType}');
  }
}
