import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/states/app_state_view.dart';
import '../../widgets/states/view_state.dart';
import 'domain/allergen.dart';
import 'domain/health_profile.dart';
import 'stores/form_status.dart';
import 'stores/profile_store.dart';
import 'widgets/stale_data_banner.dart';

class AllergenSelectScreen extends StatefulWidget {
  const AllergenSelectScreen({super.key});

  @override
  State<AllergenSelectScreen> createState() => _AllergenSelectScreenState();
}

class _AllergenSelectScreenState extends State<AllergenSelectScreen> {
  late final ProfileStore store = Get.find<ProfileStore>();
  Set<int> selected = <int>{};
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    if (store.healthProfileState is! SuccessState<HealthProfile>) {
      store.loadHealthProfile();
    }
    store.loadAllergenCatalog();
  }

  void _seed(List<Allergen> current) {
    if (_seeded) return;
    _seeded = true;
    setState(() => selected = current.map((Allergen a) => a.id).toSet());
  }

  Future<void> _save() async {
    final ok = await store.saveAllergens(selected.toList()..sort());
    if (ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.allergensSavedToast)));
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.allergensTitle,
      body: Column(
        children: <Widget>[
          Observer(
            builder: (_) => store.healthProfileIsFromCache
                ? const StaleDataBanner()
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Observer(
              builder: (_) {
                final healthState = store.healthProfileState;
                return AppStateView<List<Allergen>>(
                  state: store.allergenCatalogState,
                  onRetry: () => store.loadAllergenCatalog(),
                  emptyMessage: context.l10n.allergensCatalogEmpty,
                  successBuilder: (_, List<Allergen> catalog) {
                    if (healthState is SuccessState<HealthProfile>) {
                      _seed(healthState.data.allergens);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppDimens.sm),
                      itemCount: catalog.length,
                      itemBuilder: (_, int i) {
                        final a = catalog[i];
                        final checked = selected.contains(a.id);
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppDimens.md, 0, AppDimens.md, AppDimens.sm),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.sm),
                            child: CheckboxListTile(
                              value: checked,
                              contentPadding: EdgeInsets.zero,
                              activeColor: const Color(0xFFFF7A45),
                              onChanged: (bool? v) => setState(() {
                                if (v == true) {
                                  selected.add(a.id);
                                } else {
                                  selected.remove(a.id);
                                }
                              }),
                              title: Text(a.name),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimens.md),
            child: Observer(
              builder: (_) => AppButton(
                label: context.l10n.allergensSave,
                isLoading:
                    store.allergensSaveStatus == FormStatus.submitting,
                onPressed: store.allergensSaveStatus ==
                        FormStatus.submitting
                    ? null
                    : _save,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
