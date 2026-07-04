class GymPackage {
  final int id;
  final String name;
  final int durationDays;
  final double price;
  final String? description;
  final String isActive; // active | inactive

  GymPackage({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
    this.description,
    required this.isActive,
  });

  bool get active => isActive == 'active';

  factory GymPackage.fromJson(Map<String, dynamic> json) {
    return GymPackage(
      id: json['id'] as int,
      name: json['name'] as String,
      durationDays: json['duration_days'] as int,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      isActive: json['is_active'] as String,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'duration_days': durationDays,
      'price': price,
      'description': (description == null || description!.isEmpty) ? null : description,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final json = toCreateJson();
    json['is_active'] = isActive;
    return json;
  }
}
