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
}
