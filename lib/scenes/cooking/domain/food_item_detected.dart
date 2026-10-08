/// 1 món ăn AI nhận diện được trong ước tính (#77 `FoodItemDetected`).
class FoodItemDetected {
  const FoodItemDetected({
    required this.name,
    this.estimatedQuantity,
    this.estimatedCaloriesKcal,
  });

  final String name;
  final String? estimatedQuantity;
  final double? estimatedCaloriesKcal;

  factory FoodItemDetected.fromJson(Map<String, dynamic> json) {
    return FoodItemDetected(
      name: json['name'] as String,
      estimatedQuantity: json['estimatedQuantity'] as String?,
      estimatedCaloriesKcal:
          (json['estimatedCaloriesKcal'] as num?)?.toDouble(),
    );
  }
}