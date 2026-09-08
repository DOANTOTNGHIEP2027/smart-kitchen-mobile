import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/states/app_empty_view.dart';

/// A route seam for feature 1. It deliberately contains no authentication flow.
class LoginPlaceholderScene extends StatelessWidget {
  const LoginPlaceholderScene({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'app_title'.tr,
      body: AppEmptyView(
        icon: Icons.login_rounded,
        message: 'sign_in_unavailable'.tr,
      ),
    );
  }
}
