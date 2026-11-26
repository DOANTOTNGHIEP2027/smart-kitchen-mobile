import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/dependent_health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/dependent_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/diet_type.dart';

/// #125 §16.14 — mapper camelCase (parse sai key = field âm thầm về null).
void main() {
  final full = <String, dynamic>{
    'id': 'd1',
    'guardianUserId': 'u1',
    'guardianActive': false,
    'displayName': 'Bé Bo',
    'dateOfBirth': '2020-05-01',
    'dietType': 'VEGETARIAN',
    'allergens': <Map<String, dynamic>>[
      <String, dynamic>{'id': 1, 'name': 'Gluten'},
    ],
  };

  test('fromJson đọc đủ key camelCase', () {
    final d = DependentSummary.fromJson(full);
    expect(d.id, 'd1');
    expect(d.guardianUserId, 'u1');
    expect(d.guardianActive, isFalse);
    expect(d.displayName, 'Bé Bo');
    expect(d.dateOfBirth, DateTime(2020, 5, 1));
    expect(d.dietType, DietType.vegetarian);
    expect(d.allergens.single.name, 'Gluten');
  });

  test('fromCreateResponse: default guardianActive:true, dietType:null, allergens:[]', () {
    final d = DependentSummary.fromCreateResponse(<String, dynamic>{
      'id': 'd2',
      'householdId': 'h1',
      'guardianUserId': 'me',
      'displayName': 'Bé Na',
      'dateOfBirth': null,
      'createdAt': '2026-11-25T10:00:00Z',
    });
    expect(d.guardianActive, isTrue);
    expect(d.dietType, isNull);
    expect(d.allergens, isEmpty);
    expect(d.dateOfBirth, isNull);
  });

  test('dietType lạ → null, KHÔNG throw (không sập cả danh sách)', () {
    final d = DependentSummary.fromJson(<String, dynamic>{...full, 'dietType': 'PALEO'});
    expect(d.dietType, isNull);
  });

  test('JSON snake_case → ném lỗi (chống hồi quy key)', () {
    expect(
      () => DependentSummary.fromJson(<String, dynamic>{
        'id': 'd1',
        'guardian_user_id': 'u1',
        'guardian_active': true,
        'display_name': 'Bé Bo',
        'allergens': <dynamic>[],
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('toJson ↔ fromJson round-trip (cache), ngày sinh date-only', () {
    final d = DependentSummary.fromJson(full);
    final json = d.toJson();
    expect(json['dateOfBirth'], '2020-05-01');
    expect(json.keys, containsAll(<String>['guardianUserId', 'guardianActive', 'displayName', 'dietType']));
    final back = DependentSummary.fromJson(json);
    expect(back.id, d.id);
    expect(back.guardianActive, d.guardianActive);
    expect(back.dateOfBirth, d.dateOfBirth);
    expect(back.dietType, d.dietType);
    expect(back.allergens.map((a) => a.id), d.allergens.map((a) => a.id));
  });

  test('DependentHealthProfile: updatedAt null → isEmpty; dietType lạ giữ dietTypeRaw', () {
    final empty = DependentHealthProfile.fromJson(<String, dynamic>{
      'dependentId': 'd1',
      'targetDailyCalories': null,
      'dietType': null,
      'heightCm': null,
      'weightKg': null,
      'updatedAt': null,
      'allergens': <dynamic>[],
    });
    expect(empty.isEmpty, isTrue);
    expect(empty.hasUnknownDiet, isFalse);

    final unknown = DependentHealthProfile.fromJson(<String, dynamic>{
      'dependentId': 'd1',
      'targetDailyCalories': 1400,
      'dietType': 'PALEO',
      'heightCm': 110,
      'weightKg': 19.5,
      'updatedAt': '2026-11-20T10:00:00Z',
      'allergens': <dynamic>[],
    });
    expect(unknown.isEmpty, isFalse);
    expect(unknown.dietType, isNull);
    expect(unknown.dietTypeRaw, 'PALEO');
    expect(unknown.hasUnknownDiet, isTrue);
    expect(unknown.heightCm, 110.0);
  });

  test('shortId không RangeError với id ngắn (L5)', () {
    expect(shortId('abc'), 'abc');
    expect(shortId('12345678'), '12345678');
    expect(shortId('7f3a9c21-aaaa'), '7f3a9c21…');
  });
}
