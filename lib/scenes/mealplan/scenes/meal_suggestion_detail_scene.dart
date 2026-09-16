import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../data/meal_plan_api.dart';
import '../domain/shopping_list_sink.dart';
import '../stores/meal_plan_store.dart';
import '../stores/suggestion_store.dart';
import '../widgets/allergen_banner.dart';
import '../widgets/suggestion_card.dart';

/// Chi tiết 1 suggestion (FE-7 §12). Route chỉ từ dish VOTING.
/// Hiển thị: SuggestionCard đầy đủ + AllergenBanner + nút Accept/Reject/Re-roll.
class MealSuggestionDetailScene extends StatefulWidget {
  const MealSuggestionDetailScene({super.key});

  @override
  State<MealSuggestionDetailScene> createState() =>
      _MealSuggestionDetailSceneState();
}

class _MealSuggestionDetailSceneState extends State<MealSuggestionDetailScene> {
  late final SuggestionStore _store;

  @override
  void initState() {
    super.initState();
    final slotId = Get.parameters['slotId']!;
    final dishId = Get.parameters['dishId']!;
    _store = SuggestionStore(
      slotId: slotId,
      dishId: dishId,
      mealPlanStore: Get.find<MealPlanStore>(),
      api: Get.find<MealPlanApi>(),
      shoppingSink: const NoOpShoppingListSink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Gợi ý món ăn',
      body: Observer(
        builder: (_) {
          final suggestion = _store.currentSuggestion;
          if (_store.suggestionsUnavailable) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const AppEmptyView(
                    icon: Icons.cloud_off,
                    message:
                        'Phiên đã tồn tại nhưng chưa tải lại được danh sách gợi ý.',
                  ),
                  const SizedBox(height: AppDimens.md),
                  AppButton(
                    label: 'Làm mới',
                    expanded: false,
                    icon: Icons.refresh,
                    onPressed: () => _store.refreshSuggestions(),
                  ),
                ],
              ),
            );
          }
          if (suggestion == null) {
            return const AppEmptyView(
              icon: Icons.search_off,
              message: 'Đã xem hết gợi ý. Chờ vote hoặc thử re-roll.',
            );
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SuggestionCard(suggestion: suggestion),
                // Hiển thị AllergenBanner riêng ngoài card để test DoD rõ hơn.
                AllergenBanner(suggestion: suggestion),
                if (suggestion.missingIngredients.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppDimens.md),
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.md),
                    child: AppButton(
                      label: 'Thêm vào danh sách mua sắm',
                      variant: AppButtonVariant.secondary,
                      icon: Icons.shopping_cart_outlined,
                      onPressed: () {
                        Get.snackbar(
                          'Chưa khả dụng',
                          'Danh sách mua sắm sẽ ra mắt trong bản sau.',
                        );
                      },
                    ),
                  ),
                ],
                Observer(
                  builder: (_) => _store.actionError != null
                      ? Padding(
                          padding: const EdgeInsets.all(AppDimens.sm),
                          child: Text(
                            _store.actionError!.message,
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimens.md),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: AppButton(
                          label: 'Bỏ qua',
                          variant: AppButtonVariant.secondary,
                          icon: Icons.close,
                          onPressed:
                              _store.actionStatus ==
                                      SuggestionActionStatus.accepting
                                  ? null
                                  : () => _store.rejectSuggestion(),
                        ),
                      ),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(
                        child: AppButton(
                          label: 'Chọn món',
                          icon: Icons.check,
                          isLoading: _store.actionStatus ==
                              SuggestionActionStatus.accepting,
                          onPressed: _store.actionStatus ==
                                  SuggestionActionStatus.accepting
                              ? null
                              : () async {
                                  final ok = await _store.acceptSuggestion();
                                  if (!mounted) return;
                                  if (ok) {
                                    Get.back<void>();
                                  } else {
                                    Get.snackbar(
                                      'Không chọn được',
                                      'Đã hoàn tác thao tác.',
                                    );
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
