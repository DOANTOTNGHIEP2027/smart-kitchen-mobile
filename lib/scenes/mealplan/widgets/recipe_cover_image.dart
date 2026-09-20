import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';

/// Ảnh minh hoạ công thức cho phần gợi ý/vote.
///
/// URL của ba món demo được chọn từ `ai-native/data/recipes.json`, nhưng UI
/// không phụ thuộc vào file hay mạng: mọi món khác, hoặc ảnh tải lỗi, đều dùng
/// placeholder cục bộ. Nhờ đó cùng một card vẫn dùng được với backend thật.
class RecipeCoverImage extends StatelessWidget {
  const RecipeCoverImage({
    super.key,
    required this.recipeId,
    required this.recipeName,
    this.height = 168,
    this.width,
  });

  final String recipeId;
  final String recipeName;
  final double height;
  final double? width;

  static const Map<String, String> _demoImageUrls = <String, String>{
    'demo-recipe-ca-kho':
        'https://img-global.cpcdn.com/recipes/5abf450451a330c1/1200x630cq80/photo.jpg',
    'demo-recipe-canh-chua':
        'https://img-global.cpcdn.com/recipes/4f7b7c4b7ac6fc19/1200x630cq80/photo.jpg',
    'demo-recipe-com-ga':
        'https://img-global.cpcdn.com/recipes/36ba8a9dd0dfc545/1200x630cq80/photo.jpg',
  };

  static const Map<String, int> _demoPrepTimes = <String, int>{
    'demo-recipe-ca-kho': 40,
    'demo-recipe-canh-chua': 30,
    'demo-recipe-com-ga': 25,
  };

  /// Thời gian dùng để hiển thị trên card lịch demo. Backend thật không cần
  /// field này ở summary của dish, vì vậy trả `null` cho recipe không phải mock.
  static int? demoPrepTimeMinutes(String recipeId) => _demoPrepTimes[recipeId];

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimens.radiusMd);
    final imageUrl = _demoImageUrls[recipeId];
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppColors.border),
          color: AppColors.primaryLight,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: imageUrl == null
              ? _RecipeImageFallback(recipeName: recipeName)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _RecipeImageFallback(recipeName: recipeName),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const _RecipeImageLoading();
                  },
                ),
        ),
      ),
    );
  }
}

class _RecipeImageLoading extends StatelessWidget {
  const _RecipeImageLoading();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.primaryLight,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
}

class _RecipeImageFallback extends StatelessWidget {
  const _RecipeImageFallback({required this.recipeName});

  final String recipeName;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[AppColors.primaryGradientStart, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            recipeName.toLowerCase().contains('canh')
                ? Icons.soup_kitchen_outlined
                : Icons.restaurant_menu_outlined,
            color: AppColors.textOnPrimary,
            size: 36,
          ),
        ),
      );
}
