import '../../../l10n/app_localizations.dart';
import '../domain/allergen.dart';

/// Nhãn l10n của [Allergen] — BE giữ tên tiếng Anh (seed 14 chất EU, AI đọc
/// tên này) nên UI phải dịch. Khớp theo tên seed (duy nhất, không phụ thuộc
/// thứ tự id sinh ra); tên lạ (catalog mở rộng sau này) → in nguyên `name`.
/// Theo mẫu [DietTypeLabel] (`diet_type_label.dart`).
extension AllergenLabel on Allergen {
  String label(AppLocalizations l) => allergenLabel(l, name);
}

/// Bản dùng cho chỗ chỉ có tên (chuỗi) thay vì [Allergen].
String allergenLabel(AppLocalizations l, String name) =>
    switch (name.trim().toLowerCase()) {
      'gluten' => l.allergenGluten,
      'crustaceans' => l.allergenCrustaceans,
      'eggs' => l.allergenEggs,
      'fish' => l.allergenFish,
      'peanuts' => l.allergenPeanuts,
      'soybeans' => l.allergenSoybeans,
      'milk' => l.allergenMilk,
      'tree nuts' => l.allergenTreeNuts,
      'celery' => l.allergenCelery,
      'mustard' => l.allergenMustard,
      'sesame' => l.allergenSesame,
      'sulphur dioxide' => l.allergenSulphurDioxide,
      'lupin' => l.allergenLupin,
      'molluscs' => l.allergenMolluscs,
      _ => name,
    };
