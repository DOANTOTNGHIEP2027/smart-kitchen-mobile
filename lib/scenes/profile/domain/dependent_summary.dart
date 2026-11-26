import 'allergen.dart';
import 'diet_type.dart';

/// `dietType` của dependent đọc an toàn: giá trị BE thêm sau này (FE chưa
/// biết) → `null` thay vì ném `FormatException` làm sập cả danh sách
/// (dependent-profile-screens.md §16.2 "dietType lạ").
///
/// `null` CHỈ an toàn cho hiển thị — form health chặn lưu qua
/// `DependentHealthProfile.dietTypeRaw` (Guard 19).
DietType? dependentDietOrNull(String? raw) {
  if (raw == null) return null;
  try {
    return dietTypeFromWire(raw);
  } on FormatException {
    return null;
  }
}

/// `yyyy-MM-dd` (date-only, không giờ/múi giờ) — khớp `format: date` của OAS.
String formatDateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime? _dateOrNull(Object? raw) =>
    raw == null ? null : DateTime.parse(raw as String);

List<Allergen> _allergens(Object? raw) => (raw as List<dynamic>? ??
        const <dynamic>[])
    .map((Object? e) => Allergen.fromJson(e as Map<String, dynamic>))
    .toList(growable: false);

/// Id rút gọn để hiển thị khi không tra được tên (§16.3). Không `RangeError`
/// với id ngắn hơn 8 ký tự ([v1.2 review-125] L5).
String shortId(String id) => id.length <= 8 ? id : '${id.substring(0, 8)}…';

/// Hồ sơ phụ thuộc — item của `GET /dependents`, `GET /dependents/{id}`,
/// `PATCH .../guardian` (OAS `DependentSummaryResponse`) và response hẹp hơn
/// của `POST /dependents` (`fromCreateResponse`). Mọi key camelCase (OD-56).
class DependentSummary {
  const DependentSummary({
    required this.id,
    required this.guardianUserId,
    required this.guardianActive,
    required this.displayName,
    this.dateOfBirth,
    this.dietType,
    required this.allergens,
  });

  final String id;
  final String guardianUserId;

  /// `false` = guardian đã rời gia đình HOẶC bị hạ REMOTE_VIEWER (OD-84) —
  /// cảnh báo, không phải lỗi.
  final bool guardianActive;
  final String displayName;
  final DateTime? dateOfBirth;

  /// `null` = chưa thiết lập (khác `DietType.none`) hoặc giá trị FE chưa biết.
  final DietType? dietType;

  /// `[]` = "chưa ghi nhận", KHÔNG phải "không dị ứng" (§16.10 MEDIUM-1).
  final List<Allergen> allergens;

  factory DependentSummary.fromJson(Map<String, dynamic> json) =>
      DependentSummary(
        id: json['id'] as String,
        guardianUserId: json['guardianUserId'] as String,
        guardianActive: json['guardianActive'] as bool,
        displayName: json['displayName'] as String,
        dateOfBirth: _dateOrNull(json['dateOfBirth']),
        dietType: dependentDietOrNull(json['dietType'] as String?),
        allergens: _allergens(json['allergens']),
      );

  /// `POST /dependents` (OAS `DependentCreateResponse`): KHÔNG có
  /// `guardianActive`/`dietType`/`allergens`. Hồ sơ vừa tạo luôn có guardian
  /// active = người tạo, chưa có health-profile/dị ứng nào.
  factory DependentSummary.fromCreateResponse(Map<String, dynamic> json) =>
      DependentSummary(
        id: json['id'] as String,
        guardianUserId: json['guardianUserId'] as String,
        guardianActive: true,
        displayName: json['displayName'] as String,
        dateOfBirth: _dateOrNull(json['dateOfBirth']),
        allergens: const <Allergen>[],
      );

  /// Payload cache — PHẢI round-trip với [DependentSummary.fromJson] (Guard 13).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'guardianUserId': guardianUserId,
        'guardianActive': guardianActive,
        'displayName': displayName,
        'dateOfBirth': dateOfBirth == null ? null : formatDateOnly(dateOfBirth!),
        'dietType': dietType == null ? null : dietTypeToWire(dietType!),
        'allergens':
            allergens.map((Allergen a) => a.toJson()).toList(growable: false),
      };

  DependentSummary copyWith({
    DietType? dietType,
    bool clearDietType = false,
    List<Allergen>? allergens,
  }) =>
      DependentSummary(
        id: id,
        guardianUserId: guardianUserId,
        guardianActive: guardianActive,
        displayName: displayName,
        dateOfBirth: dateOfBirth,
        dietType: clearDietType ? null : (dietType ?? this.dietType),
        allergens: allergens ?? this.allergens,
      );
}
