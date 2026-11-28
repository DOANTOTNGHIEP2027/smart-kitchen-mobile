import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import 'l10n_x.dart';
import 'quantity_format.dart';

/// Nhãn hiển thị của đơn vị (chỉ để HIỂN THỊ — giá trị gửi API giữ nguyên).
///
/// Enum chuẩn của BE (`GRAM`, `MILLILITER`, `PIECE`, `UNIT`) → nhãn ngắn theo
/// ngôn ngữ ("Thiếu 80 g" như mock state 8). Không phân biệt hoa/thường, bỏ
/// khoảng trắng thừa và nhận vài alias hay gặp (`g`, `ml`, `pcs`…). Giá trị lạ
/// (vd. `kg`, `quả`) → in nguyên văn, không giấu dữ liệu.
String unitLabelOf(AppLocalizations l10n, String unit) {
  return switch (unit.trim().toUpperCase()) {
    'GRAM' || 'GRAMS' || 'G' => l10n.cookingUnitGram,
    'MILLILITER' ||
    'MILLILITERS' ||
    'MILLILITRE' ||
    'MILLILITRES' ||
    'ML' =>
      l10n.cookingUnitMilliliter,
    'PIECE' || 'PIECES' || 'PCS' => l10n.cookingUnitPiece,
    'UNIT' || 'UNITS' => l10n.cookingUnitUnit,
    _ => unit,
  };
}

/// [unitLabelOf] lấy l10n từ [context].
String unitLabel(BuildContext context, String unit) =>
    unitLabelOf(context.l10n, unit);

/// Như [formatQuantityWithUnit] nhưng đơn vị đã qua [unitLabelOf].
String formatQuantityWithUnitLabel(
  AppLocalizations l10n,
  double qty,
  String? unit,
) =>
    formatQuantityWithUnit(qty, unit == null ? null : unitLabelOf(l10n, unit));
