import 'package:equatable/equatable.dart';

class PackageModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final int reelsCount;
  final int shootDurationMinutes;
  final int deliveryTimeMinutes;
  final List<String> features;
  final bool isActive;

  const PackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.reelsCount,
    required this.shootDurationMinutes,
    required this.deliveryTimeMinutes,
    required this.features,
    required this.isActive,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
      reelsCount: json['reels_count'] as int? ?? 1,
      shootDurationMinutes: json['shoot_duration_minutes'] as int? ?? 30,
      deliveryTimeMinutes: json['delivery_time_minutes'] as int? ?? 10,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'reels_count': reelsCount,
      'shoot_duration_minutes': shootDurationMinutes,
      'delivery_time_minutes': deliveryTimeMinutes,
      'features': features,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        reelsCount,
        shootDurationMinutes,
        deliveryTimeMinutes,
        features,
        isActive,
      ];
}
