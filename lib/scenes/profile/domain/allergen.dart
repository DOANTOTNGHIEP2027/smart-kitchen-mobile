/// Một allergen trong master list 14 allergen gốc. `id` là INTEGER — không phải UUID.
class Allergen {
  const Allergen({required this.id, required this.name});

  final int id;
  final String name;

  factory Allergen.fromJson(Map<String, dynamic> json) => Allergen(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Allergen && other.id == id);

  @override
  int get hashCode => id;
}
