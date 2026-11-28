// Harness đo hiệu năng #93 (app-performance-audit §6). CHỈ có nghĩa ở
// `--profile` trên máy thật:
//
//   flutter drive --profile \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/performance_test.dart \
//     --dart-define=DEMO_MODE=true --dart-define=PERF_SEED=true \
//     --dart-define=PERF_INVENTORY_COUNT=100 --dart-define=PERF_RECIPE_COUNT=40 \
//     --dart-define=PERF_DEMO_LATENCY_MS=0 \
//     -d <device-id>
//
// S2: bỏ PERF_SEED, thêm --dart-define=PERF_SCENARIO=s2 (chỉ phase A).
// S2 xoá token trong secure storage trước khi khởi động (MEDIUM-1 review #93)
// — nếu không, refresh token do S1 seed khiến app tự đăng nhập, không tới
// `/login`. Lưu ý: chạy S2 cũng xoá phiên đăng nhập thật trên máy đo.
// Finder dùng `ValueKey` (kRecipeCardKeyPrefix, kCookingAbandonButtonKey) +
// `find.byType` class public; vẫn KHÔNG chạy harness với `--obfuscate`
// (`find.byType` so `runtimeType`).
// Kết quả: build/perf/<key>.json (cold_start, inventory_scroll,
// recipes_scroll, recap, memory). KHÔNG chạy trong `flutter test` / CI.
//
// Không dùng `pumpAndSettle` (Guard 4): Splash có spinner vô hạn, flame lặp.

import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate' as isolate;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/main.dart' as app;
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/auth/auth_landing_scene.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/scenes/cooking_session_scene.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/widgets/step_progress_bar.dart';
import 'package:smart_kitchen_mobile/scenes/insights/scenes/insights_routes.dart';
import 'package:smart_kitchen_mobile/scenes/recap/scenes/monthly_recap_scene.dart';
import 'package:smart_kitchen_mobile/scenes/recap/widgets/monthly_recap_widgets.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/stores/inventory_store.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/widgets/inventory_item_tile.dart';
import 'package:smart_kitchen_mobile/scenes/recap/scenes/recap_routes.dart';
import 'package:smart_kitchen_mobile/scenes/recap/scenes/weekly_recap_scene.dart';
import 'package:smart_kitchen_mobile/scenes/recap/widgets/shareable_recap_card.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/scenes/recipe_detail_scene.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/scenes/recipe_list_scene.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_scene.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_store.dart';
import 'package:smart_kitchen_mobile/scenes/splash/splash_scene.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'perf/frame_budget.dart';

const String _scenario =
    String.fromEnvironment('PERF_SCENARIO', defaultValue: 's1');
const bool _perfAssert = bool.fromEnvironment('PERF_ASSERT');
const int _latencyMs =
    int.fromEnvironment('PERF_DEMO_LATENCY_MS', defaultValue: 450);
const Duration _findTimeout = Duration(seconds: 30);

