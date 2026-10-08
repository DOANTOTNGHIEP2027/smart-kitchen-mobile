import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../constants/app_text_styles.dart';
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
    return Card(
      margin: const EdgeInsets.all(AppDimens.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
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
          Text(l10n.recapHeroFallback,
              key: ShareableRecapCard.recapHeroFallbackKey,
              style: AppTextStyles.titleMedium),
          if (householdSummary != null) ...<Widget>[
            const SizedBox(height: AppDimens.sm),
            Text(householdSummary,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                )),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: RecapBadgeColors.of(insight.badge).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.emoji_events,
            color: RecapBadgeColors.of(insight.badge),
          ),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(insight.highlight,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontStyle: FontStyle.italic,
                  )),
              if (householdSummary != null) ...<Widget>[
                const SizedBox(height: AppDimens.sm),
                Text(
                  householdSummary,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
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

/// 3 số household-level — KHÔNG gắn nhãn ngày cụ thể (Guard #4). Tách bạch
/// `adherencePercent` khỏi `compliancePct` (Guard #1).
class HouseholdStatsStrip extends StatelessWidget {
  const HouseholdStatsStrip({super.key, required this.l10n, required this.summary});

  final AppLocalizations l10n;
  final WeeklyRecapSummary summary;

  @override
  Widget build(BuildContext context) {
    final avg = summary.avgCaloriesKcal;
    final adherence = summary.adherencePercent;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        _StatCell(
          value: summary.mealsLoggedCount.toString(),
          label: l10n.recapMealsLogged(summary.mealsLoggedCount),
        ),
        _StatCell(
          value: avg != null ? avg.round().toString() : '—',
          label: l10n.recapAvgCalories(avg?.round() ?? 0),
        ),
        Expanded(
          child: Column(
            children: <Widget>[
              Text(
                adherence != null
                    ? '${adherence.round()}%'
                    : '—',
                style: AppTextStyles.titleLarge,
              ),
              Text(
                l10n.recapAdherenceCaption,
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value, style: AppTextStyles.titleLarge),
        const SizedBox(height: AppDimens.xs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}