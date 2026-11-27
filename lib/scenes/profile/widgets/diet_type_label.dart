import '../../../l10n/app_localizations.dart';
import '../domain/diet_type.dart';

/// Nhãn l10n của [DietType] — không bao giờ in wire value (`KETO`…) ra UI.
/// Dùng chung cho HealthProfileScreen và MemberDetailScreen.
extension DietTypeLabel on DietType {
  String label(AppLocalizations l) => switch (this) {
        DietType.none => l.healthProfileDietNone,
        DietType.keto => l.dietTypeKeto,
        DietType.vegetarian => l.dietTypeVegetarian,
        DietType.vegan => l.dietTypeVegan,
        DietType.pescatarian => l.dietTypePescatarian,
        DietType.glutenFree => l.dietTypeGlutenFree,
        DietType.diabetic => l.dietTypeDiabetic,
      };

  /// Nhãn ngắn cho chip chọn chế độ ăn (`DietTypeSelector`).
  String shortLabel(AppLocalizations l) => switch (this) {
        DietType.none => l.dietTypeNoneShort,
        _ => label(l),
      };

  /// Mô tả 1 câu hiện dưới chip đang chọn.
  String description(AppLocalizations l) => switch (this) {
        DietType.none => l.dietTypeNoneDescription,
        DietType.keto => l.dietTypeKetoDescription,
        DietType.vegetarian => l.dietTypeVegetarianDescription,
        DietType.vegan => l.dietTypeVeganDescription,
        DietType.pescatarian => l.dietTypePescatarianDescription,
        DietType.glutenFree => l.dietTypeGlutenFreeDescription,
        DietType.diabetic => l.dietTypeDiabeticDescription,
      };
}
