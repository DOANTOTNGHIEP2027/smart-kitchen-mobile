import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final callback = isLoading ? null : onPressed;
    return switch (variant) {
      AppButtonVariant.primary => SizedBox(
          width: double.infinity,
          height: AppDimens.minTapTarget,
          child: FilledButton(
            onPressed: callback,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusMd)),
              ),
            ),
            child: _ButtonContents(label: label, isLoading: isLoading),
          ),
        ),
      AppButtonVariant.secondary => SizedBox(
          width: double.infinity,
          height: AppDimens.minTapTarget,
          child: OutlinedButton(
            onPressed: callback,
            child: _ButtonContents(label: label, isLoading: isLoading),
          ),
        ),
      AppButtonVariant.text => TextButton(
          onPressed: callback,
          child: _ButtonContents(label: label, isLoading: isLoading),
        ),
    };
  }
}

class _ButtonContents extends StatelessWidget {
  const _ButtonContents({required this.label, required this.isLoading});

  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return Text(label);
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}
