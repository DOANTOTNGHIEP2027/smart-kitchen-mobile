import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../constants/app_text_styles.dart';
import '../../../utils/l10n_x.dart';

/// Banner vàng khi data đến từ cache offline. Không chặn — chỉ tín hiệu.
class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md, vertical: AppDimens.sm),
      color: AppColors.warning.withValues(alpha: 0.12),
      child: Row(
        children: <Widget>[
          const Icon(Icons.cloud_off, size: 18, color: AppColors.warning),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Text(
              message ?? context.l10n.staleDataBanner,
              style: AppTextStyles.label.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
