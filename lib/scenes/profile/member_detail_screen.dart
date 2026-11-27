import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feature_banner.dart';
import '../../widgets/states/app_state_view.dart';
import '../../widgets/states/state_view_layout.dart';
import '../../widgets/states/view_state.dart';
import 'family_error_l10n.dart';
import 'domain/member_health_summary.dart';
import 'stores/family_store.dart';
import 'widgets/allergen_label.dart';
import 'widgets/diet_type_label.dart';

class MemberDetailScreen extends StatefulWidget {
  /// [userId] chỉ để test/nhúng trực tiếp; route thật đọc `:userId` từ path
  /// (fallback `arguments['userId']`).
  const MemberDetailScreen({super.key, this.userId});

  final String? userId;

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  late final FamilyStore store = Get.find<FamilyStore>();
  late final String userId = _resolveUserId();
  late final String fullName = (Get.arguments is Map
          ? (Get.arguments as Map)['fullName']
          : null) as String? ??
      '';

  String _resolveUserId() {
    final fromWidget = widget.userId;
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    final fromPath = Get.parameters['userId'];
    if (fromPath != null && fromPath.isNotEmpty) return fromPath;
    final args = Get.arguments;
    final fromArgs = args is Map ? args['userId'] : null;
    return fromArgs is String ? fromArgs : '';
  }

  @override
  void initState() {
    super.initState();
    // Thiếu userId → báo lỗi tại chỗ, KHÔNG gọi API với path rỗng.
    if (userId.isNotEmpty) store.loadMemberSummary(userId);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: fullName.isEmpty ? context.l10n.memberDetailTitle : fullName,
      body: Observer(builder: (_) {
        if (userId.isEmpty) {
          return _NoRetryError(message: context.l10n.memberDetailNotFound);
        }
        final state = store.memberSummaryState;
        // S12.12: lỗi quyền — "Thử lại" vô nghĩa, chỉ có "Đóng".
        if (state is ErrorState<MemberHealthSummary> &&
            state.error.code == 'ERR_HEALTH_FORBIDDEN') {
          return _NoRetryError(
              message: familyErrorMessage(context.l10n, state.error));
        }
        // Đọc ở đây để Observer theo dõi — successBuilder chạy ngoài phạm vi.
        final isViewer = store.isMemberRemoteViewer(userId);
        return AppStateView<MemberHealthSummary>(
          state: state,
          onRetry: () => store.loadMemberSummary(userId),
          successBuilder: (_, MemberHealthSummary s) {
            return ListView(
              padding: const EdgeInsets.all(AppDimens.md),
              children: <Widget>[
                _Row(
                  label: context.l10n.memberDetailDietType,
                  value: s.dietType == null
                      ? context.l10n.healthProfileDietUnset
                      : s.dietType!.label(context.l10n),
                ),
                const SizedBox(height: AppDimens.md),
                Text(context.l10n.memberDetailAllergensSection,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppDimens.sm),
                if (s.allergens.isEmpty)
                  Text(context.l10n.memberDetailAllergensEmpty)
                else
                  Wrap(
                    spacing: AppDimens.sm,
                    runSpacing: AppDimens.xs,
                    children: <Widget>[
                      for (final a in s.allergens)
                        Chip(label: Text(a.label(context.l10n))),
                    ],
                  ),
                if (isViewer) ...<Widget>[
                  const SizedBox(height: AppDimens.md),
                  FeatureBanner(
                    key: const ValueKey<String>('member-viewer-info'),
                    message: context.l10n.tierMemberViewerInfo,
                    isError: false,
                  ),
                ],
                const SizedBox(height: AppDimens.lg),
                Text(
                  context.l10n.memberDetailPrivacyNote,
                  key: const ValueKey<String>('member-privacy-note'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}

/// Lỗi KHÔNG có "Thử lại" (S12.12 / thiếu userId): retry vô nghĩa, chỉ "Đóng".
class _NoRetryError extends StatelessWidget {
  const _NoRetryError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return StateViewLayout(
      children: <Widget>[
        Icon(
          Icons.lock_outline,
          size: AppDimens.stateIcon,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: AppDimens.md),
        Text(
          message,
          key: const ValueKey<String>('member-detail-error'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppDimens.lg),
        AppButton(
          key: const ValueKey<String>('member-detail-close'),
          label: context.l10n.memberDetailClose,
          variant: AppButtonVariant.secondary,
          expanded: false,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
