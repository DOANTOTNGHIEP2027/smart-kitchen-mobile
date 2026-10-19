import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../data/network/dio_client.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/states/app_loading_view.dart';
import 'dependent_form_screen.dart';

/// Màn hình danh sách người phụ thuộc (trẻ em, người cao tuổi trong gia đình)
/// Tuân thủ phong cách Tasty: Giao diện sáng sủa, thẻ bo tròn mềm mại, accent sage-green.
class DependentListScreen extends StatefulWidget {
  const DependentListScreen({super.key});

  @override
  State<DependentListScreen> createState() => _DependentListScreenState();
}

class _DependentListScreenState extends State<DependentListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _dependents = <Map<String, dynamic>>[];
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadDependents();
  }

  Future<void> _loadDependents() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final dio = Get.find<DioClient>().dio;
      final response = await dio.get<Map<String, dynamic>>('/api/v1/dependents');
      final data = response.data?['data'];
      if (data is List) {
        setState(() {
          _dependents = data
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: context.l10n.dependentListTitle,
      actions: <Widget>[
        IconButton(
          tooltip: context.l10n.refresh,
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadDependents,
        ),
      ],
      body: _buildBody(theme),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dependent-fab',
        backgroundColor: AppColors.sage,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () async {
          final created = await Get.to<bool>(() => const DependentFormScreen());
          if (created == true) _loadDependents();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(
          context.l10n.dependentAddProfile,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) return const AppLoadingView();

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppDimens.md),
              Text(context.l10n.dependentLoadFailed,
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppDimens.md),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.sage),
                onPressed: _loadDependents,
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (_dependents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.sageLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  size: 36,
                  color: AppColors.sage,
                ),
              ),
              const SizedBox(height: AppDimens.md),
              Text(
                context.l10n.dependentEmptyTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimens.xs),
              Text(
                context.l10n.dependentEmptyBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.md,
        AppDimens.sm,
        AppDimens.md,
        AppDimens.xxl,
      ),
      children: <Widget>[
        // Info Banner
        Container(
          padding: const EdgeInsets.all(AppDimens.md),
          decoration: BoxDecoration(
            color: AppColors.sageLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.health_and_safety_outlined,
                color: AppColors.sageDark,
                size: 22,
              ),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: Text(
                  context.l10n.dependentAllergenInfo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.sageDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.md),

        ..._dependents.map((dep) => _buildDependentCard(theme, dep)),
      ],
    );
  }

  Widget _buildDependentCard(ThemeData theme, Map<String, dynamic> dep) {
    final name =
        dep['displayName'] as String? ?? context.l10n.dependentDefaultName;
    final dob = dep['dateOfBirth'] as String?;
    final dietType = dep['dietType'] as String? ?? 'NONE';
    final allergens = dep['allergens'] as List<dynamic>? ?? const <dynamic>[];

    String ageText = '';
    if (dob != null) {
      try {
        final birthDate = DateTime.parse(dob);
        final now = DateTime.now();
        final age = now.year - birthDate.year;
        ageText = context.l10n.dependentAgeAndBirth(age,
            '${birthDate.day}/${birthDate.month}/${birthDate.year}');
      } catch (_) {
        ageText = dob;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.sageLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  color: AppColors.sage,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (ageText.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        ageText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimens.xs),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: <Widget>[
                        if (dietType != 'NONE')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryFill,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              dependentDietLabel(context.l10n, dietType),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ...allergens.map((a) {
                          final aMap = a as Map<String, dynamic>;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 11,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  context.l10n
                                      .dependentAllergenChip('${aMap['name']}'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (allergens.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.sageLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              context.l10n.dependentNoAllergens,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.sage,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
