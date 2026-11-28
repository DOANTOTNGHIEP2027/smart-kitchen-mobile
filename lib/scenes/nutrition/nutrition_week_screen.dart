import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../cooking/scenes/cooking_routes.dart';
import 'stores/nutrition_store.dart';
import 'widgets/nutrition_summary_widget.dart';

/// "Bạn đã ăn tuần này" — mở từ mục trên Profile; tải nhật ký tuần của chính
/// người dùng mỗi lần vào màn.
class NutritionWeekScreen extends StatefulWidget {
  const NutritionWeekScreen({super.key});

  @override
  State<NutritionWeekScreen> createState() => _NutritionWeekScreenState();
}

class _NutritionWeekScreenState extends State<NutritionWeekScreen> {
  late final NutritionStore store =
      Get.find<NutritionStore>(tag: NutritionStore.profileTag);

  @override
  void initState() {
    super.initState();
    store.loadCurrentWeek();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: context.l10n.nutritionWeekThisTitle,
        body: RefreshIndicator(
          onRefresh: store.loadCurrentWeek,
          child: ListView(
            padding: const EdgeInsets.all(AppDimens.md),
            children: <Widget>[
              NutritionSummaryWidget(
                store: store,
                showTitle: false,
                onSetTarget: () async => Get.toNamed<void>(AppRoutes.profileHealth),
                onOpenMealLog: () async {
                  await Get.toNamed<void>(CookingRoutes.mealLog);
                  // Vừa ghi/sửa bữa ở nhật ký → số tuần phải cập nhật ngay.
                  await store.loadCurrentWeek();
                },
              ),
            ],
          ),
        ),
      );
}
