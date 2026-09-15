import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../stores/session_store.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/buttons/app_button.dart';
import 'stores/auth_store.dart';
import 'widgets/auth_frame.dart';

class AuthLandingScene extends StatefulWidget {
  const AuthLandingScene({super.key});

  @override
  State<AuthLandingScene> createState() => _AuthLandingSceneState();
}

class _AuthLandingSceneState extends State<AuthLandingScene> {
  late final AuthStore store = Get.find<AuthStore>();

  Future<void> _google() async {
    if (await store.googleSignIn()) {
      if (!mounted) return;
      if (store.accountLinked) {
        Get.snackbar('app_title'.localized(context), 'google_account_linked'.localized(context));
      }
      _routeAfterAuth();
    }
  }

  void _routeAfterAuth() {
    final session = Get.find<SessionStore>();
    Get.offAllNamed(session.householdId == null ? AppRoutes.householdSetup : AppRoutes.shellRoot);
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
        title: 'app_title'.localized(context),
        subtitle: 'auth_landing_subtitle'.localized(context),
        showBrand: true,
        child: Observer(builder: (_) => Column(children: [
              if (store.error != null) ...[
                FeatureBanner(message: errorCopy(context, store.error!.code)),
                const SizedBox(height: 16),
              ],
              AppButton(label: 'google_sign_in'.localized(context), isLoading: store.isSubmitting, onPressed: _google),
              const SizedBox(height: 12),
              AppButton(label: 'email_sign_in'.localized(context), variant: AppButtonVariant.secondary, onPressed: () => Get.toNamed(AppRoutes.emailLogin)),
              const SizedBox(height: 12),
              AppButton(label: 'email_register'.localized(context), variant: AppButtonVariant.secondary, onPressed: () => Get.toNamed(AppRoutes.register)),
              const SizedBox(height: 12),
              AppButton(label: 'scan_join_qr'.localized(context), variant: AppButtonVariant.text, onPressed: () => Get.toNamed(AppRoutes.qrJoin)),
            ])),
      );
}
