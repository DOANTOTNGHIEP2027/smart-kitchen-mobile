import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';

/// Icon lửa nhấp nháy (decorative-only — không điều kiện theo currentStreak,
/// decision-log D9). weekly-recap-screen.md §9.4.
class StreakFlameIcon extends StatefulWidget {
  const StreakFlameIcon({super.key});

  @override
  State<StreakFlameIcon> createState() => _StreakFlameIconState();
}

class _StreakFlameIconState extends State<StreakFlameIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => Transform.scale(
          scale: 0.92 + (_controller.value * 0.16),
          child: Opacity(
            opacity: 0.85 + (_controller.value * 0.15),
            child: child,
          ),
        ),
        child: const Icon(
          Icons.local_fire_department,
          color: Color(0xFFFF6D00),
          size: 26,
        ),
      );
}

/// Ô streak counter — sub-state riêng theo [status]. Sub-state này KHÔNG ảnh
/// hưởng phần còn lại của màn hình (decision-log D2, state 8 §10).
class StreakCounterWidget extends StatelessWidget {
  const StreakCounterWidget({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.retryLabel,
    required this.streakLabel,
    required this.bestLabel,
  });

  final bool loading;
  final bool error;
  final VoidCallback onRetry;
  final String retryLabel;
  final String streakLabel;
  final String bestLabel;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (error) {
      return IconButton(
        tooltip: retryLabel,
        onPressed: onRetry,
        icon: const Icon(Icons.error_outline, size: 20),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: AppColors.primaryLight, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const StreakFlameIcon(),
          const SizedBox(width: 8),
          Text(
            streakLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            ),
            child: Text(
              bestLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
