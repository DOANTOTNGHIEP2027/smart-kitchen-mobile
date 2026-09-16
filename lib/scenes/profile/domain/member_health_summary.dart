import 'allergen.dart';
import 'diet_type.dart';

/// Cross-member view rút gọn (OAS HealthSummaryResponse). Chỉ diet + allergens,
/// không có height/weight/calories (health-profile Decision D2). Dùng cho
/// `MemberDetailScreen` của user khác.
class MemberHealthSummary {
  const MemberHealthSummary({
    required this.userId,
    this.dietType,
    required this.allergens,
  });

  final String userId;
  final DietType? dietType;
  final List<Allergen> allergens;
}
