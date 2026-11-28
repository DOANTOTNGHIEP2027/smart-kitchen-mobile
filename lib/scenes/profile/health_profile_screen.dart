import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../data/network/api_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/app_routes.dart';
import '../../utils/date_format.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/inputs/chip_choice_group.dart';
import '../../widgets/states/app_state_view.dart';
import 'domain/calorie_suggestion.dart';
import 'domain/calorie_target.dart';
import 'domain/diet_type.dart';
import 'domain/health_measurement.dart';
import 'domain/health_profile.dart';
import 'stores/form_status.dart';
import 'stores/profile_store.dart';
import 'widgets/calorie_target_field.dart';
import 'widgets/diet_type_label.dart';
import 'widgets/diet_type_selector.dart';
import 'widgets/health_profile_parts.dart';
import 'widgets/stale_data_banner.dart';
import '../../widgets/feedback/app_toast.dart';

/// Hồ sơ sức khỏe — chế độ xem (S10.2 empty / S10.3 view / S10.3c cache) +
/// chế độ sửa (S10.4) (§10.3, Decision D16). Chỉ vào được chế độ sửa khi
/// `canEditHealth` (Guard 13 — dữ liệu cache chỉ đọc).
class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  late final ProfileStore store = Get.find<ProfileStore>();
  final _formKey = GlobalKey<FormState>();
  final heightCtl = TextEditingController();
  final weightCtl = TextEditingController();

  bool _isEditing = false;
  DietType? _diet;
  // #201: đầu vào gợi ý calo.
  Gender? _gender;
  DateTime? _birthDate;
  ActivityLevel? _activity;
  // State cục bộ của CalorieTargetField (Guard 14).
  int? _storedCalories;
  bool _caloriesTouched = false;
  bool _caloriesNotSet = false;
  int _sliderValue = CalorieTarget.defaultWhenEnabled;

  @override
  void initState() {
    super.initState();
    store.loadHealthProfile();
    store.loadAllergenCatalog();
  }

  @override
  void dispose() {
    heightCtl.dispose();
    weightCtl.dispose();
    store.clearHealthSaveError();
    super.dispose();
  }

  /// Seed form từ hồ sơ đang lưu — chạy trong handler của nút, không trong
  /// `build`.
  void _startEditing(HealthProfile p) {
    store.clearHealthSaveError();
    setState(() {
      _isEditing = true;
      _diet = p.dietType;
      _gender = p.gender;
      _birthDate = p.birthDate;
      _activity = p.activityLevel;
      heightCtl.text = _formatNumber(p.heightCm);
      weightCtl.text = _formatNumber(p.weightKg);
      _storedCalories = p.targetDailyCalories;
      _caloriesTouched = false;
      _caloriesNotSet = p.targetDailyCalories == null;
      _sliderValue = CalorieTarget.thumbFor(p.targetDailyCalories);
    });
  }

  void _cancelEditing() {
    store.clearHealthSaveError();
    setState(() => _isEditing = false);
  }

  void _onFieldEdited() {
    if (store.healthSaveStatus == FormStatus.failure) {
      store.clearHealthSaveError();
    }
  }

  /// #201: gợi ý tính lại theo giá trị ĐANG nhập trên form (chưa lưu).
  int? get _calorieSuggestion => suggestDailyCalories(
        weightKg: HealthMeasurement.parse(weightCtl.text),
        heightCm: HealthMeasurement.parse(heightCtl.text),
        gender: _gender,
        birthDate: _birthDate,
        activityLevel: _activity,
      );

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(today.year - 30, 1, 1),
      firstDate: DateTime(1900),
      // OAS: birthDate phải ở quá khứ.
      lastDate: today.subtract(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;
    _onFieldEdited();
    setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    final ok = await store.saveHealthProfile(
      targetDailyCalories: CalorieTarget.resolveForSave(
        stored: _storedCalories,
        touched: _caloriesTouched,
        notSet: _caloriesNotSet,
        sliderValue: _sliderValue,
      ),
      dietTypeWire: _diet == null ? null : dietTypeToWire(_diet!),
      heightCm: HealthMeasurement.parse(heightCtl.text),
      weightKg: HealthMeasurement.parse(weightCtl.text),
      // #201: PUT thay toàn bộ — luôn gửi, `null` khi chưa chọn.
      genderWire: _gender == null ? null : genderToWire(_gender!),
      birthDate: _birthDate == null ? null : toApiDate(_birthDate!),
      activityLevelWire:
          _activity == null ? null : activityLevelToWire(_activity!),
    );
    if (!ok || !mounted) return;
    setState(() => _isEditing = false);
    AppToast.show(context.l10n.healthSavedToast, type: AppToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditing
          ? context.l10n.healthProfileEditTitle
          : context.l10n.healthProfileTitle,
      body: Observer(builder: (_) {
        // Đọc observable ở đây; successBuilder của AppStateView chạy ngoài
        // phạm vi theo dõi của Observer.
        final profileState = store.healthProfileState;
        final fromCache = store.healthProfileIsFromCache;
        final canEdit = store.canEditHealth;
        final isSaving = store.healthSaveStatus == FormStatus.submitting;
        final saveError = store.healthSaveStatus == FormStatus.failure
            ? store.mutationError
            : null;
        return Column(
          children: <Widget>[
            if (fromCache) StaleDataBanner(onRetry: store.loadHealthProfile),
            Expanded(
              child: AppStateView<HealthProfile>(
                state: profileState,
                onRetry: () => store.loadHealthProfile(),
                emptyMessage: context.l10n.healthProfileEmpty,
                successBuilder: (_, HealthProfile p) {
                  if (_isEditing) {
                    return _buildForm(p,
                        canEdit: canEdit, isSaving: isSaving, error: saveError);
                  }
                  return RefreshIndicator(
                    onRefresh: () => store.loadHealthProfile(),
                    child: p.isEmpty
                        ? _EmptyProfileView(
                            onSetUp: canEdit ? () => _startEditing(p) : null,
                            showNeedsNetwork: fromCache,
                          )
                        : _ProfileDetailsView(
                            profile: p,
                            onEdit: canEdit ? () => _startEditing(p) : null,
                            onEditAllergens: canEdit
                                ? () => Get.toNamed(AppRoutes.profileAllergens)
                                : null,
                            showNeedsNetwork: fromCache,
                          ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildForm(
    HealthProfile p, {
    required bool canEdit,
    required bool isSaving,
    required ApiException? error,
  }) {
    final l = context.l10n;
    final fieldErrors = error?.fieldErrors ?? const <String, String>{};
    final enabled = canEdit && !isSaving;
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
                message: _healthSaveErrorMessage(l, error),
                // Chỉ nhãn field đã l10n — KHÔNG in message BE (§12).
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
              suggestion: _calorieSuggestion,
              onApplySuggestion: () {
                final value = _calorieSuggestion;
                if (value == null) return;
                _onFieldEdited();
                setState(() {
                  _caloriesTouched = true;
                  _caloriesNotSet = false;
                  _sliderValue = value;
                });
              },
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
              helpText: l.healthProfileDietHelp,
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
              onChanged: (_) {
                _onFieldEdited();
                setState(() {}); // tính lại gợi ý calo
              },
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
              onChanged: (_) {
                _onFieldEdited();
                setState(() {}); // tính lại gợi ý calo
              },
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
            const SizedBox(height: AppDimens.md),
            ChipChoiceGroup<Gender>(
              groupKey: 'health-gender',
              icon: Icons.wc_outlined,
              title: l.healthProfileGender,
              value: _gender,
              enabled: enabled,
              options: <ChipChoiceOption<Gender>>[
                for (final g in Gender.values)
                  ChipChoiceOption<Gender>(
                      g, genderLabel(l, g), genderToWire(g)),
              ],
              onChanged: (Gender? v) {
                _onFieldEdited();
                setState(() => _gender = v);
              },
            ),
            const SizedBox(height: AppDimens.md),
            InkWell(
              key: const ValueKey<String>('health-birth-date'),
              onTap: enabled ? _pickBirthDate : null,
              child: InputDecorator(
                decoration: InputDecoration(
                  enabled: enabled,
                  labelText: l.healthProfileBirthDate,
                  prefixIcon: const Icon(Icons.cake_outlined),
                  errorText: fieldErrors.containsKey('birthDate')
                      ? l.healthProfileBirthDateInvalid
                      : null,
                ),
                child: Text(_birthDate == null
                    ? l.healthProfileBirthDateChoose
                    : formatDisplayDate(_birthDate!)),
              ),
            ),
            const SizedBox(height: AppDimens.md),
            ChipChoiceGroup<ActivityLevel>(
              groupKey: 'health-activity',
              icon: Icons.directions_run_outlined,
              title: l.healthProfileActivityLevel,
              value: _activity,
              enabled: enabled,
              options: <ChipChoiceOption<ActivityLevel>>[
                for (final a in ActivityLevel.values)
                  ChipChoiceOption<ActivityLevel>(
                      a, activityLevelLabel(l, a), activityLevelToWire(a)),
              ],
              onChanged: (ActivityLevel? v) {
                _onFieldEdited();
                setState(() => _activity = v);
              },
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

/// Field BE được map lỗi inline dưới ô tương ứng (S10.5).
const Set<String> _mappedFields = <String>{
  'targetDailyCalories',
  'heightCm',
  'weightKg',
  'birthDate',
};

String _formatNumber(double? v) {
  if (v == null) return '';
  return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// S10.2 — chưa có row profile (`updatedAt == null`).
class _EmptyProfileView extends StatelessWidget {
  const _EmptyProfileView({
    required this.onSetUp,
    required this.showNeedsNetwork,
  });

  final VoidCallback? onSetUp;
  final bool showNeedsNetwork;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimens.md),
      children: <Widget>[
        Icon(Icons.favorite_border,
            size: AppDimens.stateIcon, color: theme.colorScheme.primary),
        const SizedBox(height: AppDimens.sm),
        Text(l.healthProfileEmptyTitle,
            textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppDimens.xs),
        Text(l.healthProfileEmptyMessage,
            textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppDimens.md),
        AppCard(
          child: Column(
            children: <Widget>[
              _InfoRow(
                  label: l.healthProfileTargetCalories,
                  value: l.healthProfileNotSetUp),
              _InfoRow(
                  label: l.healthProfileDietType,
                  value: l.healthProfileNotSetUp),
              _InfoRow(
                  label: l.healthProfileAllergensSection,
                  value: l.healthProfileNotSetUp),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.lg),
        AppButton(
          key: const ValueKey<String>('health-setup'),
          label: l.healthProfileSetUpCta,
          onPressed: onSetUp,
        ),
        if (showNeedsNetwork)
          _NeedsNetworkHint(text: l.healthProfileNeedsNetwork),
      ],
    );
  }
}

/// S10.3 / S10.3c — chế độ xem.
class _ProfileDetailsView extends StatelessWidget {
  const _ProfileDetailsView({
    required this.profile,
    required this.onEdit,
    required this.onEditAllergens,
    required this.showNeedsNetwork,
  });

  final HealthProfile profile;
  final VoidCallback? onEdit;
  final VoidCallback? onEditAllergens;
  final bool showNeedsNetwork;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = profile;
    final calories = p.targetDailyCalories;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimens.md),
      children: <Widget>[
        AppCard(
          child: Column(
            children: <Widget>[
              _InfoRow(
                key: const ValueKey<String>('health-view-calories'),
                label: l.healthProfileTargetCalories,
                // Đúng giá trị lưu, kể cả ngoài 800–5000.
                value: calories == null
                    ? l.healthProfileCaloriesNotSet
                    : l.healthProfileKcalValue(calories),
              ),
              _InfoRow(
                key: const ValueKey<String>('health-view-diet'),
                label: l.healthProfileDietType,
                value: p.dietType?.label(l) ?? l.healthProfileDietUnset,
              ),
              _InfoRow(
                label: l.healthProfileHeight,
                value: p.heightCm == null
                    ? l.healthProfileNotSetUp
                    : _formatNumber(p.heightCm),
              ),
              _InfoRow(
                label: l.healthProfileWeight,
                value: p.weightKg == null
                    ? l.healthProfileNotSetUp
                    : _formatNumber(p.weightKg),
              ),
              _InfoRow(
                label: l.healthProfileGender,
                value: p.gender == null
                    ? l.healthProfileNotSetUp
                    : genderLabel(l, p.gender!),
              ),
              _InfoRow(
                label: l.healthProfileBirthDate,
                value: p.birthDate == null
                    ? l.healthProfileNotSetUp
                    : formatDisplayDate(p.birthDate!),
              ),
              _InfoRow(
                label: l.healthProfileActivityLevel,
                value: p.activityLevel == null
                    ? l.healthProfileNotSetUp
                    : activityLevelLabel(l, p.activityLevel!),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.md),
        AllergensSummaryCard(
          allergens: p.allergens,
          onEdit: onEditAllergens,
          emptyText: l.healthProfileAllergensEmpty,
          editKey: 'health-allergens-edit',
        ),
        const SizedBox(height: AppDimens.lg),
        AppButton(
          key: const ValueKey<String>('health-edit'),
          label: l.healthProfileEditAction,
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),
        if (showNeedsNetwork)
          _NeedsNetworkHint(text: l.healthProfileNeedsNetwork),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.xs),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: AppDimens.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedsNetworkHint extends StatelessWidget {
  const _NeedsNetworkHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.sm),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.fieldLabels});

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
      'gender' => l.healthProfileGender,
      'birthDate' => l.healthProfileBirthDate,
      'activityLevel' => l.healthProfileActivityLevel,
      _ => null,
    };

/// Copy lỗi lưu hồ sơ sức khoẻ (§12): theo [ApiException.code], KHÔNG bao
/// giờ trả `error.message` của BE — mã lạ/validation → `genericRetryError`
/// (cùng kiểu `familyErrorMessage`).
String _healthSaveErrorMessage(AppLocalizations l, ApiException? error) {
  if (error is AuthExpiredException) return l.sessionExpiredError;
  return switch (error?.code) {
    'ERR_NETWORK' => l.networkError,
    _ => l.genericRetryError,
  };
}
