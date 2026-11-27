import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../data/network/api_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/states/app_error_view.dart';
import '../../widgets/states/app_loading_view.dart';
import '../../widgets/states/view_state.dart';
import 'dependent_detail_screen.dart';
import 'dependent_error_l10n.dart';
import 'dependent_list_screen.dart';
import 'domain/calorie_target.dart';
import 'domain/dependent_health_profile.dart';
import 'domain/dependent_summary.dart';
import 'domain/diet_type.dart';
import 'domain/health_measurement.dart';
import 'stores/dependent_store.dart';
import 'stores/form_status.dart';
import 'widgets/calorie_target_field.dart';
import 'widgets/dependent_row.dart';
import 'widgets/dependent_state_views.dart';
import 'widgets/diet_type_label.dart';
import 'widgets/diet_type_selector.dart';

/// Hồ sơ sức khoẻ của một dependent (§9.5, §16.10, §16.12) — tinh thần
/// `HealthProfileScreen` (S10.x) nhưng bind `DependentStore`.
///
/// Cold deep-link: detail chưa Success cho đúng id → `loadDependentDetail`
/// trước; guard `canEditHealthOf` CHỈ đánh giá khi detail đã Success (S-D8).
class DependentHealthProfileScreen extends StatefulWidget {
  const DependentHealthProfileScreen({super.key, this.dependentId});

  final String? dependentId;

  @override
  State<DependentHealthProfileScreen> createState() =>
      _DependentHealthProfileScreenState();
}

