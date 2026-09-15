import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Trạng thái loading dùng chung (fe-app-shell.md §10.3).
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
}
