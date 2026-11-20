import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_colors_extension.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_icons.dart';
import '../../stores/theme_store.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/dialogs/confirm_dialog.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/states/app_empty_view.dart';
import '../../widgets/states/app_error_view.dart';
import '../../widgets/states/app_loading_view.dart';

/// Màn dev liệt kê mọi widget dùng chung và các trạng thái của chúng
/// (design-system.md §8). State ở đây chỉ là ephemeral UI state của màn demo
/// (overlay bật/tắt, nút đang loading) — không phải business state, nên dùng
/// `StatefulWidget` cục bộ thay vì store (D1).
class WidgetShowcaseScene extends StatefulWidget {
  const WidgetShowcaseScene({super.key});

  static const Duration demoDelay = Duration(seconds: 2);

  @override
  State<WidgetShowcaseScene> createState() => _WidgetShowcaseSceneState();
}

class _WidgetShowcaseSceneState extends State<WidgetShowcaseScene> {
  bool _demoLoading = false;
  bool _overlayVisible = false;
  final List<Timer> _timers = <Timer>[];

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  void _runFor2s(void Function(bool value) setFlag) {
    setState(() => setFlag(true));
    _timers.add(Timer(WidgetShowcaseScene.demoDelay, () {
      if (mounted) setState(() => setFlag(false));
    }));
  }

  Future<void> _openDialog({required bool destructive}) async {
    final l10n = context.l10n;
    final result = await showConfirmDialog(
      context,
      title: l10n.showcaseDialogTitle,
      message: l10n.showcaseDialogMessage,
      isDestructive: destructive,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(context.l10n.showcaseDialogResult(
            result ? context.l10n.commonConfirm : context.l10n.cancel)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeStore = Get.find<ThemeStore>();
    return AppScaffold(
      title: l10n.showcaseTitle,
      actions: <Widget>[
        Observer(
          builder: (_) => IconButton(
            key: const ValueKey<String>('showcase-toggle-theme'),
            tooltip: l10n.showcaseToggleTheme,
            icon: Icon(themeStore.themeMode == ThemeMode.dark
                ? AppIcons.lightMode
                : AppIcons.darkMode),
            onPressed: themeStore.toggle,
          ),
        ),
      ],
      body: ListView(
        key: const ValueKey<String>('showcase-list'),
        padding: const EdgeInsets.all(AppDimens.md),
        children: <Widget>[
          _Section(
            id: 'colors',
            title: l10n.showcaseSectionColors,
            child: const _ColorSwatches(),
          ),
          _Section(
            id: 'typography',
            title: l10n.showcaseSectionTypography,
            child: const _TypographySamples(),
          ),
          _Section(
            id: 'buttons',
            title: l10n.showcaseSectionButtons,
            child: _ButtonMatrix(
              demoLoading: _demoLoading,
              onDemoTap: () => _runFor2s((v) => _demoLoading = v),
            ),
          ),
          _Section(
            id: 'cards',
            title: l10n.showcaseSectionCards,
            child: Column(
              children: <Widget>[
                AppCard(child: Text(l10n.showcaseCardNormal)),
                const SizedBox(height: AppDimens.sm),
                AppCard(
                  highlighted: true,
                  child: Text(l10n.showcaseHighlighted),
                ),
                const SizedBox(height: AppDimens.sm),
                AppCard(
                  onTap: () {},
                  child: Text(l10n.showcaseCardTappable),
                ),
                const SizedBox(height: AppDimens.sm),
                AppCard(elevation: 1, child: Text(l10n.showcaseCardElevated)),
              ],
            ),
          ),
          _Section(
            id: 'inputs',
            title: l10n.showcaseSectionInputs,
            child: const _InputSamples(),
          ),
          _Section(
            id: 'states',
            title: l10n.showcaseSectionStates,
            child: Column(
              children: <Widget>[
                const _StateBox(child: AppLoadingView()),
                const _StateBox(child: AppEmptyView()),
                _StateBox(
                  child: AppEmptyView(
                    action: AppButton(
                      label: l10n.showcaseEmptyAction,
                      icon: AppIcons.add,
                      variant: AppButtonVariant.secondary,
                      expanded: false,
                      onPressed: () {},
                    ),
                  ),
                ),
                _StateBox(child: AppErrorView(onRetry: () {})),
              ],
            ),
          ),
          _Section(
            id: 'overlay',
            title: l10n.showcaseSectionOverlay,
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 160,
                  child: LoadingOverlay(
                    isLoading: _overlayVisible,
                    message: l10n.commonLoading,
                    child: AppCard(
                      child: SizedBox.expand(
                        child: Text(l10n.showcaseSampleText),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                AppButton(
                  key: const ValueKey<String>('showcase-show-overlay'),
                  label: l10n.showcaseShowOverlay,
                  variant: AppButtonVariant.outline,
                  onPressed: _overlayVisible
                      ? null
                      : () => _runFor2s((v) => _overlayVisible = v),
                ),
              ],
            ),
          ),
          _Section(
            id: 'dialog',
            title: l10n.showcaseSectionDialog,
            child: Column(
              children: <Widget>[
                AppButton(
                  key: const ValueKey<String>('showcase-open-dialog'),
                  label: l10n.showcaseOpenDialog,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _openDialog(destructive: false),
                ),
                const SizedBox(height: AppDimens.sm),
                AppButton(
                  key: const ValueKey<String>(
                      'showcase-open-destructive-dialog'),
                  label: l10n.showcaseOpenDestructiveDialog,
                  variant: AppButtonVariant.destructive,
                  onPressed: () => _openDialog(destructive: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.id, required this.title, required this.child});

  final String id;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        key: ValueKey<String>('showcase-$id'),
        padding: const EdgeInsets.only(bottom: AppDimens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppDimens.sm),
            child,
          ],
        ),
      );
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final swatches = <Color>[
      scheme.primary,
      scheme.primaryContainer,
      scheme.surface,
      colors.border,
      scheme.error,
      colors.success,
      colors.warning,
      colors.info,
    ];
    return Wrap(
      spacing: AppDimens.sm,
      runSpacing: AppDimens.sm,
      children: <Widget>[
        for (final color in swatches)
          Container(
            width: 56,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(color: colors.border),
            ),
          ),
      ],
    );
  }
}

class _TypographySamples extends StatelessWidget {
  const _TypographySamples();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sample = context.l10n.showcaseSampleText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final style in <TextStyle?>[
          text.titleLarge,
          text.titleMedium,
          text.bodyLarge,
          text.bodyMedium,
          text.labelSmall,
        ])
          Text(sample, style: style),
      ],
    );
  }
}

class _ButtonMatrix extends StatelessWidget {
  const _ButtonMatrix({required this.demoLoading, required this.onDemoTap});

