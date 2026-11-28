import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../routing/app_routes.dart';
import '../../../utils/l10n_x.dart';
import '../../shell/app_shell_store.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/feature_banner.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../domain/receipt_matched_item.dart';
import '../stores/receipt_scan_store.dart';
import '../widgets/receipt_matched_line_tile.dart';
import '../widgets/receipt_summary_header.dart';
import '../widgets/receipt_unmatched_item_card.dart';

/// Màn kết quả quét (#68, shopping-receipt-scan.md §13.2). Chỉ được push khi
/// scan trả 200; điều hướng nằm ở scene (§12.4, D19).
class ReceiptResultScene extends StatefulWidget {
  const ReceiptResultScene({super.key});

  @override
  State<ReceiptResultScene> createState() => _ReceiptResultSceneState();
}

class _ReceiptResultSceneState extends State<ReceiptResultScene> {
  /// Fix v3: "Xong" bấm 2 lần chỉ pop 1 lần (Get.close(2) × 2 = pop cả shell).
  bool _finishing = false;

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ReceiptScanStore>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isBusy(store)) return;
        _restart(context, store);
      },
      child: Observer(
        builder: (_) {
          final busy = _isBusy(store);
          return AppScaffold(
            title: context.l10n.receiptResultTitle,
            actions: <Widget>[
              if (!busy)
                TextButton(
                  key: const ValueKey<String>('receipt-restart'),
                  onPressed: () => _restart(context, store),
                  child: Text(context.l10n.receiptRestart),
                ),
            ],
            body: _body(context, store),
          );
        },
      ),
    );
  }

  bool _isBusy(ReceiptScanStore store) =>
      store.status == ReceiptScanStatus.committing ||
      store.hasConfirmingUnmatched;

  Widget _body(BuildContext context, ReceiptScanStore store) {
    if (store.isEmptyResult) {
      return AppEmptyView(
        icon: Icons.receipt_long_outlined,
        message: context.l10n.receiptEmpty,
        action: AppButton(
          key: const ValueKey<String>('receipt-retake'),
          label: context.l10n.receiptRetake,
          icon: Icons.photo_camera_outlined,
          expanded: false,
          onPressed: () => _restart(context, store),
        ),
      );
    }
    // idle chỉ xuất hiện thoáng qua sau reset() khi màn đang được pop.
    if (store.status == ReceiptScanStatus.idle) return const SizedBox.shrink();

    final currency = store.meta?.currency ?? 'VND';
    final committing = store.status == ReceiptScanStatus.committing;
    final failedCount = store.failedItemIds.length;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppDimens.md),
            children: <Widget>[
              if (failedCount > 0)
                FeatureBanner(
                  key: const ValueKey<String>('receipt-commit-failed'),
                  message: context.l10n.receiptCommitFailedBanner(failedCount),
                  margin: const EdgeInsets.only(bottom: AppDimens.md),
                ),
              ReceiptSummaryHeader(
                meta: store.meta,
                matchedLines: store.matchedItems.length,
                unmatchedCount: store.unmatchedItems.length,
              ),
              if (store.matchedItems.isNotEmpty)
                ..._matchedSection(context, store, currency, committing),
              if (store.unmatchedItems.isNotEmpty)
                ..._unmatchedSection(context, store, currency),
            ],
          ),
        ),
        _BottomBar(
          child: store.commitPending
              ? AppButton(
                  key: const ValueKey<String>('receipt-commit'),
                  label: context.l10n.receiptCommit(store.selectedItemCount),
                  icon: Icons.checklist_rounded,
                  isLoading: committing,
                  onPressed: committing ? null : () => _commit(context, store),
                )
              : AppButton(
                  key: const ValueKey<String>('receipt-done'),
                  label: context.l10n.receiptDone,
                  isLoading: committing,
                  onPressed: committing || store.hasConfirmingUnmatched
                      ? null
                      : () => _finish(context, store),
                ),
        ),
      ],
    );
  }

  List<Widget> _matchedSection(
    BuildContext context,
    ReceiptScanStore store,
    String currency,
    bool committing,
  ) {
    final lines = store.matchedItems;
    final itemCount = lines.map((line) => line.shoppingItemId).toSet().length;
    final locked = committing || store.matchedCommitted;
    return <Widget>[
      _SectionTitle(
        title: context.l10n.receiptMatchedSection,
        trailing: context.l10n.receiptMatchedCount(lines.length, itemCount),
      ),
      for (final line in lines)
        ReceiptMatchedLineTile(
          key: ValueKey<String>('receipt-line-${line.lineKey}'),
          line: line,
          currency: currency,
          // Đọc observable TRONG builder của Observer, truyền giá trị thuần.
          selected: store.selectedLineKeys.contains(line.lineKey),
          locked: locked,
          outcome: _outcome(store, line),
          onToggle: () => store.toggleMatchedLine(line.lineKey),
        ),
    ];
  }

  ReceiptLineOutcome _outcome(ReceiptScanStore store, ReceiptMatchedItem line) {
    if (!store.matchedCommitted) return ReceiptLineOutcome.none;
    if (!store.selectedLineKeys.contains(line.lineKey)) {
      return ReceiptLineOutcome.skipped;
    }
    if (store.failedItemIds.contains(line.shoppingItemId)) {
      return ReceiptLineOutcome.failed;
    }
    return ReceiptLineOutcome.marked;
  }

  List<Widget> _unmatchedSection(
    BuildContext context,
    ReceiptScanStore store,
    String currency,
  ) {
    final items = store.unmatchedItems;
    return <Widget>[
      _SectionTitle(
        title: context.l10n.receiptUnmatchedSection,
        trailing: context.l10n.receiptUnmatchedCount(items.length),
      ),
      for (final item in items)
        ReceiptUnmatchedItemCard(
          key: ValueKey<String>('receipt-unmatched-${item.itemId}'),
          item: item,
          currency: currency,
          onNameChanged: (value) =>
              store.editUnmatchedItem(item.itemId, name: value),
          onQuantityChanged: (value) =>
              store.editUnmatchedItem(item.itemId, quantity: value),
          onUnitChanged: (value) =>
              store.editUnmatchedItem(item.itemId, unit: value),
          onCategoryChanged: (value) =>
              store.editUnmatchedItem(item.itemId, category: value),
          onExpiryChanged: (value) =>
              store.editUnmatchedItem(item.itemId, expiryDate: value),
          onConfirm: () => store.confirmUnmatchedItem(item.itemId),
        ),
    ];
  }

  /// "Chụp lại" (empty) = "Đặt lại" = back → về màn scan ở trạng thái idle.
  /// KHÔNG `Get.back()` (Guard 15).
  void _restart(BuildContext context, ReceiptScanStore store) {
    store.reset();
    Navigator.of(context).pop();
  }

  Future<void> _commit(BuildContext context, ReceiptScanStore store) async {
    final result = await store.commitMatched();
    // Lần bấm bị guard chặn (double-tap) KHÔNG được điều hướng (Guard 15).
    if (!context.mounted || result.skipped) return;
    if (result.allSucceeded && !store.hasOpenUnmatched) {
      _finish(context, store);
    }
  }

  void _finish(BuildContext context, ReceiptScanStore store) {
    if (_finishing) return;
    _finishing = true;
    final count = store.committedItemIds.length;
    final title = context.l10n.receiptDoneTitle;
    final message = context.l10n.receiptDoneToast(count);
    // Pop ĐÚNG 2 màn (result + scan). KHÔNG Get.until theo tên: Mua sắm là tab
    // trong IndexedStack của shell, không có route '/shopping' (Guard 13).
    Navigator.of(context).popUntil((route) =>
        route.isFirst ||
        route.settings.name == AppRoutes.shellRoot ||
        route.settings.name == AppRoutes.shopping);
    if (Get.isRegistered<AppShellStore>()) {
      Get.find<AppShellStore>().selectTab(3);
    }
    store.reset();
    if (count > 0) {
      Get.snackbar(title, message);
      // #239: món vừa đánh dấu đã mua → xem lại hạn & cất vào kho.
      Get.toNamed<void>(AppRoutes.shoppingCheckout);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.lg, bottom: AppDimens.sm),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(title, style: textTheme.titleSmall)),
          Text(
            trailing,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: child,
      ),
    );
  }
}
