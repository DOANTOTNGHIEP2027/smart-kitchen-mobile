import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../widgets/buttons/app_button.dart';
import 'api/auth_api.dart';
import 'otp_scene.dart';
import 'stores/otp_store.dart';
import 'stores/upgrade_profile_store.dart';
import 'widgets/auth_frame.dart';

class UpgradeProfileScene extends StatefulWidget {
  const UpgradeProfileScene({super.key});

  @override
  State<UpgradeProfileScene> createState() => _UpgradeProfileSceneState();
}

class _UpgradeProfileSceneState extends State<UpgradeProfileScene> {
  late final UpgradeProfileStore store = UpgradeProfileStore(Get.find<AuthApi>(), Get.find());
  final email = TextEditingController();
  final password = TextEditingController();
  final fullName = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    fullName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (await store.submit(email: email.text, password: password.text, fullName: fullName.text)) {
      Get.toNamed(AppRoutes.otp, arguments: OtpArguments(email: email.text.trim(), flow: OtpFlow.upgrade));
    }
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
        title: 'upgrade_profile_title'.tr,
        subtitle: 'upgrade_profile_subtitle'.tr,
        child: Observer(builder: (_) => Column(children: [
              if (store.error != null && store.error!.code != 'ERR_AUTH_003') ...[
                FeatureBanner(message: errorCopy(store.error!.code)),
                const SizedBox(height: 16),
              ],
              TextField(controller: email, enabled: !store.isSubmitting, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'email'.tr, errorText: _fieldError('email'))),
              const SizedBox(height: 12),
              TextField(controller: password, enabled: !store.isSubmitting, obscureText: true, decoration: InputDecoration(labelText: 'password'.tr, errorText: _fieldError('password'))),
              const SizedBox(height: 12),
              TextField(controller: fullName, enabled: !store.isSubmitting, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: 'full_name_optional'.tr, errorText: _fieldError('fullName'))),
              const SizedBox(height: 20),
              AppButton(label: 'continue_to_otp'.tr, isLoading: store.isSubmitting, onPressed: _submit),
            ])),
      );

  String? _fieldError(String field) {
    final key = store.fieldErrors[field];
    return key?.tr;
  }
}