  final bool demoLoading;
  final VoidCallback onDemoTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final variants = <AppButtonVariant, String>{
      AppButtonVariant.primary: l10n.showcaseVariantPrimary,
      AppButtonVariant.secondary: l10n.showcaseVariantSecondary,
      AppButtonVariant.outline: l10n.showcaseVariantOutline,
      AppButtonVariant.google: l10n.showcaseVariantGoogle,
      AppButtonVariant.text: l10n.showcaseVariantText,
      AppButtonVariant.destructive: l10n.showcaseVariantDestructive,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final entry in variants.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.sm),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: entry.value,
                    variant: entry.key,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: AppDimens.xs),
                Expanded(
                  child: AppButton(
                    label: l10n.showcaseStateLoading,
                    variant: entry.key,
                    isLoading: true,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: AppDimens.xs),
                Expanded(
                  child: AppButton(
                    label: l10n.showcaseStateDisabled,
                    variant: entry.key,
                    onPressed: null,
                  ),
                ),
              ],
            ),
          ),
        AppButton(
          key: const ValueKey<String>('showcase-demo-loading'),
          label: l10n.showcaseTapToLoad,
          isLoading: demoLoading,
          onPressed: onDemoTap,
        ),
      ],
    );
  }
}

class _InputSamples extends StatefulWidget {
  const _InputSamples();

  @override
  State<_InputSamples> createState() => _InputSamplesState();
}

class _InputSamplesState extends State<_InputSamples> {
  final TextEditingController _required = TextEditingController();

  @override
  void dispose() {
    _required.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const gap = SizedBox(height: AppDimens.md);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
            label: l10n.showcaseSampleLabel, hint: l10n.showcaseSampleText),
        gap,
        AppTextField(
          key: const ValueKey<String>('showcase-field-required'),
          label: l10n.showcaseFieldRequired,
          controller: _required,
          validator: (value) => (value == null || value.trim().isEmpty)
              ? l10n.commonRequiredField
              : null,
        ),
        gap,
        AppTextField(
          label: l10n.showcaseFieldServerError,
          errorText: l10n.showcaseFieldServerErrorText,
        ),
        gap,
        AppTextField(label: l10n.showcaseFieldPassword, obscureText: true),
        gap,
        AppTextField(label: l10n.showcaseFieldDisabled, enabled: false),
      ],
    );
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.sm),
        child: SizedBox(
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: context.appColors.border),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: child,
          ),
        ),
      );
}