/// `expect` ngân sách chỉ bật ở profile + `PERF_ASSERT` (§6.1).
bool get _assertBudget => kProfileMode && _perfAssert;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('performance #93', (tester) async {
    binding.reportData ??= <String, dynamic>{};
    final report = binding.reportData!;

    // ── Phase A — cold start (M1, M2) ─────────────────────────────────────
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
    final startupFrames = <FrameTiming>[];
    binding.addTimingsCallback(startupFrames.addAll);
    if (_scenario == 's1') {
      await _seedSession();
    } else {
      await TokenStorage().clear(); // MEDIUM-1: S2 phải bắt đầu chưa đăng nhập
    }

    final sw = Stopwatch()..start();
    final t0 = developer.Timeline.now; // µs
    app.main(); // KHÔNG pumpWidget — phải đi qua bootstrap()

    final m1 = await _untilFound(tester, binding, find.byType(SplashScene), sw);
    final target = _scenario == 's1'
        ? find.byType(AppShellScene)
        : find.byType(AuthLandingScene);
    final m2 = await _untilFound(tester, binding, target, sw);
    final m2FoundAt = developer.Timeline.now;
    await tester.pump(const Duration(milliseconds: 500));
    // MEDIUM-3: engine gửi FrameTiming theo lô (≤1s / 100 frame) ở
    // profile/release → chờ tới khi lô chứa frame M2 về rồi mới gỡ callback.
    await _waitForTimingAfter(tester, startupFrames, m2FoundAt);
    binding.removeTimingsCallback(startupFrames.addAll);

    report['cold_start'] = <String, Object?>{
      'scenario': _scenario,
      'latency_ms': _latencyMs,
      'm1_ui_ms': m1 ?? 'timeout',
      'm2_ui_ms': m2 ?? 'timeout',
      // Chỉ đúng nếu đồng hồ FrameTiming cùng gốc với Timeline.now (§6.2 —
      // chưa xác minh được khi đọc source). Không cùng gốc → bỏ, dùng ui_ms.
      'm2_raster_ms': _rasterAfter(startupFrames, m2FoundAt, t0),
      // Chỉ tham khảo: gồm cả frame sau M2 trong lúc chờ lô timing.
      'frames_until_m2': startupFrames.length,
      if (m2 == null) 'current_route': Get.currentRoute,
    };
    expect(m2, isNotNull,
        reason: 'Không thấy màn đích trong $_findTimeout '
            '(route hiện tại: ${Get.currentRoute})');
    if (_assertBudget) expect(m2, lessThan(2000));
    if (_scenario != 's1') return;

    // ── Phase B — scroll Inventory 100 item + Recipes ─────────────────────
    Get.find<AppShellStore>().selectTab(1); // tab Kho thật, KHÔNG toNamed
    await _untilFound(tester, binding, find.byType(InventoryItemTile), sw);
    await _until(tester,
        () => Get.find<InventoryStore>().status == InventoryLoadStatus.ready);

    final inventoryList = find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.vertical,
    );
    expect(inventoryList, findsOneWidget); // R3-01: bỏ thanh chip ngang
    report['inventory_scroll'] =
        await _measureScroll(tester, binding, inventoryList);
    if (_assertBudget) {
      // MEDIUM-2: `pass` = frame_count > 0 && jank_frames == 0 — 0 frame
      // không được tính là PASS (§6.8/§13).
      expect((report['inventory_scroll'] as Map<String, Object>)['pass'], isTrue,
          reason: 'frame_count=0 hoặc có jank');
    }

    Get.find<AppShellStore>().selectTab(0);
    await tester.pump(const Duration(milliseconds: 300));
    Get.toNamed<void>(AppRoutes.recipes);
    await _untilFound(tester, binding, find.byType(RecipeListScene), sw);
    final grid = find.byType(GridView);
    await _untilFound(tester, binding, grid, sw);
    await tester.pump(const Duration(milliseconds: 500));
    report['recipes_scroll'] = await _measureScroll(tester, binding, grid);
    Get.back<void>();
    await tester.pump(const Duration(milliseconds: 500));

    // ── Phase C — recap render < 500ms ─────────────────────────────────────
    Get.find<AppShellStore>().selectTab(4);
    await tester.pump(const Duration(milliseconds: 500));
    sw.reset();
    Get.toNamed<void>(RecapRoutes.root);
    final recapFirst =
        await _untilFound(tester, binding, find.byType(WeeklyRecapScene), sw);
    final recapUi =
        await _untilFound(tester, binding, find.byType(ShareableRecapCard), sw);
    report['recap'] = <String, Object?>{
      'latency_ms': _latencyMs,
      'recap_first_frame_ms': recapFirst ?? 'timeout',
      'recap_ui_ms': recapUi ?? 'timeout',
    };
    if (_assertBudget && _latencyMs == 0) expect(recapUi, lessThan(500));
    Get.back<void>();
    await tester.pump(const Duration(milliseconds: 500));

    // ── Phase D — full navigation ×3 + heap ───────────────────────────────
    final memory = <String, Object?>{};
    for (var round = 1; round <= 3; round++) {
      await _fullNavigation(tester, binding, sw);
      if (round == 1 || round == 3) {
        final heap = await _readHeap();
        heap.forEach((k, v) => memory['${k}_round$round'] = v);
      }
    }
    memory['rss_mb'] = ProcessInfo.currentRss / (1024 * 1024);
    memory['max_rss_mb'] = ProcessInfo.maxRss / (1024 * 1024);
    report['memory'] = memory;
    final heap3 = memory['heap_mb_round3'];
    if (_assertBudget && heap3 is double) expect(heap3, lessThan(150));
  });
}

