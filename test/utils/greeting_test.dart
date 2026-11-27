import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/utils/greeting.dart';

void main() {
  test('sáng 5–10', () {
    for (final h in <int>[5, 7, 10]) {
      expect(greetingFor(h), GreetingPeriod.morning, reason: 'hour $h');
    }
  });

  test('trưa 11–12', () {
    expect(greetingFor(11), GreetingPeriod.noon);
    expect(greetingFor(12), GreetingPeriod.noon);
  });

  test('chiều 13–17', () {
    expect(greetingFor(13), GreetingPeriod.afternoon);
    expect(greetingFor(17), GreetingPeriod.afternoon);
  });

  test('tối: 18–23 và 0–4', () {
    for (final h in <int>[18, 21, 23, 0, 4]) {
      expect(greetingFor(h), GreetingPeriod.evening, reason: 'hour $h');
    }
  });
}
