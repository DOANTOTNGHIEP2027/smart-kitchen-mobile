import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/utils/text_format.dart';

void main() {
  test('chuỗi rỗng giữ nguyên', () {
    expect(capitalizeFirst(''), '');
  });

  test('viết hoa chữ đầu, giữ phần còn lại', () {
    expect(capitalizeFirst('cà chua'), 'Cà chua');
    expect(capitalizeFirst('Thịt bò'), 'Thịt bò');
  });

  test('chữ tiếng Việt đặc thù', () {
    expect(capitalizeFirst('đậu phụ'), 'Đậu phụ');
    expect(capitalizeFirst('ức gà'), 'Ức gà');
  });

  test('ký tự có dấu tổ hợp (NFD) không bị cắt đôi', () {
    // "ộ" viết dạng o + dấu mũ + dấu nặng tổ hợp.
    const decomposed = 'o\u0302\u0323i';
    expect(capitalizeFirst(decomposed), 'O\u0302\u0323i');
  });
}
