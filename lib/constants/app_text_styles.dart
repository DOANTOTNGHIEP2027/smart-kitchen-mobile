import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const title = TextStyle(
    color: AppColors.text,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(color: AppColors.text, fontSize: 14);
  static const caption = TextStyle(color: AppColors.muted, fontSize: 12);
}
