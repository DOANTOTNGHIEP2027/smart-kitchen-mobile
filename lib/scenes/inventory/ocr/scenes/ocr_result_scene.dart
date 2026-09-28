import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_dimens.dart';
import '../../../../utils/l10n_x.dart';
import '../../../../widgets/app_scaffold.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../inventory_routes.dart';
import '../stores/ocr_store.dart';
import '../widgets/ocr_item_card.dart';

class OcrResultScene extends StatelessWidget {
  const OcrResultScene({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<OcrStore>();
    return Observer(
      builder: (_) {
        final confirming = store.status == OcrStatus.confirming;
        return AppScaffold(
          title: context.l10n.inventoryOcrResultTitle(store.items.length),
          actions: store.items.isEmpty
              ? null
              : <Widget>[
                  TextButton(
                    onPressed: confirming || !store.canConfirmAll
                        ? null
                        : () => _confirmAll(store),
                    child: Text(context.l10n.inventoryOcrConfirmAll),
                  ),
                ],
          body: store.items.isEmpty
              ? _EmptyResult(onRetake: () => _retake(store))
              : _ResultList(
                  store: store,
                  confirming: confirming,
                  onSave: (id) => _confirmOne(store, id),
                  onRemove: (id) {
                    store.removeItem(id);
                    _finishIfDone(store);
                  },
                ),
        );
      },
    );
  }

  Future<void> _confirmAll(OcrStore store) async {
    await store.confirmAll();
    _finishIfDone(store);
  }

  Future<void> _confirmOne(OcrStore store, String id) async {
    await store.confirmItem(id);
    _finishIfDone(store);
  }

  void _finishIfDone(OcrStore store) {
    if (store.status != OcrStatus.done) return;
    Get.until((route) => route.settings.name == InventoryRoutes.list);
    store.reset();
  }

  void _retake(OcrStore store) {
    store.reset();
    Get.back<void>();
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.onRetake});

  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.border,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_outlined),
            ),
            const SizedBox(height: AppDimens.md),
            Text(
              context.l10n.inventoryOcrEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimens.md),
            SizedBox(
              width: 180,
              child: AppButton(
                label: context.l10n.inventoryOcrRetake,
                icon: Icons.photo_camera_outlined,
                onPressed: onRetake,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.store,
    required this.confirming,
    required this.onSave,
    required this.onRemove,
  });

  final OcrStore store;
  final bool confirming;
  final ValueChanged<String> onSave;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (confirming)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.md,
              AppDimens.sm,
              AppDimens.md,
              0,
            ),
            child: Column(
              children: <Widget>[
                LinearProgressIndicator(
                  value: store.items.isEmpty
                      ? 0
                      : store.confirmedCount / store.items.length,
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.inventoryOcrSavingProgress(
                    store.confirmedCount,
                    store.items.length,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        if (!confirming && store.failedCount > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppDimens.md,
              AppDimens.md,
              AppDimens.md,
              0,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E0),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: Text(
                    context.l10n.inventoryOcrPartialFailure(store.failedCount),
                    style: const TextStyle(color: Color(0xFF8B6A00)),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimens.md),
            itemCount: store.items.length,
            itemBuilder: (context, index) {
              final item = store.items[index];
              return OcrItemCard(
                key: ValueKey<String>(item.itemId),
                item: item,
                locked: confirming,
                onChanged: ({
                  String? name,
                  Object? quantity = _unchanged,
                  Object? unit = _unchanged,
                  Object? expiryEstimate = _unchanged,
                }) {
                  store.editItem(
                    item.itemId,
                    name: name,
                    quantity: identical(quantity, _unchanged)
                        ? item.quantity
                        : quantity,
                    unit: identical(unit, _unchanged) ? item.unit : unit,
                    expiryEstimate: identical(expiryEstimate, _unchanged)
                        ? item.expiryEstimate
                        : expiryEstimate,
                  );
                },
                onSave: () => onSave(item.itemId),
                onRemove: () => onRemove(item.itemId),
              );
            },
          ),
        ),
      ],
    );
  }
}

const Object _unchanged = Object();
