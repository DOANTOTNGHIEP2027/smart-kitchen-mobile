import 'package:flutter/widgets.dart';

import '../../../utils/l10n_x.dart';

/// Enum đơn vị chuẩn của OAS cooking-session (`GRAM`, `MILLILITER`, `PIECE`,
/// `UNIT`) → nhãn ngắn ("Thiếu 80 g" như mock state 8). Giá trị lạ → in
/// nguyên văn, không giấu dữ liệu.
String cookingUnitLabel(BuildContext context, String unit) {
  final l10n = context.l10n;
  return switch (unit) {
    'GRAM' => l10n.cookingUnitGram,
    'MILLILITER' => l10n.cookingUnitMilliliter,
    'PIECE' => l10n.cookingUnitPiece,
    'UNIT' => l10n.cookingUnitUnit,
    _ => unit,
  };
}
