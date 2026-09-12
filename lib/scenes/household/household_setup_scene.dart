import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../widgets/buttons/app_button.dart';
import '../auth/widgets/auth_frame.dart';

class HouseholdSetupScene extends StatelessWidget {
  const HouseholdSetupScene({super.key});

  @override
  Widget build(BuildContext context) => AuthFrame(
        title: 'household_setup_title'.tr,
        subtitle: 'household_setup_subtitle'.tr,
        child: Column(children: [
          AppButton(
              label: 'create_household'.tr,
              onPressed: () => Get.toNamed(AppRoutes.householdCreate)),
          const SizedBox(height: 12),
          AppButton(
              label: 'join_household'.tr,
              variant: AppButtonVariant.secondary,
              onPressed: () => Get.toNamed(AppRoutes.qrJoin,
                  arguments: const {'manual': true})),
        ]),
      );
}
