/// Tag dị ứng được suy ra bằng cách nào (FE-7 §5.3, B1).
///
/// **KHÔNG được gập thành bool.** 4 trạng thái của `allergenTags` + derivation
/// không gập được vào `bool?` (đã từng bị gập → Bug bảo mật an toàn dị ứng).
enum AllergenDerivation { ingredientRule, source, manual, unverified, unknown }

AllergenDerivation parseAllergenDerivation(String? raw) => switch (raw) {
      'INGREDIENT_RULE' => AllergenDerivation.ingredientRule,
      'SOURCE' => AllergenDerivation.source,
      'MANUAL' => AllergenDerivation.manual,
      'UNVERIFIED' => AllergenDerivation.unverified,
      _ => AllergenDerivation.unknown,
    };
