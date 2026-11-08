import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../domain/household_streak.dart';
import '../domain/weekly_recap_summary.dart';
import '../stores/weekly_recap_store.dart';
import 'recap_badge_colors.dart';
import 'streak_counter_widget.dart';

/// Bọc `RecapHeroSection` + `HouseholdStatsStrip` + `StreakCounterWidget` —
/// nằm TRONG `RepaintBoundary` của scene (Guard #12). Chỉ nhận dữ liệu qua
/// constructor, không đọc store (Guard #8).
class ShareableRecapCard extends StatelessWidget {
  const ShareableRecapCard({
    super.key,
    required this.summary,
    required this.ownInsight,
    required this.streakStatus,
    required this.streak,
    required this.onRetryStreak,
  });

  /// Public để widget test dựng card trực tiếp.
  static const recapHeroFallbackKey = Key('recapHeroFallback');

  final WeeklyRecapSummary summary;
  final MemberWeeklyInsight? ownInsight;
  final RecapLoadStatus streakStatus;
  final HouseholdStreak? streak;
  final VoidCallback onRetryStreak;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _RecapHeroSection(ownInsight: ownInsight, summary: summary),
            const SizedBox(height: AppDimens.lg),
            HouseholdStatsStrip(l10n: l10n, summary: summary),
            const SizedBox(height: AppDimens.lg),
            StreakCounterWidget(
              loading: streakStatus == RecapLoadStatus.loading,
              error: streakStatus == RecapLoadStatus.error,
              onRetry: onRetryStreak,
              retryLabel: l10n.recapStreakRetry,
              streakLabel: l10n.recapStreak(
                streak?.currentStreak ?? 0,
              ),
              bestLabel: l10n.recapStreakBest(streak?.bestStreak ?? 0),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge của chính người xem + highlight + householdSummary. `ownInsight ==
/// null` (isStale=true HOẶC self không đủ điều kiện) → fallback trung tính,
/// KHÔNG đoán badge (decision-log D11).
class _RecapHeroSection extends StatelessWidget {
  const _RecapHeroSection({required this.ownInsight, required this.summary});

  final MemberWeeklyInsight? ownInsight;
  final WeeklyRecapSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final insight = ownInsight;
    final householdSummary = summary.householdSummary;
    if (insight == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.recapHeroFallback,
            key: ShareableRecapCard.recapHeroFallbackKey,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (householdSummary != null) ...<Widget>[
            const SizedBox(height: AppDimens.sm),
            Text(
              householdSummary,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ],
      );
    }
    final badgeColor = RecapBadgeColors.of(insight.badge);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.emoji_events_rounded,
            color: badgeColor,
            size: 26,
          ),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  insight.highlight,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
              if (householdSummary != null) ...<Widget>[
                const SizedBox(height: AppDimens.sm),
                Text(
                  householdSummary,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 3 số household-level — KPI cards hiện đại, thoáng, có phân cấp rõ ràng.
class HouseholdStatsStrip extends StatelessWidget {
  const HouseholdStatsStrip({super.key, required this.l10n, required this.summary});

  final AppLocalizations l10n;
  final WeeklyRecapSummary summary;

  @override
  Widget build(BuildContext context) {
    final avg = summary.avgCaloriesKcal;
    final adherence = summary.adherencePercent;
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            icon: Icons.restaurant_rounded,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.primaryContainer,
            value: summary.mealsLoggedCount.toString(),
            label: l10n.recapMealsLogged(summary.mealsLoggedCount),
          ),
        ),
        const SizedBox(width: AppDimens.xs),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFF9500),
            iconBgColor: const Color(0xFFFFF3E0),
            value: avg != null ? avg.round().toString() : '—',
            label: l10n.recapAvgCalories(avg?.round() ?? 0),
          ),
        ),
        const SizedBox(width: AppDimens.xs),
        Expanded(
          child: _StatCard(
            icon: Icons.verified_rounded,
            iconColor: AppColors.success,
            iconBgColor: AppColors.successSurface,
            value: adherence != null ? '${adherence.round()}%' : '—',
            label: l10n.recapAdherenceCaption,
            valueColor: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.value,
    required this.label,
    this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: AppDimens.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
