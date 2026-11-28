import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/feedback/app_toast.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_error_view.dart';
import '../../profile/profile_family_routes.dart';
import '../stores/monthly_recap_store.dart';
import '../widgets/monthly_recap_widgets.dart';
import '../widgets/recap_skeleton.dart';
import '../widgets/waste_spend_sections.dart';

/// Màn Tổng kết tháng — cùng bố cục Tổng kết tuần (thẻ chia sẻ, insight từng
/// thành viên, lãng phí & chi tiêu) cộng thanh chuyển tháng.
class MonthlyRecapScene extends StatefulWidget {
  const MonthlyRecapScene({super.key});

  @override
  State<MonthlyRecapScene> createState() => _MonthlyRecapSceneState();
}

class _MonthlyRecapSceneState extends State<MonthlyRecapScene> {
  late final MonthlyRecapStore _store;
  final _shareCardKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _store = Get.find<MonthlyRecapStore>();
    _store.loadCurrentMonth();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.monthlyRecapTitle,
      body: Observer(builder: (context) {
        final status = _store.status;
        if (status == MonthlyRecapStatus.noHousehold) {
          return AppEmptyView(message: l10n.monthlyRecapNoHousehold);
        }
        final navigator = MonthNavigator(
          month: _store.month,
          canGoPrevious: _store.canGoPrevious,
          canGoNext: _store.canGoNext,
          onPrevious: _store.previousMonth,
          onNext: _store.nextMonth,
        );
        final Widget content;
        switch (status) {
          case MonthlyRecapStatus.loading:
            content = const RecapSkeleton();
          case MonthlyRecapStatus.error:
            content = AppErrorView(
              message: apiErrorMessage(l10n, _store.error,
                  fallback: l10n.recapError),
              onRetry: _store.retry,
            );
          case MonthlyRecapStatus.noHousehold:
          case MonthlyRecapStatus.ready:
            content = _buildReady(context);
        }
        return Column(
          children: <Widget>[
            navigator,
            Expanded(child: content),
          ],
        );
      }),
    );
  }

  Widget _buildReady(BuildContext context) {
    final l10n = context.l10n;
    final s = _store.summary!;
    final spend = s.toSpendSummary();
    final range = monthlyRecapRange(context, s.month);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _store.reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          RepaintBoundary(
            key: _shareCardKey,
            child: MonthlyRecapShareCard(
              summary: s,
              ownInsight: _store.ownInsight?.summary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.md,
              vertical: AppDimens.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.md,
                      vertical: 8,
                    ),
                  ),
                  onPressed: _isSharing ? null : _share,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        )
                      : const Icon(Icons.share_rounded, size: 18),
                  label: Text(
                    l10n.recapShareTooltip,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          MonthlyInsightList(
            members: _store.orderedMemberInsights,
            emptyText: l10n.monthlyRecapEmptyInsights,
          ),
          // Ngoài RepaintBoundary — số tiền không lọt vào ảnh chia sẻ.
          RecapSectionTitle(l10n.recapWasteSpendTitle),
          WasteSection(
            count: s.wasteItemCount,
            breakdown: s.wasteCauseBreakdown,
            weekStart: s.month,
            period: RecapPeriod.month,
            subtitle: range,
          ),
          SpendSection(
            summary: spend,
            canSetBudget: _store.canSetBudget,
            onSetBudget: () => Get.toNamed<void>(ProfileFamilyRoutes.family),
            period: RecapPeriod.month,
            subtitle: range,
          ),
          SpendDetailSection(
            gate: _store.spendDetailGate!,
            summary: spend,
            period: RecapPeriod.month,
            // Nâng cấp xong LUÔN tải lại (claim có thể chưa kịp đổi).
            onUpgrade: () async {
              await Get.toNamed<void>(ProfileFamilyRoutes.tierUpgrade);
              if (mounted) await _store.reload();
            },
          ),
          const SizedBox(height: AppDimens.lg),
        ],
      ),
    );
  }

  /// Chụp PNG thẻ chia sẻ rồi mở share sheet; lỗi thì báo toast, không crash.
  Future<void> _share() async {
    final l10n = context.l10n;
    setState(() => _isSharing = true);
    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getTemporaryDirectory();
      final file = await File(
        '${dir.path}/monthly_recap_${DateTime.now().millisecondsSinceEpoch}.png',
      ).writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: l10n.monthlyRecapShare,
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(l10n.recapShareFailed, type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}
