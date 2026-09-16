import 'allergen_derivation.dart';

/// 1 phần tử dinh dưỡng của 1 suggestion (FE-7 §5.3).
///
/// `null` cho đến khi BE forward bảng thành phần thật (engine-lite chưa có
/// `\w(nutrition_fit)=0`, see engine §13.3 + D-02).
class NutritionInfo {
  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
}

/// 1 nguyên liệu của 1 suggestion (FE-7 §5.3 + B1).
class IngredientItem {
  const IngredientItem({
    required this.name,
    required this.quantity,
    required this.unit,
    this.role,
  });

  final String name;
  final double quantity;
  final String unit;

  /// [B1] MAIN | SECONDARY | SEASONING — chỉ có ở `missingIngredients`. null
  /// ở `ingredients` thường. Để FE không hiển thị "thiếu thịt" và "thiếu hành
  /// lá" cùng một mức khẩn.
  final String? role;
}

/// 1 suggestion món ăn từ AI (FE-7 §5.3, **[SỬA 2026-09-15 B1]**).
///
/// **Hai factory khác nhau có chủ đích:**
/// - [MealSuggestion.fromVoteOpen] — nguồn `POST vote/open` 201 hoặc WS
///   `session_opened`, **giàu field** sau B1.
/// - [MealSuggestion.fromResultVote] — nguồn `GET vote/result`, **vẫn nghèo**
///   (pha 2 của B1 — có thể hoãn khỏi demo). Mọi field rich → nullable/
///   empty-default, `allergenDerivation = unknown`.
///
/// **Quan trọng an toàn dị ứng (Implementation Guard #6, #7):**
/// [isAllergenCleared] `true` **chỉ khi** đã kiểm bằng luật nguyên liệu VÀ
/// `allergenTags` rỗng. [needsAllergenWarning] `true` ⇒ UI **BẮT BUỘC** hiện
/// nhãn "chưa kiểm chứng", không bao giờ `SizedBox.shrink()`.
class MealSuggestion {
  const MealSuggestion({
    required this.recipeId,
    required this.mealName,
    this.aiReasoning,
    this.description,
    this.ingredients = const <IngredientItem>[],
    this.missingIngredients = const <IngredientItem>[],
    this.nutrition,
    this.prepTimeMinutes,
    this.servingSize,
    this.dietCompatible = const <String>[],
    this.confidenceScore,
    this.kbRecipeId,
    this.source,
    this.rankReason,
    this.tradeoffNote,
    this.allergenTags = const <String>[],
    this.allergenDerivation = AllergenDerivation.unknown,
  });

  final String recipeId;
  final String mealName;
  final String? aiReasoning;
  final String? description;
  final List<IngredientItem> ingredients;
  final List<IngredientItem> missingIngredients;
  final NutritionInfo? nutrition;
  final int? prepTimeMinutes;
  final int? servingSize;
  final List<String> dietCompatible;
  final double? confidenceScore;

  // ── [B1] field từ recommendation engine ──
  final String? kbRecipeId;
  final String? source; // 'KB' | 'GENERATED' | null
  final String? rankReason;
  final String? tradeoffNote;
  final List<String> allergenTags;
  final AllergenDerivation allergenDerivation;

  /// [B1] `true` **chỉ khi** đã kiểm bằng luật nguyên liệu VÀ không có tag.
  ///
  /// `allergenTags` rỗng với derivation khác `ingredientRule` nghĩa là
  /// "CHƯA KIỂM ĐƯỢC", không phải "an toàn" (engine §7.3). Getter này thay thế
  /// `allergenFree` kiểu `bool?` của bản cũ đã bị gỡ — 4 trạng thái không gập
  /// được vào 2.
  bool get isAllergenCleared =>
      allergenDerivation == AllergenDerivation.ingredientRule &&
      allergenTags.isEmpty;

  /// `true` ⇒ UI **BẮT BUỘC** hiện nhãn cảnh báo "chưa kiểm chứng dị ứng".
  /// Guard #7 của thiết kế: `AllergenBanner` không bao giờ được im lặng khi
  /// nhánh này hit.
  bool get needsAllergenWarning =>
      allergenDerivation != AllergenDerivation.ingredientRule;

  /// Nguồn `POST vote/open` 201 hoặc WS `session_opened` — **giàu field** sau B1.
  /// Key JSON là **camelCase** ở cả REST lẫn WS (đã verify qua OAS
  /// meal-plan-voting-lifecycle.yaml và `VoteWsPublisher` BE).
  factory MealSuggestion.fromVoteOpen(Map<String, dynamic> json) {
    return MealSuggestion(
      recipeId: json['recipeId'] as String,
      mealName: json['recipeName'] as String,
      confidenceScore: (json['confidence'] as num?)?.toDouble(),
      kbRecipeId: json['kbRecipeId'] as String?,
      source: json['source'] as String?,
      rankReason: json['rankReason'] as String?,
      aiReasoning: json['rankReason'] as String?,
      tradeoffNote: json['tradeoffNote'] as String?,
      missingIngredients: ((json['missingIngredients'] as List<dynamic>?) ??
              const <dynamic>[])
          .map((Object? e) => IngredientItem(
                name: (e as Map<String, dynamic>)['name'] as String,
                quantity:
                    (((e)['quantity']) as num).toDouble(),
                unit: (e)['unit'] as String,
                role: (e)['role'] as String?,
              ))
          .toList(growable: false),
      allergenTags: ((json['allergenTags'] as List<dynamic>?) ??
              const <dynamic>[])
          .map((Object? e) => e as String)
          .toList(growable: false),
      allergenDerivation:
          parseAllergenDerivation(json['allergenDerivation'] as String?),
    );
  }

  /// Nguồn `GET vote/result` (join phiên đã tồn tại) — **vẫn nghèo** pha 2 B1.
  /// Mọi field rich giữ default `null`/`[]`/`unknown`. `allergenDerivation =
  /// unknown` ⇒ [needsAllergenWarning] = `true` ⇒ UI hiện nhãn cảnh báo — đó
  /// là hành vi ĐÚNG (ở nhánh này FE thật sự không biết món đã được kiểm dị
  /// ứng hay chưa).
  factory MealSuggestion.fromResultVote({
    required String recipeId,
    required String mealName,
  }) =>
      MealSuggestion(recipeId: recipeId, mealName: mealName);
}
