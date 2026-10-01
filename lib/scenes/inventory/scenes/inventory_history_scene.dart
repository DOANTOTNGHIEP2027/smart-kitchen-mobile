import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_error_view.dart';
import '../../../widgets/states/app_loading_view.dart';
import '../domain/inventory_item.dart';
import '../domain/inventory_transaction.dart';
import '../stores/inventory_history_store.dart';

class InventoryHistoryScene extends StatefulWidget {
  const InventoryHistoryScene({super.key});

  @override
  State<InventoryHistoryScene> createState() => _InventoryHistorySceneState();
}

class _InventoryHistorySceneState extends State<InventoryHistoryScene> {
  late final InventoryHistoryStore store;
  InventoryItemModel? item;

  @override
  void initState() {
    super.initState();
    store = Get.find<InventoryHistoryStore>();
    item = Get.arguments is InventoryItemModel
        ? Get.arguments as InventoryItemModel
        : null;
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.inventoryHistoryTitle,
      body: Column(
        children: <Widget>[
          if (item != null) _ItemSummary(item: item!),
          Expanded(
            child: Observer(
              builder: (_) {
                switch (store.status) {
                  case InventoryHistoryStatus.loading:
                    return const AppLoadingView();
                  case InventoryHistoryStatus.error:
                    return AppErrorView(
                      message: context.l10n.inventoryHistoryLoadFailed,
                      onRetry: () => store.load(refresh: true),
                    );
                  case InventoryHistoryStatus.ready:
                    if (store.items.isEmpty) {
                      return AppEmptyView(
                        icon: Icons.history_rounded,
                        message: context.l10n.inventoryHistoryEmpty,
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => store.load(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.md,
                          AppDimens.sm,
                          AppDimens.md,
                          AppDimens.xl,
                        ),
                        itemCount: store.items.length + 1,
                        itemBuilder: (context, index) {
                          if (index == store.items.length) {
                            if (!store.canLoadMore) {
                              return const SizedBox(height: AppDimens.md);
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: AppDimens.sm),
                              child: AppButton(
                                label: context.l10n.inventoryHistoryLoadMore,
                                isLoading: store.isLoadingMore,
                                variant: AppButtonVariant.outline,
                                onPressed:
                                    store.isLoadingMore ? null : store.loadMore,
                              ),
                            );
                          }
                          return _TransactionTile(
                            transaction: store.items[index],
                          );
                        },
                      ),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemSummary extends StatelessWidget {
  const _ItemSummary({required this.item});

  final InventoryItemModel item;

  @override
  Widget build(BuildContext context) {
    final quantity = item.displayQuantity ?? item.quantity;
    final unit = item.displayUnit ?? item.unit;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppDimens.md,
        AppDimens.md,
        AppDimens.md,
        AppDimens.sm,
      ),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.inventory_2_outlined),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(context.l10n.inventoryHistoryCurrentQuantity(
                  _formatNumber(quantity),
                  unit,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final InventoryTransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final delta = transaction.quantityDelta;
    final deltaText = '${delta > 0 ? '+' : ''}${_formatNumber(delta)} '
        '${transaction.unit}';
    final date = DateFormat.yMd(Localizations.localeOf(context).toString())
        .add_Hm()
        .format(transaction.createdAt.toLocal());
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.sm),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(_iconFor(transaction.reason), size: 20),
        ),
        title: Text(_reasonLabel(context, transaction.reason)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(date),
            if (transaction.wasteCause != null)
              Text(_wasteCauseLabel(context, transaction.wasteCause!)),
            if (transaction.note?.trim().isNotEmpty == true)
              Text(transaction.note!.trim()),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              deltaText,
              style: TextStyle(
                color: delta < 0
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              context.l10n.inventoryHistoryRemaining(
                _formatNumber(transaction.quantityAfter),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String reason) => switch (reason) {
        'BOUGHT' => Icons.add_shopping_cart_outlined,
        'COOKED' => Icons.restaurant_outlined,
        'EXPIRED' => Icons.event_busy_outlined,
        'WASTE' => Icons.delete_outline,
        _ => Icons.edit_outlined,
      };

  String _reasonLabel(BuildContext context, String reason) => switch (reason) {
        'BOUGHT' => context.l10n.inventoryHistoryReasonBought,
        'COOKED' => context.l10n.inventoryHistoryReasonCooked,
        'EXPIRED' => context.l10n.inventoryHistoryReasonExpired,
        'WASTE' => context.l10n.inventoryHistoryReasonWaste,
        _ => context.l10n.inventoryHistoryReasonCorrected,
      };

  String _wasteCauseLabel(BuildContext context, String cause) =>
      switch (cause) {
        'OVERBOUGHT' => context.l10n.inventoryWasteOverbought,
        'FORGOTTEN' => context.l10n.inventoryWasteForgotten,
        'SPOILED_EARLY' => context.l10n.inventoryWasteSpoiledEarly,
        _ => context.l10n.inventoryWasteUntagged,
      };
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
