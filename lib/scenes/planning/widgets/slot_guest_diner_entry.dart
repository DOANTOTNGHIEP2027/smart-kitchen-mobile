import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../data/network/dio_client.dart';
import '../../../utils/l10n_x.dart';
import '../data/guest_diner_api.dart';
import '../scenes/planning_routes.dart';
import '../stores/guest_diner_store.dart';

/// #201: mục "Khách ăn cùng bữa này" trong màn sửa bữa — hiện số khách riêng
/// của bữa, bấm mở màn khách theo đúng slot, quay lại thì đếm lại.
class SlotGuestDinerEntry extends StatefulWidget {
  const SlotGuestDinerEntry({
    super.key,
    required this.planId,
    required this.slotId,
  });

  final String planId;
  final String slotId;

  @override
  State<SlotGuestDinerEntry> createState() => _SlotGuestDinerEntryState();
}

class _SlotGuestDinerEntryState extends State<SlotGuestDinerEntry> {
  late final SlotGuestCountStore _store;

  @override
  void initState() {
    super.initState();
    _store = SlotGuestCountStore(_resolveApi(), widget.planId, widget.slotId);
    _store.load();
  }

  /// Api đăng ký ở binding route khách (fenix); màn sửa bữa có thể mở trước
  /// route đó nên tự dựng từ DioClient. Không có cả hai (test) → không đếm.
  static GuestDinerApi? _resolveApi() {
    if (Get.isRegistered<GuestDinerApi>()) return Get.find<GuestDinerApi>();
    if (Get.isRegistered<DioClient>()) {
      return GuestDinerApi(Get.find<DioClient>());
    }
    return null;
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    await Get.toNamed<void>(
        PlanningRoutes.slotGuestDinersOf(widget.planId, widget.slotId));
    if (mounted) await _store.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(top: AppDimens.sm, bottom: AppDimens.md),
      child: Observer(
        builder: (_) {
          final count = _store.count;
          return ListTile(
            key: const ValueKey<String>('slot-guest-diners'),
            leading: const Icon(Icons.group_add_outlined, color: AppColors.sage),
            title: Text(l10n.planningGuestSlotTitle),
            subtitle: count == null
                ? null
                : Text(l10n.planningGuestSlotCount(count),
                    key: const ValueKey<String>('slot-guest-diners-count')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _open,
          );
        },
      ),
    );
  }
}
