import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../domain/meal_suggestion.dart';

/// Widget 3 nhánh cảnh báo dị ứng (FE-7 §9.3, Implementation Guard #7).
///
/// **DoD FE-7 bắt buộc:** suggestion có `allergenDerivation="UNVERIFIED"` +
/// `allergenTags=[]` → **phải** render banner vàng. Đây là test chống hồi quy
/// an toàn dị ứng — không được xoá.
///
/// 3 nhánh (theo đúng §9.3):
/// 1. [MealSuggestion.isAllergenCleared] — đã kiểm bằng luật VÀ không có tag →
///    ẩn (sizebox.shrink). Đây là TRẠNG THÁI DUY NHẤT được im lặng.
/// 2. Đã kiểm bằng luật (`!needsAllergenWarning`) VÀ CÓ tag → banner ĐỎ, nêu
///    đích danh chất gây dị ứng.
/// 3. `derivation != INGREDIENT_RULE` (SOURCE/MANUAL/UNVERIFIED/unknown) →
///    BẮT BUỘC hiện nhãn VÀNG "Chưa kiểm chứng dị ứng." KhÔNG bao giờ trả
///    `SizedBox.shrink()` ở nhánh này — engine §7.3 + AGENTS.md.
class AllergenBanner extends StatelessWidget {
  const AllergenBanner({super.key, required this.suggestion});

  final MealSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    // 1. Đã kiểm bằng luật nguyên liệu VÀ không có tag → im lặng an toàn.
    if (suggestion.isAllergenCleared) {
      return const SizedBox.shrink();
    }

    // 2. Đã kiểm bằng luật, có tag → banner ĐỎ nêu đích danh.
    if (!suggestion.needsAllergenWarning) {
      final tags = suggestion.allergenTags.join(', ');
      return _Banner(
        icon: Icons.dangerous_outlined,
        text: 'Món này chứa: $tags',
        color: AppColors.error,
      );
    }

    // 3. derivation khác INGREDIENT_RULE → BẮT BUỘC cảnh báo vàng.
    return const _Banner(
      icon: Icons.warning_amber,
      text: 'Chưa kiểm chứng dị ứng cho món này',
      color: AppColors.warning,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.md, vertical: AppDimens.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md, vertical: AppDimens.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