class _DependentHealthProfileScreenState
    extends State<DependentHealthProfileScreen> {
  late final DependentStore store = Get.find<DependentStore>();
  late final String id = resolveDependentId(widget.dependentId);
  final _formKey = GlobalKey<FormState>();
  final heightCtl = TextEditingController();
  final weightCtl = TextEditingController();

  bool _isEditing = false;
  DietType? _diet;
  // State cục bộ của CalorieTargetField (Guard 14 của #29).
  int? _storedCalories;
  bool _caloriesTouched = false;
  bool _caloriesNotSet = false;
  int _sliderValue = CalorieTarget.defaultWhenEnabled;

  @override
  void initState() {
    super.initState();
    if (id.isEmpty) return; // not-found, KHÔNG gọi API với path rỗng
    final d = store.detailFor(id);
    if (d == null) {
      // loadDependentDetail tự gọi loadHealthProfile khi có quyền.
      store.loadDependentDetail(id);
    } else if (store.canEditHealthOf(d)) {
      // L3: không GET trùng khi health của detail đang bay.
      store.ensureHealthLoaded(id);
    }
  }

  @override
  void dispose() {
    heightCtl.dispose();
    weightCtl.dispose();
    store.clearHealthSaveStatus();
    super.dispose();
  }

  /// Seed form từ dữ liệu SERVER (không từ rỗng) — chỉ khi `canSaveHealthFor`.
  void _startEditing(DependentHealthProfile p) {
    if (!store.canSaveHealthFor(id)) return;
    store.clearHealthSaveStatus();
    setState(() {
      _isEditing = true;
      _diet = p.dietType;
      heightCtl.text = formatHealthNumber(p.heightCm);
      weightCtl.text = formatHealthNumber(p.weightKg);
      _storedCalories = p.targetDailyCalories;
      _caloriesTouched = false;
      _caloriesNotSet = p.targetDailyCalories == null;
      _sliderValue = CalorieTarget.thumbFor(p.targetDailyCalories);
    });
  }

  void _cancelEditing() {
    store.clearHealthSaveStatus();
    setState(() => _isEditing = false);
  }

  void _onFieldEdited() {
    if (store.healthSaveStatus == FormStatus.failure) {
      store.clearHealthSaveStatus();
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    final ok = await store.saveHealthProfile(
      id,
      targetDailyCalories: CalorieTarget.resolveForSave(
        stored: _storedCalories,
        touched: _caloriesTouched,
        notSet: _caloriesNotSet,
        sliderValue: _sliderValue,
      ),
      dietTypeWire: _diet == null ? null : dietTypeToWire(_diet!),
      heightCm: HealthMeasurement.parse(heightCtl.text),
      weightKg: HealthMeasurement.parse(weightCtl.text),
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (ok) {
      setState(() => _isEditing = false);
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.healthSavedToast)));
      return;
    }
    if (store.healthSaveError?.code == 'ERR_DEP_001') {
      backToDependentList();
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.dependentNotFoundTitle)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Observer(builder: (_) {
      final d = id.isEmpty ? null : store.detailFor(id);
      final String title;
      if (d == null) {
        title = l10n.healthProfileTitle;
      } else if (_isEditing) {
        title = l10n.healthProfileEditTitle;
      } else {
        title = l10n.dependentHealthTitle(d.displayName);
      }
      return AppScaffold(title: title, body: _body(context, d));
    });
  }

  Widget _body(BuildContext context, DependentSummary? d) {
    final l10n = context.l10n;
    if (id.isEmpty) {
      return const DependentNotFoundView(onBack: backToDependentList);
    }
    if (d == null) {
      final state = store.detailState;
      if (state is ErrorState<DependentSummary>) {
        if (state.error.code == 'ERR_DEP_001') {
          return const DependentNotFoundView(onBack: backToDependentList);
        }
        return AppErrorView(
          message: dependentErrorMessage(l10n, state.error),
          onRetry: () => store.loadDependentDetail(id),
        );
      }
      return const AppLoadingView(); // S-D1 (cả lúc tải detail — deep-link nguội)
    }
    // S-D8 — chỉ đánh giá khi detail đã Success.
    if (!store.canEditHealthOf(d)) {
      return DependentBlockedView(
        key: const ValueKey<String>('dependent-health-blocked'),
        message: l10n.dependentNoAccessHealth,
      );
    }
    final health = store.healthState;
    final canSave = store.canSaveHealthFor(id);
    final isSaving = store.healthSaveStatus == FormStatus.submitting;
    final saveError = store.healthSaveStatus == FormStatus.failure
        ? store.healthSaveError
        : null;
    return switch (health) {
      ErrorState<DependentHealthProfile>(:final error) => AppErrorView(
          message: dependentErrorMessage(l10n, error),
          onRetry: () => store.loadHealthProfile(id),
        ),
      SuccessState<DependentHealthProfile>(:final data)
          when data.dependentId == id =>
        _isEditing && canSave
            ? _buildForm(isSaving: isSaving, error: saveError)
            : RefreshIndicator(
                onRefresh: () => store.loadHealthProfile(id),
                child: _ViewMode(
                  profile: data,
                  onEdit: canSave ? () => _startEditing(data) : null,
                  onEditAllergens: () => Get.toNamed<void>(AppRoutes
                      .dependentAllergens
                      .replaceFirst(':dependentId', id)),
                ),
              ),
      _ => const AppLoadingView(),
    };
  }

  Widget _buildForm({required bool isSaving, required ApiException? error}) {
    final l = context.l10n;
    final fieldErrors = error?.fieldErrors ?? const <String, String>{};
    final enabled = !isSaving;
    // Field BE không map được vào ô nào → liệt kê trong khối lỗi chung.
    final unmapped = Map<String, String>.of(fieldErrors)
      ..removeWhere((String k, _) => _mappedFields.contains(k));
    final showGeneralError = error != null &&
        (error is! ValidationException ||
            fieldErrors.isEmpty ||
            unmapped.isNotEmpty);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (showGeneralError) ...<Widget>[
              _InlineError(
                key: const ValueKey<String>('dependent-health-save-error'),
                // KHÔNG chép `_healthSaveErrorMessage` — dùng
                // dependentErrorMessage (§16.16 quyết định 1).
                message: dependentErrorMessage(l, error),
                fieldLabels: <String>[
                  for (final field in unmapped.keys)
                    if (_fieldLabel(l, field) case final String label) label,
                ],
              ),
              const SizedBox(height: AppDimens.md),
            ],
            CalorieTargetField(
              stored: _storedCalories,
              touched: _caloriesTouched,
              notSet: _caloriesNotSet,
              sliderValue: _sliderValue,
              enabled: enabled,
              errorText: fieldErrors.containsKey('targetDailyCalories')
                  ? l.healthProfileCaloriesServerInvalid
                  : null,
              onSliderChanged: (int v) {
                _onFieldEdited();
                setState(() {
                  _caloriesTouched = true;
                  _sliderValue = v;
                });
              },
              onNotSetChanged: (bool v) {
                _onFieldEdited();
                setState(() {
                  _caloriesTouched = true;
                  _caloriesNotSet = v;
                });
              },
            ),
            const SizedBox(height: AppDimens.md),
            DietTypeSelector(
              value: _diet,
              enabled: enabled,
              onChanged: (DietType? v) {
                _onFieldEdited();
                setState(() => _diet = v);
              },
            ),
            const SizedBox(height: AppDimens.sm),
            TextFormField(
              key: const ValueKey<String>('health-height'),
              controller: heightCtl,
              enabled: enabled,
              onChanged: (_) => _onFieldEdited(),
              validator: (value) => HealthMeasurement.isValidHeight(value ?? '')
                  ? null
                  : l.healthProfileHeightInvalid,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.healthProfileHeight,
                prefixIcon: const Icon(Icons.height_rounded),
                errorText: fieldErrors.containsKey('heightCm')
                    ? l.healthProfileHeightInvalid
                    : null,
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            TextFormField(
              key: const ValueKey<String>('health-weight'),
              controller: weightCtl,
              enabled: enabled,
              onChanged: (_) => _onFieldEdited(),
              validator: (value) => HealthMeasurement.isValidWeight(value ?? '')
                  ? null
                  : l.healthProfileWeightInvalid,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.healthProfileWeight,
                prefixIcon: const Icon(Icons.monitor_weight_outlined),
                errorText: fieldErrors.containsKey('weightKg')
                    ? l.healthProfileWeightInvalid
                    : null,
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            AppButton(
              key: const ValueKey<String>('health-save'),
              label: l.healthSave,
              isLoading: isSaving,
              onPressed: enabled ? _save : null,
            ),
            TextButton(
              key: const ValueKey<String>('health-cancel'),
              onPressed: isSaving ? null : _cancelEditing,
              child: Text(l.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Field BE được map lỗi inline dưới ô tương ứng (S-D5).
const Set<String> _mappedFields = <String>{
  'targetDailyCalories',
  'heightCm',
  'weightKg',
};

/// S-D2 (empty) / S-D3 (có dữ liệu). [onEdit] `null` = không được lưu (dietType
/// lạ — HIGH-1): ẩn nút sửa, hiện ghi chú.
class _ViewMode extends StatelessWidget {
  const _ViewMode({
    required this.profile,
    required this.onEdit,
    required this.onEditAllergens,
  });

  final DependentHealthProfile profile;
  final VoidCallback? onEdit;
  final VoidCallback onEditAllergens;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = profile;
    final theme = Theme.of(context);
    final calories = p.targetDailyCalories;
    final edit = onEdit;
    final empty = p.isEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimens.md),
      children: <Widget>[
        if (empty) ...<Widget>[
          Text(l.healthProfileEmptyTitle,
              key: const ValueKey<String>('dependent-health-empty'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: AppDimens.md),
        ],
        AppCard(
          child: Column(
            children: <Widget>[
              DependentInfoRow(
                key: const ValueKey<String>('dependent-health-view-calories'),
                label: l.healthProfileTargetCalories,
                value: empty
                    ? l.healthProfileNotSetUp
                    : (calories == null
                        ? l.healthProfileCaloriesNotSet
                        : l.healthProfileKcalValue(calories)),
              ),
              DependentInfoRow(
                key: const ValueKey<String>('dependent-health-view-diet'),
                label: l.healthProfileDietType,
                value: empty
                    ? l.healthProfileNotSetUp
                    : (p.dietType?.label(l) ?? l.healthProfileDietUnset),
              ),
              DependentInfoRow(
                label: l.healthProfileHeight,
                value: p.heightCm == null
                    ? l.healthProfileNotSetUp
                    : formatHealthNumber(p.heightCm),
              ),
              DependentInfoRow(
                label: l.healthProfileWeight,
                value: p.weightKg == null
                    ? l.healthProfileNotSetUp
                    : formatHealthNumber(p.weightKg),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(l.healthProfileAllergensSection,
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: AppDimens.sm),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: dependentAllergenChips(l, p.allergens),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey<String>('dependent-health-allergens-edit'),
                  onPressed: onEditAllergens,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l.healthProfileAllergensEdit),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.lg),
        if (edit != null)
          AppButton(
            key: ValueKey<String>(
                empty ? 'dependent-health-setup' : 'dependent-health-edit'),
            label: empty ? l.healthProfileSetUpCta : l.healthProfileEditAction,
            icon: Icons.edit_outlined,
            onPressed: edit,
          )
        else if (p.hasUnknownDiet)
          Text(
            l.dependentHealthUnknownDiet,
            key: const ValueKey<String>('dependent-health-unknown-diet'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(
      {super.key, required this.message, required this.fieldLabels});

  final String message;
  final List<String> fieldLabels;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(message, style: TextStyle(color: errorColor)),
          if (fieldLabels.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppDimens.xs),
            for (final label in fieldLabels)
              Text('• $label',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: errorColor)),
          ],
        ],
      ),
    );
  }
}

/// Tên field BE (camelCase) → nhãn l10n; field lạ → `null` (không in key thô).
String? _fieldLabel(AppLocalizations l, String field) => switch (field) {
      'targetDailyCalories' => l.healthProfileTargetCalories,
      'heightCm' => l.healthProfileHeight,
      'weightKg' => l.healthProfileWeight,
      'dietType' => l.healthProfileDietType,
      _ => null,
    };
