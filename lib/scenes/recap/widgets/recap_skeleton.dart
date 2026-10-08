import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';

/// Khung xương hero + stats + card khi đang loading (state 1, §10). Không phải
/// shimmer phức tạp — chỉ là các khối xám tĩnh cho bố cục ổn định.
class RecapSkeleton extends StatelessWidget {
  const RecapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final block = Container(
      height: AppDimens.md,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(AppDimens.md),
      children: <Widget>[
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              block,
              const SizedBox(height: AppDimens.sm),
              FractionallySizedBox(
                widthFactor: 0.6,
                child: block,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.md),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Row(
            children: <Widget>[
              for (var i = 0; i < 3; i++) ...<Widget>[
                Expanded(child: block),
                if (i < 2) const SizedBox(width: AppDimens.md),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppDimens.md),
        Center(child: SizedBox(width: 60, height: 60, child: block)),
      ],
    );
  }
}