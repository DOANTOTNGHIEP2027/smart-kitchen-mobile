import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_colors.dart';
import '../../routing/app_routes.dart';
import '../../stores/session_store.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/states/view_state.dart';
import '../auth/widgets/auth_frame.dart';
import 'domain/household_models.dart';
import 'stores/household_store.dart';

class JoinHouseholdScene extends StatefulWidget {
  const JoinHouseholdScene({super.key});

  @override
  State<JoinHouseholdScene> createState() => _JoinHouseholdSceneState();
}

class _JoinHouseholdSceneState extends State<JoinHouseholdScene> {
  late final HouseholdStore store = Get.find<HouseholdStore>();
  final code = TextEditingController();
  final displayName = TextEditingController();
  bool manual = false;
  bool permissionDenied = false;
  bool _handledBarcode = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    manual = args is Map && args['manual'] == true;
    final routeCode = Get.parameters['code'];
    if (routeCode?.isNotEmpty == true) {
      manual = true;
      code.text = routeCode!;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => store.preview(routeCode));
    } else if (!manual) {
      _requestCamera();
    }
  }

  Future<void> _requestCamera() async {
    if (kIsWeb) return;
    final status = await Permission.camera.request();
    if (mounted) setState(() => permissionDenied = !status.isGranted);
  }

  void _detect(BarcodeCapture capture) {
    if (_handledBarcode) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final parsed = raw.split('/').last;
    _handledBarcode = true;
    code.text = parsed;
    setState(() => manual = true);
    store.preview(parsed);
  }

  Future<void> _preview() => store.preview(code.text);

  Future<void> _join() async {
    if (await store.join(displayName: displayName.text)) {
      Get.offAllNamed(AppRoutes.shellRoot);
    }
  }

  @override
  void dispose() {
    code.dispose();
    displayName.dispose();
    store.resetMutation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
        title: 'join_household'.localized(context),
        subtitle: 'join_household_subtitle'.localized(context),
        child: Observer(builder: (_) {
          if (store.error?.code == 'CLIENT_ALREADY_IN_HOUSEHOLD') {
            return FeatureBanner(message: 'already_in_household'.localized(context));
          }
          return Column(children: [
            if (!manual) _scanner(),
            if (manual) _manualAndPreview(),
          ]);
        }),
      );

  Widget _scanner() {
    if (permissionDenied) {
      return Column(children: [
        FeatureBanner(message: 'camera_permission_denied'.localized(context)),
        const SizedBox(height: 16),
        AppButton(label: 'open_settings'.localized(context), onPressed: openAppSettings),
        AppButton(
            label: 'enter_code_manually'.localized(context),
            variant: AppButtonVariant.text,
            onPressed: () => setState(() => manual = true)),
      ]);
    }
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 300,
          child: Stack(fit: StackFit.expand, children: [
            MobileScanner(
                onDetect: _detect,
                errorBuilder: (_, __) => ColoredBox(
                    color: Colors.black87,
                    child: Center(
                        child: Text('camera_unavailable'.localized(context),
                            style: const TextStyle(color: Colors.white))))),
            Center(
                child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 3),
                        borderRadius: BorderRadius.circular(20)))),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      AppButton(
          label: 'enter_code_manually'.localized(context),
          variant: AppButtonVariant.text,
          onPressed: () => setState(() => manual = true)),
    ]);
  }

  Widget _manualAndPreview() {
    final state = store.previewState;
    return Column(children: [
      TextField(
        controller: code,
        enabled: !store.isSubmitting,
        textCapitalization: TextCapitalization.characters,
        maxLength: 8,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
          LengthLimitingTextInputFormatter(8)
        ],
        onChanged: (value) {
          final normalized = HouseholdStore.normalizeInviteCode(value);
          if (value != normalized) {
            code.value = TextEditingValue(
                text: normalized,
                selection: TextSelection.collapsed(offset: normalized.length));
          }
        },
        onSubmitted: (_) => _preview(),
        decoration:
            InputDecoration(
              labelText: 'invite_code'.localized(context),
              hintText: context.l10n.inviteCodeExample,
              prefixIcon: const Icon(Icons.key_outlined),
              counterText: '',
            ),
      ),
      const SizedBox(height: 16),
      if (state is LoadingState<InvitePreview>)
        const CircularProgressIndicator(),
      if (state is ErrorState<InvitePreview>) ...[
        FeatureBanner(message: errorCopy(context, state.error.code)),
        const SizedBox(height: 12),
        AppButton(label: 'preview_invite'.localized(context), onPressed: _preview),
      ],
      if (state is EmptyState<InvitePreview>)
        AppButton(label: 'preview_invite'.localized(context), onPressed: _preview),
      if (state is SuccessState<InvitePreview>) _previewCard(state.data),
      if (store.error != null) ...[
        const SizedBox(height: 12),
        FeatureBanner(message: errorCopy(context, store.error!.code)),
      ],
      AppButton(
          label: 'scan_again'.localized(context),
          variant: AppButtonVariant.text,
          onPressed: () {
            _handledBarcode = false;
            store.resetMutation();
            setState(() => manual = false);
            _requestCamera();
          }),
    ]);
  }

  Widget _previewCard(InvitePreview preview) {
    final guest = Get.find<SessionStore>().status != AuthStatus.authenticated;
    return Column(children: [
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.home_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(preview.householdName,
                style: Theme.of(context).textTheme.titleLarge),
          ),
        ]),
        const SizedBox(height: 12),
        Text('${'household_owner'.localized(context)}: ${preview.ownerName}'),
        const SizedBox(height: 4),
        Text('${'member_count'.localized(context)}: ${preview.memberCount}'),
        const SizedBox(height: 4),
        Text(
            '${'invite_expires'.localized(context)}: ${MaterialLocalizations.of(context).formatMediumDate(preview.expiresAt.toLocal())}'),
      ])),
      if (guest) ...[
        const SizedBox(height: 12),
        TextField(
            controller: displayName,
            enabled: !store.isSubmitting,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'display_name_optional'.localized(context),
              hintText: context.l10n.joinDisplayNameExample,
              prefixIcon: const Icon(Icons.person_outline),
            )),
      ],
      const SizedBox(height: 20),
      AppButton(
          label: 'confirm_join'.localized(context),
          isLoading: store.isSubmitting,
          onPressed: _join),
    ]);
  }
}
