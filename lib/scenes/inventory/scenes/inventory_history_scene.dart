import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
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

/// Lịch sử xuất nhập tồn kho — phong cách Tasty:
/// Thẻ thông tin mặt hàng thoáng đãng, timeline giao dịch rõ ràng với mã màu trực quan.
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
                      color: AppColors.sage,
                      onRefresh: () => store.load(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.md,
                          AppDimens.xs,
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
        AppDimens.xs,
      ),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.sageLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.sage,
              size: 22,
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.inventoryHistoryCurrentQuantity(
                    _formatNumber(quantity),
                    unit,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.sageLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Text(
              '${_formatNumber(quantity)} $unit',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.sageDark,
              ),
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

    final isPositive = delta > 0;
    final reasonColor = _colorForReason(transaction.reason);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: reasonColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconFor(transaction.reason),
                size: 20,
                color: reasonColor,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _reasonLabel(context, transaction.reason),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                  ),
                  if (transaction.wasteCause != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      _wasteCauseLabel(context, transaction.wasteCause!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontSize: 11,
                          ),
                    ),
                  ],
                  if (transaction.note?.trim().isNotEmpty == true) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      transaction.note!.trim(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AppColors.sageLight
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    deltaText,
                    style: TextStyle(
                      color: isPositive ? AppColors.sageDark : AppColors.error,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.inventoryHistoryRemaining(
                    _formatNumber(transaction.quantityAfter),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForReason(String reason) {
    switch (reason) {
      case 'BOUGHT':
      case 'RESTOCKED':
        return AppColors.sage;
      case 'COOKED':
        return const Color(0xFF0284C7);
      case 'WASTE':
      case 'EXPIRED':
        return AppColors.error;
      case 'CORRECTED':
      default:
        return const Color(0xFFD97706);
    }
  }

  IconData _iconFor(String reason) {
    switch (reason) {
      case 'BOUGHT':
      case 'RESTOCKED':
        return Icons.add_shopping_cart_rounded;
      case 'COOKED':
        return Icons.restaurant_rounded;
      case 'WASTE':
      case 'EXPIRED':
        return Icons.delete_outline_rounded;
      case 'CORRECTED':
      default:
        return Icons.edit_note_rounded;
    }
  }

  String _reasonLabel(BuildContext context, String reason) => switch (reason) {
        'BOUGHT' || 'RESTOCKED' => context.l10n.inventoryHistoryReasonBought,
        'COOKED' => context.l10n.inventoryHistoryReasonCooked,
        'EXPIRED' => context.l10n.inventoryHistoryReasonExpired,
        'WASTE' => context.l10n.inventoryHistoryReasonWaste,
        _ => context.l10n.inventoryHistoryReasonCorrected,
      };

  String _wasteCauseLabel(BuildContext context, String cause) =>
      switch (cause) {
        'OVERBOUGHT' => context.l10n.inventoryWasteOverbought,
        'FORGOTTEN' => context.l10n.inventoryWasteForgotten,
        'SPOILED_EARLY' || 'SPOILED' => context.l10n.inventoryWasteSpoiledEarly,
        _ => context.l10n.inventoryWasteUntagged,
      };
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}
