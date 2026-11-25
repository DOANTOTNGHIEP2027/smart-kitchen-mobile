import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_progress_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_step.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/scenes/cooking_session_scene.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/stores/cooking_session_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/widgets/step_progress_bar.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/widgets/step_timer_view.dart';

import '../../helpers/pump_app.dart';
import 'cooking_session_store_test.dart' show MemoryProgressStore;
import 'fake_cooking_api.dart';

/// #93 F5 (app-performance-audit §7.3): tick timer mỗi giây chỉ dựng lại
/// `StepTimerView`, không dựng lại nội dung bước (Observer body).
void main() {
  late CookingSessionStore store;

  setUp(() {
    for (final api in <String>['toggle', 'isEnabled']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$api',
        (_) async => const StandardMessageCodec()
            .encodeMessage(<Object?>[api == 'isEnabled' ? false : null]),
      );
    }
    final cookingApi = FakeCookingApi()
      ..onStart = (_) async => CookingSession(
            id: 's1',
            householdId: 'h1',
            recipeId: 'r1',
            recipeName: 'Canh chua',
            startedBy: 'u1',
            status: CookingSessionStatusWire.inProgress,
            totalSteps: 1,
            startedAt: DateTime.parse('2026-11-19T07:00:00Z'),
            stepsSnapshot: const <CookingSessionStep>[
              CookingSessionStep(
                  stepNumber: 1, instruction: 'Nấu', durationSeconds: 60),
            ],
          );
    store = CookingSessionStore(
      cookingApi: cookingApi,
      recipeApi: FakeRecipeApi(),
      progressStore: CookingProgressCoordinator(MemoryProgressStore()),
      userId: 'u1',
      entryMode: CookingEntryMode.start,
      recipeId: 'r1',
    );
    Get.put<CookingSessionStore>(store);
  });

  tearDown(() {
    widgets.debugOnRebuildDirtyWidget = null;
    store.dispose();
    Get.reset();
  });

  testWidgets('timer tick 3 lần → StepTimerView rebuild 3, thân bước 0',
      (tester) async {
    await tester.pumpAppWidget(const CookingSessionScene(),
        wrapInScaffold: false);
    await tester.pump();
    await tester.pump();
    expect(store.phase, CookingScreenPhase.active);
    expect(store.timerRunning, isTrue);
    expect(store.remainingSeconds, 60);

    var timerBuilds = 0;
    var bodyBuilds = 0;
    widgets.debugOnRebuildDirtyWidget = (element, _) {
      if (element.widget is StepTimerView) timerBuilds++;
      if (element.widget is StepProgressBar) bodyBuilds++;
    };

    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(store.remainingSeconds, 57);
    expect(timerBuilds, 3, reason: 'StepTimerView dựng lại mỗi tick');
    expect(bodyBuilds, 0,
        reason: 'nội dung bước không được dựng lại theo tick timer');
    expect(find.byType(StepTimerView), findsOneWidget);
  });
}
