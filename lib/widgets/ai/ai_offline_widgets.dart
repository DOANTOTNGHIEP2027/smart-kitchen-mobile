import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../data/ai_runtime/ai_result.dart';
import '../../utils/l10n_x.dart';
import '../feature_banner.dart';

/// Banner khi màn hình ĐANG dựa vào kết quả on-device (§9.1) — không phải
/// banner "mất mạng" toàn app. Chỉ dựa vào `AIResult.isDegraded` (§9.3).
class OfflineModeBanner extends StatelessWidget {
  const OfflineModeBanner({super.key, required this.result, this.message});

  final AIResult<Object?> result;

  /// Câu theo ngữ cảnh task; `null` → câu mặc định.
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (!result.isDegraded) return const SizedBox.shrink();
    return FeatureBanner(
      key: const ValueKey<String>('offline-mode-banner'),
      message: message ?? context.l10n.aiOfflineModeBanner,
      isError: false,
      margin: const EdgeInsets.only(bottom: AppDimens.sm),
    );
  }
}

/// Badge nhỏ trên từng result card (§9.2) — chỉ hiện khi kết quả on-device.
class AIResultSourceBadge extends StatelessWidget {
  const AIResultSourceBadge({super.key, required this.result});

  final AIResult<Object?> result;

  @override
  Widget build(BuildContext context) {
    if (!result.isDegraded) return const SizedBox.shrink();
    final confidence = result.confidence;
    return Container(
      key: const ValueKey<String>('ai-source-badge'),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Text(
        confidence == null
            ? context.l10n.aiOfflineEstimate
            : context.l10n.aiOfflineEstimateConfidence((confidence * 100).round()),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
