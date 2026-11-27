import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/domain/shared/food_category.dart';

void main() {
  test('#201 danh sách chuẩn đúng thứ tự', () {
    expect(FoodCategory.labels, <String>[
      'Rau củ',
      'Thịt',
      'Hải sản',
      'Trứng & sữa',
      'Gia vị',
      'Đồ khô & ngũ cốc',
      'Trái cây',
      'Đồ uống',
      'Khác',
    ]);
  });

  test('#201 khớp lỏng tên cũ', () {
    expect(FoodCategory.match('Thịt cá'), FoodCategory.meat);
    expect(FoodCategory.match('Trứng sữa'), FoodCategory.eggsDairy);
    expect(FoodCategory.match('Thực phẩm khô'), FoodCategory.dryGoods);
    expect(FoodCategory.match('Ngũ cốc'), FoodCategory.dryGoods);
    expect(FoodCategory.match(' rau củ '), FoodCategory.vegetables);
    expect(FoodCategory.match('Hải sản'), FoodCategory.seafood);
    expect(FoodCategory.match(null), isNull);
    expect(FoodCategory.match('Đồ gia dụng lạ'), isNull);
    expect(FoodCategory.styleOf('Đồ gia dụng lạ'), FoodCategory.other);
  });

  test('#201 sortNames: chuẩn trước theo thứ tự chuẩn, tự do sau', () {
    expect(FoodCategory.sortNames(<String>['Khô', 'Gia vị', 'Rau củ', 'Bánh']),
        <String>['Rau củ', 'Gia vị', 'Bánh', 'Khô']);
  });
}
