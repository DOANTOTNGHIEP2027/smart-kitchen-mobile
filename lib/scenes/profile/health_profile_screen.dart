import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/states/app_state_view.dart';
import '../../widgets/states/view_state.dart';
import 'domain/diet_type.dart';
import 'domain/health_profile.dart';
import 'stores/form_status.dart';
import 'stores/profile_store.dart';
import 'widgets/stale_data_banner.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  late final ProfileStore store = Get.find<ProfileStore>();
  final caloriesCtl = TextEditingController();
  final heightCtl = TextEditingController();
  final weightCtl = TextEditingController();
  DietType? diet;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    store.loadHealthProfile();
    store.loadAllergenCatalog();
  }

  @override
  void dispose() {
    caloriesCtl.dispose();
    heightCtl.dispose();
    weightCtl.dispose();
    store.clearHealthSaveError();
    super.dispose();
  }

  void _seed(HealthProfile p) {
    if (_seeded) return;
    _seeded = true;
    caloriesCtl.text = p.targetDailyCalories?.toString() ?? '';
    heightCtl.text = p.heightCm?.toString() ?? '';
    weightCtl.text = p.weightKg?.toString() ?? '';
    setState(() => diet = p.dietType);
  }

  Future<void> _save() async {
    final ok = await store.saveHealthProfile(
      targetDailyCalories: int.tryParse(caloriesCtl.text.trim()),
      dietTypeWire: diet == null ? null : dietTypeToWire(diet!),
      heightCm: double.tryParse(heightCtl.text.trim()),
      weightKg: double.tryParse(weightCtl.text.trim()),
    );
    if (ok && mounted) {
      final acknowledged = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.healthSavedDialogTitle),
          content: Text(context.l10n.healthSavedDialogMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.healthSavedDialogConfirm),
            ),
          ],
        ),
      );
      if (acknowledged == true && mounted) Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.healthProfileTitle,
      body: Observer(builder: (_) {
        return Column(
          children: <Widget>[
            if (store.healthProfileIsFromCache) const StaleDataBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => store.loadHealthProfile(),
                child: AppStateView<HealthProfile>(
                  state: store.healthProfileState,
                  onRetry: () => store.loadHealthProfile(),
                  emptyMessage: context.l10n.healthProfileEmpty,
                  successBuilder: (_, HealthProfile p) {
                    _seed(p);
                    return ListView(
                      padding: const EdgeInsets.all(AppDimens.md),
                      children: <Widget>[
                        if (store.mutationError != null) ...<Widget>[
                          _InlineError(
                            message: store.mutationError!.message,
                            fieldErrors: store.mutationError!.fieldErrors,
                          ),
                          const SizedBox(height: AppDimens.md),
                        ],
                        TextField(
                          controller: weightCtl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText:
                                context.l10n.healthProfileWeight,
                            prefixIcon: const Icon(Icons.monitor_weight_outlined),
                          ),
                        ),
                        const SizedBox(height: AppDimens.sm),
                        TextField(
                          controller: heightCtl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText:
                                context.l10n.healthProfileHeight,
                            prefixIcon: const Icon(Icons.height_rounded),
                          ),
                        ),
                        const SizedBox(height: AppDimens.sm),
                        DropdownButtonFormField<DietType?>(
                          initialValue: diet,
                          decoration: InputDecoration(
                            labelText: context.l10n.healthProfileDietType,
                            prefixIcon: const Icon(Icons.restaurant_menu_outlined),
                          ),
                          items: <DropdownMenuItem<DietType?>>[
                            for (final DietType d in DietType.values)
                              DropdownMenuItem<DietType?>(
                                value: d,
                                child: Text(_dietLabel(context, d)),
                              ),
                          ],
                          onChanged: (DietType? v) =>
                              setState(() => diet = v),
                        ),
                        const SizedBox(height: AppDimens.sm),
                        TextField(
                          controller: caloriesCtl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                context.l10n.healthProfileTargetCalories,
                            prefixIcon: const Icon(Icons.local_fire_department_outlined),
                            suffixText: 'kcal',
                          ),
                        ),
                        const SizedBox(height: AppDimens.md),
                        _AllergensSummary(
                          store: store,
                          onEdit: () =>
                              Get.toNamed(AppRoutes.profileAllergens),
                        ),
                        const SizedBox(height: AppDimens.lg),
                        AppButton(
                          label: context.l10n.healthSave,
                          isLoading: store.healthSaveStatus ==
                              FormStatus.submitting,
                          onPressed: store.healthSaveStatus ==
                                  FormStatus.submitting
                              ? null
                              : _save,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _AllergensSummary extends StatelessWidget {
  const _AllergensSummary({required this.store, required this.onEdit});

  final ProfileStore store;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final state = store.healthProfileState;
      final allergens = state is SuccessState<HealthProfile>
          ? state.data.allergens
          : const <dynamic>[];
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.health_and_safety_outlined),
                const SizedBox(width: AppDimens.sm),
                Text(context.l10n.healthProfileAllergensSection,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: AppDimens.sm),
            if (allergens.isEmpty)
              Text(context.l10n.healthProfileAllergensEmpty)
            else
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: <Widget>[
                  for (final a in allergens) Chip(label: Text(a.name)),
                ],
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(context.l10n.healthProfileAllergensEdit),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.fieldErrors});

  final String message;
  final Map<String, String>? fieldErrors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(message, style: const TextStyle(color: Colors.red)),
          if (fieldErrors != null && fieldErrors!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            for (final entry in fieldErrors!.entries)
              Text('• ${entry.key}: ${entry.value}',
                  style:
                      const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

String _dietLabel(BuildContext context, DietType t) {
  final l = context.l10n;
  return switch (t) {
    DietType.none => l.dietTypeNone,
    DietType.keto => l.dietTypeKeto,
    DietType.vegetarian => l.dietTypeVegetarian,
    DietType.vegan => l.dietTypeVegan,
    DietType.pescatarian => l.dietTypePescatarian,
    DietType.glutenFree => l.dietTypeGlutenFree,
    DietType.diabetic => l.dietTypeDiabetic,
  };
}