/// Ghi trước refresh token demo — cùng cách `bootstrap` dựng `TokenStorage`.
Future<void> _seedSession() =>
    TokenStorage().saveTokens('', 'demo-refresh-perf-seed');

/// Vòng `pump()` tới khi [finder] có kết quả, rồi chờ `endOfFrame`; trả
/// `sw.elapsedMilliseconds`. Quá [_findTimeout] → `null` (không treo).
Future<int?> _untilFound(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Finder finder,
  Stopwatch sw,
) async {
  final deadline = DateTime.now().add(_findTimeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) {
      await binding.endOfFrame;
      return sw.elapsedMilliseconds;
    }
    await Future<void>.delayed(const Duration(milliseconds: 4));
  }
  return null;
}

Future<void> _until(WidgetTester tester, bool Function() condition) async {
  final deadline = DateTime.now().add(_findTimeout);
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Chờ (tối đa 3s, thời gian thật) tới khi [frames] có timing với
/// `buildStart ≥ foundAt` — lô FrameTiming chứa frame M2 đã về.
Future<void> _waitForTimingAfter(
  WidgetTester tester,
  List<FrameTiming> frames,
  int foundAt,
) async {
  bool arrived() => frames.any(
      (f) => f.timestampInMicroseconds(FramePhase.buildStart) >= foundAt);
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!arrived() && DateTime.now().isBefore(deadline)) {
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

/// `rasterFinish` của frame đầu có `buildStart ≥ foundAt`, tính từ [t0] (ms).
double? _rasterAfter(List<FrameTiming> frames, int foundAt, int t0) {
  for (final f in frames) {
    if (f.timestampInMicroseconds(FramePhase.buildStart) >= foundAt) {
      return (f.timestampInMicroseconds(FramePhase.rasterFinish) - t0) / 1000;
    }
  }
  return null;
}

/// Fling dọc ×3 xuống + ×3 lên, thu `FrameTiming` theo mẫu `watchPerformance`
/// (xả 2s → thu → chờ timing mới, tối đa 40s), tóm tắt theo 16 667µs.
Future<Map<String, Object>> _measureScroll(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Finder list,
) async {
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
  await Future<void>.delayed(const Duration(seconds: 2));
  final frames = <FrameTiming>[];
  binding.addTimingsCallback(frames.addAll);
  for (final dy in <double>[-600, -600, -600, 600, 600, 600]) {
    await tester.fling(list, Offset(0, dy), 3000);
    await tester.pump(const Duration(milliseconds: 800));
  }
  await Future<void>.delayed(const Duration(seconds: 2));
  final waitStart = DateTime.now();
  while (frames.isEmpty &&
      DateTime.now().difference(waitStart) < const Duration(seconds: 40)) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  binding.removeTimingsCallback(frames.addAll);
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final ours = summarizeFrames(
    <int>[for (final f in frames) f.buildDuration.inMicroseconds],
    <int>[for (final f in frames) f.rasterDuration.inMicroseconds],
    <int>[for (final f in frames) f.totalSpan.inMicroseconds],
  );
  return <String, Object>{
    ...ours.toJson(),
    // Số của SDK (ngưỡng 16ms) — chỉ ghi kèm để đối chiếu (Guard 12).
    if (frames.isNotEmpty) 'sdk_summary': FrameTimingSummarizer(frames).summary,
  };
}

/// Một vòng điều hướng theo entry point thật (§6.7).
Future<void> _fullNavigation(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Stopwatch sw,
) async {
  final shell = Get.find<AppShellStore>();
  shell.selectTab(0);
  await tester.pump(const Duration(milliseconds: 300));
  shell.selectTab(1);
  await tester.pump(const Duration(milliseconds: 300));
  shell.selectTab(0);
  await tester.pump(const Duration(milliseconds: 300));

  Get.toNamed<void>(AppRoutes.recipes);
  await _untilFound(tester, binding, find.byType(RecipeListScene), sw);
  final card = find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith(kRecipeCardKeyPrefix),
  );
  await _untilFound(tester, binding, card, sw);
  await tester.tap(card.first);
  await _untilFound(tester, binding, find.byType(RecipeDetailScene), sw);

  final l10n = AppLocalizations.of(
    tester.element(find.byType(RecipeDetailScene)),
  );
  final start = find.text(l10n.recipeStartCooking);
  await _untilFound(tester, binding, start, sw);
  await tester.tap(start.first);
  await _untilFound(tester, binding, find.byType(CookingSessionScene), sw);
  await _untilFound(tester, binding, find.byType(StepProgressBar), sw);

  // Rời bằng nút đóng → dialog huỷ → xác nhận (gọi abandon).
  await tester.tap(find.byKey(kCookingAbandonButtonKey));
  final abandon = find.text(l10n.cookingAbandonAction);
  await _untilFound(tester, binding, abandon, sw);
  await tester.tap(abandon.last);
  await _until(
      tester, () => find.byType(CookingSessionScene).evaluate().isEmpty);
  await tester.pump(const Duration(milliseconds: 300));

  Get.back<void>(); // detail → list
  await tester.pump(const Duration(milliseconds: 300));
  Get.back<void>(); // list → shell
  await tester.pump(const Duration(milliseconds: 300));

  shell.selectTab(4);
  await tester.pump(const Duration(milliseconds: 300));
  Get.toNamed<void>(RecapRoutes.root);
  await _untilFound(tester, binding, find.byType(ShareableRecapCard), sw);
  Get.toNamed<void>(InsightsRoutes.history);
  await _untilFound(tester, binding, find.byType(MonthlyRecapScene), sw);
  await _untilFound(tester, binding, find.byType(MonthlyRecapShareCard), sw);
  // Lùi 1 tháng rồi tiến lại tháng hiện tại.
  await tester.tap(find.byKey(MonthNavigator.previousKey));
  await tester.pump(const Duration(milliseconds: 500));
  await _untilFound(tester, binding, find.byType(MonthlyRecapShareCard), sw);
  await tester.tap(find.byKey(MonthNavigator.nextKey));
  await tester.pump(const Duration(milliseconds: 500));
  Get.back<void>(); // tổng kết tháng → recap
  await tester.pump(const Duration(milliseconds: 300));
  Get.back<void>(); // recap → shell
  await tester.pump(const Duration(milliseconds: 300));
  shell.selectTab(0);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Heap Dart sau GC qua VM service (§6.7). Không kết nối được → ghi lý do,
/// đo tay bằng DevTools (failure mode §13).
Future<Map<String, Object>> _readHeap() async {
  final info = await developer.Service.getInfo();
  final uri = info.serverWebSocketUri;
  final isolateId = developer.Service.getIsolateId(isolate.Isolate.current);
  if (uri == null || isolateId == null) {
    return <String, Object>{'heap_error': 'vm_service_unavailable'};
  }
  final VmService vm = await vmServiceConnectUri(uri.toString());
  try {
    final AllocationProfile profile =
        await vm.getAllocationProfile(isolateId, gc: true);
    final usage = profile.memoryUsage;
    const mb = 1024 * 1024;
    return <String, Object>{
      'heap_mb': (usage?.heapUsage ?? 0) / mb,
      'heap_capacity_mb': (usage?.heapCapacity ?? 0) / mb,
      'external_mb': (usage?.externalUsage ?? 0) / mb,
    };
  } finally {
    await vm.dispose();
  }
}
