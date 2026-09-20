import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/buttons/app_button.dart';
import '../auth/widgets/auth_frame.dart';

class HouseholdSetupScene extends StatelessWidget {
  const HouseholdSetupScene({super.key});

  @override
  Widget build(BuildContext context) => AuthFrame(
        title: 'household_setup_title'.localized(context),
        subtitle: 'household_setup_subtitle'.localized(context),
        child: Column(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4EC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.home_outlined, color: Color(0xFFFF7A45), size: 30),
          ),
          const SizedBox(height: 20),
          AppButton(
              icon: Icons.add_home_outlined,
              label: 'create_household'.localized(context),
              onPressed: () => Get.toNamed(AppRoutes.householdCreate)),
          const SizedBox(height: 12),
          AppButton(
              icon: Icons.qr_code_scanner_outlined,
              label: 'join_household'.localized(context),
              variant: AppButtonVariant.secondary,
              onPressed: () => Get.toNamed(AppRoutes.qrJoin,
                  arguments: const {'manual': true})),
        ]),
      );
}
