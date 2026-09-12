import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../widgets/buttons/app_button.dart';
import 'api/auth_api.dart';
import 'stores/otp_store.dart';
import 'widgets/auth_frame.dart';

class OtpArguments {
  const OtpArguments({required this.email, required this.flow});

  final String email;
  final OtpFlow flow;
}

class OtpScene extends StatefulWidget {
  const OtpScene({super.key});

  @override
  State<OtpScene> createState() => _OtpSceneState();
}

class _OtpSceneState extends State<OtpScene> {
  late final OtpArguments arguments = Get.arguments as OtpArguments;
  late final OtpStore store = OtpStore(Get.find<AuthApi>(), Get.find(), email: arguments.email, flow: arguments.flow);
  final code = TextEditingController();

  @override
  void dispose() {
    code.dispose();
    store.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!await store.verify(code.text)) {
      if (store.error?.code == 'ERR_AUTH_OTP_INVALID') code.clear();
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (arguments.flow == OtpFlow.upgrade) {
      Get.offAllNamed(AppRoutes.shellRoot, arguments: const {'profileTab': true});
    } else {
      Get.offAllNamed(AppRoutes.householdSetup);
    }
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
        title: 'otp_title'.tr,
        subtitle: '${'otp_sent_to'.tr}\n${arguments.email}',
        child: Observer(builder: (_) => Column(children: [
              if (store.error != null) ...[
                FeatureBanner(message: errorCopy(store.error!.code)),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: code,
                enabled: !store.isSubmitting,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.w700),
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                onSubmitted: (_) => _verify(),
                decoration: InputDecoration(labelText: 'otp_code'.tr, counterText: ''),
              ),
              const SizedBox(height: 12),
              Text('${'otp_expires'.tr} ${_clock(store.ttlSeconds)}'),
              const SizedBox(height: 20),
              AppButton(label: store.status.name == 'success' ? 'verified'.tr : 'verify'.tr, isLoading: store.isSubmitting, onPressed: _verify),
              AppButton(
                label: store.cooldownSeconds > 0 ? '${'resend_otp'.tr} (${store.cooldownSeconds}s)' : 'resend_otp'.tr,
                variant: AppButtonVariant.text,
                onPressed: store.canResend ? store.resend : null,
              ),
            ])),
      );

  String _clock(int seconds) => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}
