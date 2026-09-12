import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../stores/session_store.dart';
import '../../widgets/buttons/app_button.dart';
import 'stores/auth_store.dart';
import 'widgets/auth_frame.dart';

class EmailLoginScene extends StatefulWidget {
  const EmailLoginScene({super.key});

  @override
  State<EmailLoginScene> createState() => _EmailLoginSceneState();
}

class _EmailLoginSceneState extends State<EmailLoginScene> {
  late final AuthStore store = Get.find<AuthStore>();
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    store.reset();
    super.dispose();
  }

  Future<void> _submit() async {
    if (await store.login(email: email.text, password: password.text)) {
      final session = Get.find<SessionStore>();
      Get.offAllNamed(session.householdId == null ? AppRoutes.householdSetup : AppRoutes.shellRoot);
    }
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
        title: 'login_title'.tr,
        subtitle: 'login_subtitle'.tr,
        child: Observer(builder: (_) {
          final locked = store.isLoginLocked;
          return Column(children: [
            if (locked) ...[
              FeatureBanner(message: '${'auth_rate_limited'.tr} ${store.loginLockSeconds}s'),
              const SizedBox(height: 16),
            ] else if (store.error != null && store.error!.code != 'ERR_AUTH_004') ...[
              FeatureBanner(message: errorCopy(store.error!.code)),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: email,
              enabled: !store.isSubmitting && !locked,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(labelText: 'email'.tr, errorText: _fieldError('email')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              enabled: !store.isSubmitting && !locked,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(labelText: 'password'.tr, errorText: _fieldError('password')),
            ),
            const SizedBox(height: 20),
            AppButton(label: 'sign_in'.tr, isLoading: store.isSubmitting, onPressed: locked ? null : _submit),
            AppButton(label: 'no_account_register'.tr, variant: AppButtonVariant.text, onPressed: () => Get.offNamed(AppRoutes.register)),
          ]);
        }),
      );

  String? _fieldError(String field) {
    final key = store.fieldErrors[field];
    return key?.tr;
  }
}
