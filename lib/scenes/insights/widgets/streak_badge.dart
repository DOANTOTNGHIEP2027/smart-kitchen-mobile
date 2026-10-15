import 'package:flutter/material.dart';

import '../../../utils/l10n_x.dart';
import '../domain/streak_summary.dart';

/// Badge hiện streak hiện tại + kỷ lục của household (tab Mức Độ Tuân Thủ).
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak});

  final StreakSummary streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department,
          color: streak.currentStreak > 0 ? Colors.orange : Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(
          context.l10n.insightsStreakText(
            streak.bestStreak,
            streak.currentStreak,
          ),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}