import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/utils/unit_label.dart';

void main() {
  final vi = lookupAppLocalizations(const Locale('vi'));

  test('enum BE không phân biệt hoa/thường, bỏ khoảng trắng thừa', () {
    expect(unitLabelOf(vi, 'GRAM'), 'g');
    expect(unitLabelOf(vi, 'gram'), 'g');
    expect(unitLabelOf(vi, ' Milliliter '), 'ml');
    expect(unitLabelOf(vi, 'piece'), 'quả');
    expect(unitLabelOf(vi, 'Unit'), 'cái');
  });

  test('alias hay gặp', () {
    expect(unitLabelOf(vi, 'G'), 'g');
    expect(unitLabelOf(vi, 'ML'), 'ml');
    expect(unitLabelOf(vi, 'pieces'), 'quả');
  });

  test('đơn vị lạ in nguyên văn', () {
    expect(unitLabelOf(vi, 'kg'), 'kg');
    expect(unitLabelOf(vi, 'quả'), 'quả');
    expect(unitLabelOf(vi, 'bó'), 'bó');
  });

  test('formatQuantityWithUnitLabel dịch đơn vị, null → chỉ số', () {
    expect(formatQuantityWithUnitLabel(vi, 2, 'piece'), '2 quả');
    expect(formatQuantityWithUnitLabel(vi, 1.5, 'kg'), '1.5 kg');
    expect(formatQuantityWithUnitLabel(vi, 10, null), '10');
  });
}
