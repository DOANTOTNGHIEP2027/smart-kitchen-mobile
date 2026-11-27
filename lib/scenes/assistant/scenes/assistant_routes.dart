import 'package:get/get.dart';

import '../../../data/network/dio_client.dart';
import '../../../routing/route_guards.dart';
import '../../../services/connectivity_service.dart';
import '../../../stores/session_store.dart';
import '../data/assistant_api.dart';
import '../domain/assistant_models.dart';
import '../stores/assistant_store.dart';
import 'assistant_scene.dart';

/// Điểm vào màn trợ lý toàn màn (#204, FE design v2 §1).
class AssistantEntry {
  const AssistantEntry.global()
      : contextType = AssistantContextType.global,
        mealPlanId = null,
        slotId = null,
        slotLabel = null,
        horizonDays = 1;

  const AssistantEntry.planning({
    required String this.mealPlanId,
    required String this.slotId,
    required String this.slotLabel,
    required this.horizonDays,
  }) : contextType = AssistantContextType.planning;

  final AssistantContextType contextType;
  final String? mealPlanId;
  final String? slotId;

  /// Chip ngữ cảnh S2, vd. "Thứ Hai · Bữa tối".
  final String? slotLabel;
  final int horizonDays;
}

class AssistantRoutes {
  AssistantRoutes._();

  static const String chat = '/assistant';

  /// Tag của store GLOBAL bền trong cả phiên đăng nhập — FAB toàn cục mở lại
  /// đúng hội thoại đang dở.
  static const String globalTag = 'assistant-global';

  static Future<void>? openGlobal() =>
      Get.toNamed<void>(chat, arguments: const AssistantEntry.global());

  static Future<void>? openPlanning({
    required String mealPlanId,
    required String slotId,
    required String slotLabel,
    required int horizonDays,
  }) =>
      Get.toNamed<void>(
        chat,
        arguments: AssistantEntry.planning(
          mealPlanId: mealPlanId,
          slotId: slotId,
          slotLabel: slotLabel,
          horizonDays: horizonDays,
        ),
      );

  /// Store cho một lần mở. GLOBAL dùng chung một store bền; PLANNING luôn là
  /// phiên mới (ngữ cảnh gắn cố định với phiên) nên tạo store riêng, màn tự
  /// [AssistantStore.dispose].
  static AssistantStore storeFor(AssistantEntry entry) {
    if (!Get.isRegistered<AssistantApi>()) {
      Get.put<AssistantApi>(AssistantApiImpl(Get.find<DioClient>()),
          permanent: true);
    }
    if (entry.contextType == AssistantContextType.global &&
        Get.isRegistered<AssistantStore>(tag: globalTag)) {
      return Get.find<AssistantStore>(tag: globalTag);
    }
    final session =
        Get.isRegistered<SessionStore>() ? Get.find<SessionStore>() : null;
    final connectivity = Get.isRegistered<ConnectivityService>()
        ? Get.find<ConnectivityService>()
        : null;
    final store = AssistantStore(
      api: Get.find<AssistantApi>(),
      contextType: entry.contextType,
      contextKey: entry.contextType == AssistantContextType.global
          ? () => 'global'
          : () => '${entry.mealPlanId}|${entry.slotId}',
      planning: entry.contextType == AssistantContextType.planning
          ? () => (
                mealPlanId: entry.mealPlanId!,
                slotId: entry.slotId!,
                horizonDays: entry.horizonDays,
              )
          : null,
      isOnline: () => connectivity?.isOnlineNow ?? true,
      accountScope: session == null
          ? null
          : () => '${session.currentUser?.id}|${session.householdId}',
    );
    if (entry.contextType == AssistantContextType.global) {
      Get.put<AssistantStore>(store, tag: globalTag, permanent: true);
    }
    return store;
  }
}

/// List route, ghép vào AppPages theo quy ước aggregation D2.
final List<GetPage<dynamic>> assistantPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: AssistantRoutes.chat,
    page: () => AssistantScene(
      entry: Get.arguments is AssistantEntry
          ? Get.arguments as AssistantEntry
          : const AssistantEntry.global(),
    ),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];
