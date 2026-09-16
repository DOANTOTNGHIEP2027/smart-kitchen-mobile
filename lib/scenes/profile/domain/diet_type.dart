/// 7 giá trị DietType thật (OAS `health-profile.yaml`). Wire format khớp đúng
/// enum: `NONE | KETO | VEGETARIAN | VEGAN | PESCATARIAN | GLUTEN_FREE | DIABETIC`.
enum DietType {
  none,
  keto,
  vegetarian,
  vegan,
  pescatarian,
  glutenFree,
  diabetic,
}

const Map<DietType, String> _dietWire = <DietType, String>{
  DietType.none: 'NONE',
  DietType.keto: 'KETO',
  DietType.vegetarian: 'VEGETARIAN',
  DietType.vegan: 'VEGAN',
  DietType.pescatarian: 'PESCATARIAN',
  DietType.glutenFree: 'GLUTEN_FREE',
  DietType.diabetic: 'DIABETIC',
};

String dietTypeToWire(DietType t) => _dietWire[t]!;

DietType dietTypeFromWire(String value) {
  final entry = _dietWire.entries.firstWhere(
    (e) => e.value == value,
    orElse: () => throw FormatException('Unknown DietType wire: $value'),
  );
  return entry.key;
}
