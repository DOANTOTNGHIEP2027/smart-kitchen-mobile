import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_colors.dart';
import '../../routing/app_routes.dart';
import '../../stores/session_store.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/states/view_state.dart';
import '../auth/widgets/auth_frame.dart';
import '../auth/domain/auth_validators.dart';
import 'domain/household_models.dart';
import 'domain/invite_code.dart';
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

  /// S8.14: QR vừa quét không phải mã mời Smart Kitchen.
  bool _qrInvalid = false;

  /// Chống quét trùng (§12b): bỏ qua cùng một giá trị trong [_scanDebounce].
  String? _lastRaw;
  DateTime? _lastRawAt;
  static const Duration _scanDebounce = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    manual = args is Map && args['manual'] == true;
    final routeCode = Get.parameters['code'];
    if (routeCode?.isNotEmpty == true) {
      // Deep link `/join/:code` (§12b): mã sai định dạng → S8.6 qua preview,
      // không gọi API.
      manual = true;
      code.text = parseInviteCode(routeCode!) ??
          HouseholdStore.normalizeInviteCode(routeCode);
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
    final now = DateTime.now();
    if (raw == _lastRaw &&
        _lastRawAt != null &&
        now.difference(_lastRawAt!) < _scanDebounce) {
      return;
    }
    _lastRaw = raw;
    _lastRawAt = now;
    final parsed = parseInviteCode(raw);
    if (parsed == null) {
      // S8.14 — không gọi API, scanner tiếp tục chạy.
      setState(() => _qrInvalid = true);
      return;
    }
    _handledBarcode = true;
    code.text = parsed;
    setState(() {
      _qrInvalid = false;
      manual = true;
    });
    store.preview(parsed);
  }

  Future<void> _preview() => store.preview(code.text);

  Future<void> _join() async {
    if (AuthValidators.fullName(displayName.text, required: false) != null) {
      return; // lỗi đã hiện realtime dưới ô tên hiển thị (§18b)
    }
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
          final session = Get.find<SessionStore>();
          final alreadyInHousehold = session.isAuthenticated &&
              session.householdId != null;
          if (alreadyInHousehold ||
              store.error?.code == 'CLIENT_ALREADY_IN_HOUSEHOLD') {
            return Column(children: [
              FeatureBanner(message: 'already_in_household'.localized(context)),
              const SizedBox(height: 16),
              AppButton(
                key: const ValueKey<String>('join-go-home'),
                label: context.l10n.joinGoHome,
                onPressed: () => Get.offAllNamed(AppRoutes.splash),
              ),
            ]);
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
      if (_qrInvalid) ...[
        FeatureBanner(
            key: const ValueKey<String>('join-qr-invalid'),
            message: 'invite_qr_invalid'.localized(context)),
        const SizedBox(height: 12),
      ],
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 300,
          child: Stack(fit: StackFit.expand, children: [
            MobileScanner(onDetect: _detect, errorBuilder: _scannerError),
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

  /// S8.2 khi lỗi do quyền camera, S8.15 cho mọi lỗi khác (sửa review L1
  /// 2026-09-15: trước đây mọi lỗi đều báo "cần quyền camera").
  Widget _scannerError(BuildContext context, MobileScannerException error) {
    final permission =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      key: ValueKey<String>(
          permission ? 'join-camera-permission' : 'join-camera-unavailable'),
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            (permission ? 'camera_permission_denied' : 'camera_unavailable')
                .localized(context),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  String _errorCopy(String code) => code == 'ERR_AUTH_RATE_LIMIT'
      ? 'join_rate_limited'.localized(context)
      : errorCopy(context, code);

  Widget _manualAndPreview() {
    final state = store.previewState;
    return Column(children: [
      AppTextField(
        key: const ValueKey<String>('join-code'),
        label: 'invite_code'.localized(context),
        controller: code,
        enabled: !store.isSubmitting,
        textCapitalization: TextCapitalization.characters,
        hint: context.l10n.inviteCodeExample,
        prefixIcon: Icons.key_outlined,
        onChanged: (value) {
          // Dán cả link mời (§12b) → rút mã; còn lại chuẩn hoá về 8 ký tự.
          final fromLink = value.contains('/') ? parseInviteCode(value) : null;
          var normalized =
              fromLink ?? HouseholdStore.normalizeInviteCode(value);
          if (normalized.length > 8) normalized = normalized.substring(0, 8);
          if (value != normalized) {
            code.value = TextEditingValue(
                text: normalized,
                selection: TextSelection.collapsed(offset: normalized.length));
          }
        },
        onSubmitted: (_) => _preview(),
      ),
      const SizedBox(height: 16),
      if (state is LoadingState<InvitePreview>)
        const CircularProgressIndicator(),
      if (state is ErrorState<InvitePreview>) ...[
        FeatureBanner(
            key: ValueKey<String>('join-preview-error-${state.error.code}'),
            message: _errorCopy(state.error.code)),
        const SizedBox(height: 12),
        AppButton(label: 'preview_invite'.localized(context), onPressed: _preview),
      ],
      if (state is EmptyState<InvitePreview>)
        AppButton(label: 'preview_invite'.localized(context), onPressed: _preview),
      if (state is SuccessState<InvitePreview>) _previewCard(state.data),
      if (store.error != null) ...[
        const SizedBox(height: 12),
        FeatureBanner(
            key: ValueKey<String>('join-error-${store.error!.code}'),
            message: _errorCopy(store.error!.code)),
      ],
      AppButton(
          label: 'scan_again'.localized(context),
          variant: AppButtonVariant.text,
          onPressed: () {
            _handledBarcode = false;
            _lastRaw = null;
            _qrInvalid = false;
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
        AppTextField(
          key: const ValueKey<String>('join-display-name'),
          label: 'display_name_optional'.localized(context),
          controller: displayName,
          enabled: !store.isSubmitting,
          textCapitalization: TextCapitalization.words,
          hint: context.l10n.joinDisplayNameExample,
          prefixIcon: Icons.person_outline,
          validator: (v) =>
              AuthValidators.fullName(v, required: false)?.localized(context),
        ),
      ],
      const SizedBox(height: 20),
      // S8.12: nhà đã đủ người (409 khi confirm) → không cho bấm lại.
      if (store.error?.code != 'ERR_HOUSEHOLD_FULL')
        AppButton(
            label: 'confirm_join'.localized(context),
            isLoading: store.isSubmitting,
            onPressed: _join),
      if (guest)
        AppButton(
          key: const ValueKey<String>('join-have-account'),
          label: 'have_account_login'.localized(context),
          variant: AppButtonVariant.text,
          onPressed: store.isSubmitting
              ? null
              : () => Get.toNamed(AppRoutes.emailLogin),
        ),
    ]);
  }
}
