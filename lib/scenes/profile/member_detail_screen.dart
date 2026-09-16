import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/states/app_state_view.dart';
import 'domain/diet_type.dart';
import 'domain/member_health_summary.dart';
import 'stores/family_store.dart';

class MemberDetailScreen extends StatefulWidget {
  const MemberDetailScreen({super.key});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  late final FamilyStore store = Get.find<FamilyStore>();
  late final String userId = Get.parameters['userId'] ?? '';
  late final String fullName =
      (Get.arguments is Map ? (Get.arguments as Map)['fullName'] : null)
              as String? ??
          '';

  @override
  void initState() {
    super.initState();
    store.loadMemberSummary(userId);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: fullName.isEmpty ? context.l10n.memberDetailTitle : fullName,
      body: Observer(builder: (_) {
        return AppStateView<MemberHealthSummary>(
          state: store.memberSummaryState,
          onRetry: () => store.loadMemberSummary(userId),
          successBuilder: (_, MemberHealthSummary s) {
            return ListView(
              padding: const EdgeInsets.all(AppDimens.md),
              children: <Widget>[
                _Row(
                  label: context.l10n.memberDetailDietType,
                  value: s.dietType == null
                      ? context.l10n.dietTypeNone
                      : _dietLabel(context, s.dietType!),
                ),
                const SizedBox(height: AppDimens.md),
                Text(context.l10n.memberDetailAllergensSection,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppDimens.sm),
                if (s.allergens.isEmpty)
                  Text(context.l10n.memberDetailAllergensEmpty)
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: <Widget>[
                      for (final a in s.allergens) Chip(label: Text(a.name)),
                    ],
                  ),
              ],
            );
          },
        );
      }),
    );
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
