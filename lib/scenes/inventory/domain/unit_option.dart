/// Lựa chọn đơn vị trong form (FE-5 §6 — khớp 1:1 bảng conversion của BE).
///
/// [value] là literal gửi lên BE (free-text unit mà BE `UnitNormalizer` chấp
/// nhận). [canonical] chỉ dùng cho FE validate whole-number, KHÔNG gửi đi.
class UnitOption {
  const UnitOption({
    required this.value,
    required this.label,
    required this.canonical,
    required this.isWholeNumber,
  });

  final String value;
  final String label;
  final String canonical;
  final bool isWholeNumber;
}

/// Danh sách đóng, đúng literal mà BE chấp nhận (FE-5 Implementation Guard 2).
const List<UnitOption> unitOptions = <UnitOption>[
  UnitOption(value: 'g', label: 'g (gram)', canonical: 'GRAM', isWholeNumber: false),
  UnitOption(value: 'kg', label: 'kg (kilogram)', canonical: 'GRAM', isWholeNumber: false),
  UnitOption(value: 'ml', label: 'ml (mililít)', canonical: 'MILLILITER', isWholeNumber: false),
  UnitOption(value: 'l', label: 'l (lít)', canonical: 'MILLILITER', isWholeNumber: false),
  UnitOption(value: 'quả', label: 'quả / trái / củ', canonical: 'PIECE', isWholeNumber: true),
  UnitOption(value: 'cái', label: 'cái / gói / hộp / chai / túi', canonical: 'UNIT', isWholeNumber: true),
];
