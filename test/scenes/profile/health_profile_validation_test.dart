import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/calorie_target.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_measurement.dart';

void main() {
  group('CalorieTarget (Guard 14)', () {
    test('slider 800–5000 bước 50 → 84 divisions', () {
      expect(CalorieTarget.min, 800);
      expect(CalorieTarget.max, 5000);
      expect(CalorieTarget.step, 50);
      expect(CalorieTarget.divisions, 84);
    });

    test(
        'isInSliderRange: biên 800/5000 nằm trong, ngoài khoảng và null thì không',
        () {
      expect(CalorieTarget.isInSliderRange(800), isTrue);
      expect(CalorieTarget.isInSliderRange(5000), isTrue);
      expect(CalorieTarget.isInSliderRange(799), isFalse);
      expect(CalorieTarget.isInSliderRange(5001), isFalse);
      expect(CalorieTarget.isInSliderRange(0), isFalse);
      expect(CalorieTarget.isInSliderRange(null), isFalse);
    });

    test('thumbFor: null → 2000; ngoài khoảng → mép gần nhất (chỉ để vẽ)', () {
      expect(CalorieTarget.thumbFor(null), 2000);
      expect(CalorieTarget.thumbFor(1800), 1800);
      expect(CalorieTarget.thumbFor(6000), 5000);
      expect(CalorieTarget.thumbFor(600), 800);
      expect(CalorieTarget.thumbFor(0), 800);
    });

    test('snap về bội số 50 trong khoảng', () {
      expect(CalorieTarget.snap(1812.4), 1800);
      expect(CalorieTarget.snap(1826), 1850);
      expect(CalorieTarget.snap(10), 800);
      expect(CalorieTarget.snap(9999), 5000);
    });

    test('resolveForSave: AC #29 kéo tới 1800 → 1800', () {
      expect(
          CalorieTarget.resolveForSave(
              stored: 2000, touched: true, notSet: false, sliderValue: 1800),
          1800);
    });

    test(
        'resolveForSave: không chạm → giữ nguyên giá trị cũ, kể cả ngoài khoảng',
        () {
      for (final stored in <int?>[null, 0, 600, 1800, 6000, 10000]) {
        expect(
            CalorieTarget.resolveForSave(
                stored: stored,
                touched: false,
                notSet: false,
                sliderValue: CalorieTarget.thumbFor(stored)),
            stored,
            reason: 'stored=$stored phải được gửi nguyên');
      }
    });

    test('resolveForSave: bấm "Chưa đặt" → null; từ null bật lại → 2000', () {
      expect(
          CalorieTarget.resolveForSave(
              stored: 1800, touched: true, notSet: true, sliderValue: 1800),
          isNull);
      expect(
          CalorieTarget.resolveForSave(
              stored: null,
              touched: true,
              notSet: false,
              sliderValue: CalorieTarget.thumbFor(null)),
          2000);
    });
  });

  group('HealthMeasurement', () {
    test('ô trống hợp lệ và parse ra null', () {
      expect(HealthMeasurement.isValidHeight(''), isTrue);
      expect(HealthMeasurement.isValidWeight('   '), isTrue);
      expect(HealthMeasurement.parse(''), isNull);
    });

    test('chấp nhận dấu phẩy thập phân', () {
      expect(HealthMeasurement.parse('65,5'), 65.5);
      expect(HealthMeasurement.parse(' 170.2 '), 170.2);
      expect(HealthMeasurement.isValidWeight('65,5'), isTrue);
      expect(HealthMeasurement.isValidHeight('172,5'), isTrue);
    });

    test('biên chiều cao 1–300', () {
      expect(HealthMeasurement.isValidHeight('1'), isTrue);
      expect(HealthMeasurement.isValidHeight('300'), isTrue);
      expect(HealthMeasurement.isValidHeight('0'), isFalse);
      expect(HealthMeasurement.isValidHeight('0,5'), isFalse);
      expect(HealthMeasurement.isValidHeight('300,1'), isFalse);
    });

    test('biên cân nặng 1–500', () {
      expect(HealthMeasurement.isValidWeight('1'), isTrue);
      expect(HealthMeasurement.isValidWeight('500'), isTrue);
      expect(HealthMeasurement.isValidWeight('0'), isFalse);
      expect(HealthMeasurement.isValidWeight('500.5'), isFalse);
    });

    test('từ chối ký hiệu số lạ', () {
      for (final raw in <String>[
        'abc',
        '1e3',
        '-1',
        'NaN',
        '0x10',
        '1,2,3',
        '1.'
      ]) {
        expect(HealthMeasurement.parse(raw), isNull, reason: raw);
        expect(HealthMeasurement.isValidHeight(raw), isFalse, reason: raw);
      }
    });
  });
}
