import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../data/network/api_exception.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/states/app_loading_view.dart';
import '../stores/cooking_session_store.dart';
import '../widgets/ingredient_deduction_list.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/step_timer_view.dart';

/// Màn hình chính cooking (FE-6 §1, §7): dẫn dắt từng bước của recipe.
///
/// Hành vi bắt buộc (Implementation Guards §9):
/// - WakeLock bật khi `phase` chuyển sang `active`, tắt NGAY khi `phase` chuyển
///   `completed`/`abandoned` (KHÔNG chờ dispose — D5).
/// - `PopScope` chặn back cứng ở `phase=active` HOẶC `loading` (Guard §9.6) —
///   mở dialog Huỷ Bỏ, người dùng xác nhận mới pop.
/// - `Timer` sống trong Store (không phải State) — đã đảm bảo ở store.
class CookingSessionScene extends StatefulWidget {
  const CookingSessionScene({super.key});

  @override
  State<CookingSessionScene> createState() => _CookingSessionSceneState();
}

class _CookingSessionSceneState extends State<CookingSessionScene>
    with WidgetsBindingObserver {
  late final CookingSessionStore _store;
  ReactionDisposer? _wakelockReaction;
  ReactionDisposer? _actionErrorReaction;

  /// Snackbar của lỗi thao tác đang hiện/xếp hàng (OD-27).
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _errorSnack;
  ApiException? _errorSnackError;
  bool _errorSnackVisible = false;

  @override
  void initState() {
    super.initState();
    _store = Get.find<CookingSessionStore>();
    WidgetsBinding.instance.addObserver(this);

    // Bật WakeLock ngay khi vào màn hình — mục đích của cả màn hình là screen-on
    WakelockPlus.enable();

    // Decision D5 — tắt phản ứng theo `phase`, KHÔNG chờ dispose().
    _wakelockReaction = reaction<CookingScreenPhase>(
      (_) => _store.phase,
      (phase) {
        if (phase == CookingScreenPhase.completed ||
            phase == CookingScreenPhase.abandoned) {
          WakelockPlus.disable();
        }
      },
    );

    // Snackbar lỗi thao tác: reaction chỉ chạy khi lỗi ĐỔI — không phụ thuộc
    // Observer build lại mỗi giây vì timer (OD-27).
    _actionErrorReaction = reaction<ApiException?>(
      (_) => _store.actionError,
      _onActionErrorChanged,
    );

    _store.init();
  }

  void _onActionErrorChanged(ApiException? error) {
    // Snackbar có "Thử lại" persist — lỗi đã bị xoá/thay thì tự đóng.
    if (_errorSnack != null && !identical(_errorSnackError, error)) {
      _closeStaleErrorSnack();
    }
    if (error == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    _errorSnackError = error;
    _errorSnackVisible = false;
    late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snack;
    snack = messenger.showSnackBar(
      SnackBar(
        content: Text(apiErrorMessage(l10n, error)),
        // Đang xếp hàng sau snackbar khác thì chỉ đóng được khi tới lượt.
        onVisible: () {
          if (identical(_errorSnack, snack)) _errorSnackVisible = true;
          // Lỗi đã cũ trong lúc chờ → tự đóng CHÍNH nó.
          if (!identical(_store.actionError, error)) snack.close();
        },
        action: _store.canRetryAction
            ? SnackBarAction(
                label: l10n.cookingRetry,
                // User bấm mới chạy, KHÔNG tự retry.
                onPressed: () {
                  if (identical(_store.actionError, error)) {
                    _store.retryLastAction();
                  }
                },
              )
            : null,
      ),
    );
    _errorSnack = snack;
    snack.closed.then((reason) {
      if (identical(_errorSnack, snack)) {
        _errorSnack = null;
        _errorSnackError = null;
      }
      if (!identical(_store.actionError, error)) return;
      if (reason == SnackBarClosedReason.hide ||
          reason == SnackBarClosedReason.remove) {
        // Bị snackbar khác (vd. thông báo toàn cục) đẩy ra trong khi lỗi vẫn
        // còn → xếp hiện lại, không xoá mất đường "Thử lại".
        if (mounted) _onActionErrorChanged(error);
        return;
      }
      // Tự ẩn/bị vuốt → lỗi không còn UI nào hiện, dọn khỏi store.
      _store.clearActionError();
    });
  }

  /// `close()` chỉ hợp lệ khi snackbar đang là cái hiện tại — chưa tới lượt
  /// thì `onVisible` của nó sẽ tự đóng.
  void _closeStaleErrorSnack() {
    final snack = _errorSnack;
    final visible = _errorSnackVisible;
    _errorSnack = null;
    _errorSnackError = null;
    _errorSnackVisible = false;
    if (snack != null && visible) snack.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Tái khẳng định WakeLock khi app foreground trong lúc đang nấu —
    // Implementation Guard §9.5.
    if (state == AppLifecycleState.resumed &&
        _store.phase == CookingScreenPhase.active) {
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    _wakelockReaction?.call();
    // Rời màn hình → lỗi không còn UI: reaction tự đóng snackbar "Thử lại"
    // (persist) để nó không treo sang màn khác và gọi store đã dispose.
    _store.clearActionError();
    _actionErrorReaction?.call();
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable(); // idempotent-safe dù reaction đã tắt trước đó
    _store.dispose();
    super.dispose();
  }

  Future<void> _showAbandonConfirmDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.cookingAbandonTitle),
        content: Text(context.l10n.cookingAbandonMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.l10n.cookingContinue),
          ),
          Observer(
            builder: (_) => AppButton(
              label: context.l10n.cookingAbandonAction,
              variant: AppButtonVariant.text,
              isLoading: _store.isAbandoning,
              expanded: false,
              onPressed: _store.isAbandoning
                  ? null
                  : () async {
                      await _store.abandon();
                      if (_store.phase == CookingScreenPhase.abandoned) {
                        Get.back(); // đóng dialog
                        Get.back(); // rời màn hình cooking
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Chặn pop khi đang active HOẶC loading (Guard §9.6 — ở loading,
      // start() có thể đã tạo session ở server, pop tự do để lại session mồ côi).
      canPop: _store.phase != CookingScreenPhase.active &&
          _store.phase != CookingScreenPhase.loading,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showAbandonConfirmDialog();
      },
      child: Observer(
        builder: (_) => _buildBody(context, _store),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CookingSessionStore store) {
    switch (store.phase) {
      case CookingScreenPhase.loading:
        return const AppScaffold(body: AppLoadingView());
      case CookingScreenPhase.error:
        return AppScaffold(
          body: _ErrorPhaseView(
            message: apiErrorMessage(context.l10n, store.loadError,
                fallback: context.l10n.cookingLoadFailed),
            retryable: store.loadErrorIsRetryable,
            onRetry: store.retryLoad,
          ),
        );
      case CookingScreenPhase.active:
        return _ActiveStepView(
          store: store,
          onAbandon: _showAbandonConfirmDialog,
        );
      case CookingScreenPhase.completed:
        return _CompletedResultView(store: store);
      case CookingScreenPhase.abandoned:
        return const _AbandonedView();
    }
  }
}

/// Phase `error` — phán theo `loadErrorIsRetryable` để quyết định nút
/// "Thử lại" (gọi `retryLoad`) hay "Quay lại" (điều hướng ra ngoài).
/// MEDIUM-1 (review): không dùng `AppErrorView` vì nút cố định "Thử lại".
class _ErrorPhaseView extends StatelessWidget {
  const _ErrorPhaseView({
    required this.message,
    required this.retryable,
    required this.onRetry,
  });

  final String message;
  final bool retryable;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline,
                size: AppDimens.stateIcon, color: AppColors.error),
            const SizedBox(height: AppDimens.md),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppDimens.lg),
            AppButton(
              label: retryable
                  ? context.l10n.cookingRetry
                  : context.l10n.cookingBack,
              variant: AppButtonVariant.secondary,
              expanded: false,
              onPressed: retryable ? onRetry : () => Get.back<void>(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Phase `active` — top bar + progress + nội dung bước + timer + nút hành động.
class _ActiveStepView extends StatelessWidget {
  const _ActiveStepView({required this.store, required this.onAbandon});

  final CookingSessionStore store;
  final Future<void> Function() onAbandon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: store.session?.recipeName,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: context.l10n.cookingAbandonTooltip,
          onPressed: onAbandon,
        ),
      ],
      body: Observer(
        builder: (_) {
          final busy =
              store.isAdvancing || store.isCompleting || store.isResyncing;
          return Column(
            children: <Widget>[
              const SizedBox(height: AppDimens.md),
              StepProgressBar(
                viewedStep: store.viewedStep,
                currentStep: store.session?.currentStep ?? 1,
                totalSteps: store.session?.totalSteps ?? 1,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      StepTimerView(
                        remainingSeconds: store.remainingSeconds,
                        durationSeconds: store.viewedStepDef?.durationSeconds,
                        isViewingCurrentStep: store.isViewingCurrentStep,
                        timerRunning: store.timerRunning,
                        onToggle: store.toggleTimer,
                        onReset: store.resetTimer,
                      ),
                      const SizedBox(height: AppDimens.md),
                      AppCard(
                        padding: const EdgeInsets.all(AppDimens.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              context.l10n.cookingStepLabel(store.viewedStep),
                              style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppColors.sage,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppDimens.sm),
                            Text(
                              store.viewedStepDef?.instruction ??
                                  context
                                      .l10n.cookingStepUnavailable, // Guard #7
                              style: theme.textTheme.titleMedium?.copyWith(
                                  height: 1.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.lg),
                      if (!store.isViewingCurrentStep)
                        AppButton(
                          label: context.l10n.cookingReturnToCurrentStep,
                          icon: Icons.fast_forward,
                          onPressed: store.returnToCurrentStep,
                        ),
                    ],
                  ),
                ),
              ),
              // Nút dưới cùng — label/hành vi đổi theo isViewingCurrentStep + isLastStep.
              Padding(
                padding: const EdgeInsets.all(AppDimens.md),
                child: Row(
                  children: <Widget>[
                    if (store.isViewingCurrentStep)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: context.l10n.cookingPreviousStep,
                        onPressed: store.viewedStep <= 1
                            ? null
                            : store.viewPreviousStep,
                      ),
                    const SizedBox(width: AppDimens.sm),
                    Expanded(
                      child: AppButton(
                        label: store.session?.isLastStep == true
                            ? context.l10n.cookingComplete
                            : context.l10n.cookingNextStep,
                        isLoading: busy,
                        icon: store.session?.isLastStep == true
                            ? Icons.check_circle_outline
                            : Icons.arrow_forward,
                        onPressed: busy ? null : store.advanceOrComplete,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Phase `completed` — hiển thị danh sách ingredient_deductions + nút "Xong".
class _CompletedResultView extends StatelessWidget {
  const _CompletedResultView({required this.store});

  final CookingSessionStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAnyShortfall = store.deductions.any((d) => d.hasShortfall);
    return AppScaffold(
      title: store.session?.recipeName,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: AppDimens.stateIcon + AppDimens.md,
                height: AppDimens.stateIcon + AppDimens.md,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (hasAnyShortfall ? AppColors.warning : AppColors.success)
                          .withValues(alpha: 0.13),
                ),
                child: Icon(
                  hasAnyShortfall
                      ? Icons.warning_amber_rounded
                      : Icons.check_rounded,
                  size: AppDimens.stateIcon,
                  color:
                      hasAnyShortfall ? AppColors.warning : AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.md),
            Text(
              hasAnyShortfall
                  ? context.l10n.cookingCompletedWithShortfall
                  : context.l10n.cookingCompleted,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            if (hasAnyShortfall)
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.sm),
                child: Text(
                  context.l10n.cookingCompletedShortfallDetail,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: AppDimens.lg),
            Text(context.l10n.cookingDeductionResult,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppDimens.sm),
            IngredientDeductionList(deductions: store.deductions),
            const SizedBox(height: AppDimens.lg),
            AppButton(
              label: context.l10n.cookingDone,
              icon: Icons.home,
              onPressed: () {
                // Đích cụ thể là câu hỏi mở Q3 của file thiết kế — hiện tại
                // Get.back về màn hình gọi tới.
                Get.back<void>();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Phase `abandoned` — session đã đóng, không đụng kho.
class _AbandonedView extends StatelessWidget {
  const _AbandonedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.logout,
                size: AppDimens.stateIcon, color: AppColors.textSecondary),
            const SizedBox(height: AppDimens.md),
            Text(context.l10n.cookingAbandoned,
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppDimens.sm),
            Text(
              context.l10n.cookingAbandonedDetail,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimens.lg),
            AppButton(
              label: context.l10n.cookingHome,
              icon: Icons.home,
              expanded: false,
              onPressed: () => Get.back<void>(),
            ),
          ],
        ),
      ),
    );
  }
}
