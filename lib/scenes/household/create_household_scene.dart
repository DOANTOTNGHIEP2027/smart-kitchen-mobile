import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../routing/app_routes.dart';
import '../../stores/session_store.dart';
import '../../widgets/buttons/app_button.dart';
import '../auth/widgets/auth_frame.dart';
import 'stores/household_store.dart';

class CreateHouseholdScene extends StatefulWidget {
  const CreateHouseholdScene({super.key});

  @override
  State<CreateHouseholdScene> createState() => _CreateHouseholdSceneState();
}

class _CreateHouseholdSceneState extends State<CreateHouseholdScene> {
  late final HouseholdStore store = Get.find<HouseholdStore>();
  final name = TextEditingController();
  String? localError;

  @override
  void dispose() {
    name.dispose();
    store.resetMutation();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = name.text.trim();
    setState(() => localError = value.isEmpty
        ? 'household_name_required'.tr
        : value.length > 255
            ? 'household_name_too_long'.tr
            : null);
    if (localError != null) return;
    if (!await store.create(value) && store.error?.code == 'ERR_HH_003') {
      final session = Get.find<SessionStore>();
      Get.offAllNamed(session.householdId == null
          ? AppRoutes.householdSetup
          : AppRoutes.shellRoot);
    }
  }

  @override
  Widget build(BuildContext context) => Observer(builder: (_) {
        final household = store.created;
        if (household != null) {
          return AuthFrame(
            title: 'household_created'.tr,
            subtitle: household.name,
            child: Column(children: [
              Semantics(
                  label: 'invite_qr_semantics'.tr,
                  child: QrImageView(
                      data:
                          'https://app.smartkitchen.vn/join/${household.inviteCode}',
                      size: 220)),
              const SizedBox(height: 12),
              SelectableText(household.inviteCode,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3)),
              const SizedBox(height: 20),
              AppButton(
                  label: 'invite_members'.tr,
                  onPressed: () => Get.offAllNamed(AppRoutes.shellRoot,
                      arguments: const {'profileTab': true})),
              AppButton(
                  label: 'later'.tr,
                  variant: AppButtonVariant.text,
                  onPressed: () => Get.offAllNamed(AppRoutes.shellRoot)),
            ]),
          );
        }
        return AuthFrame(
          title: 'create_household'.tr,
          subtitle: 'create_household_subtitle'.tr,
          child: Column(children: [
            if (store.error != null) ...[
              FeatureBanner(message: errorCopy(store.error!.code)),
              const SizedBox(height: 16),
            ],
            TextField(
                controller: name,
                enabled: !store.isSubmitting,
                maxLength: 255,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                    labelText: 'household_name'.tr, errorText: localError)),
            const SizedBox(height: 20),
            AppButton(
                label: 'create_household'.tr,
                isLoading: store.isSubmitting,
                onPressed: _submit),
          ]),
        );
      });
}
