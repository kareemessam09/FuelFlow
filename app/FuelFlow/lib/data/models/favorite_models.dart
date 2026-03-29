import '../../domain/entities/meal.dart';

/// Favorite meal model
class FavoriteMeal {
  final String id;
  final String userId;
  final String foodName;
  final double fullnessVolume;
  final double absorptionRate;
  final AbsorptionProfile absorptionProfile;
  final int estimatedSatiety;
  final String category;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? imageUrl;
  final int usageCount;
  final DateTime createdAt;

  const FavoriteMeal({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.fullnessVolume,
    required this.absorptionRate,
    required this.absorptionProfile,
    required this.estimatedSatiety,
    required this.category,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.imageUrl,
    required this.usageCount,
    required this.createdAt,
  });

  factory FavoriteMeal.fromJson(Map<String, dynamic> json) {
    return FavoriteMeal(
      id: json['id'].toString(),
      userId: json['userId'] as String,
      foodName: json['foodName'] as String,
      fullnessVolume: (json['fullnessVolume'] as num).toDouble(),
      absorptionRate: (json['absorptionRate'] as num).toDouble(),
      absorptionProfile: AbsorptionProfile.fromString(json['absorptionProfile'] as String),
      estimatedSatiety: json['estimatedSatiety'] as int,
      category: json['category'] as String? ?? 'other',
      calories: json['calories'] as int?,
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      usageCount: json['usageCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'fullnessVolume': fullnessVolume,
      'absorptionRate': absorptionRate,
      'absorptionProfile': absorptionProfile.toApiString(),
      'estimatedSatiety': estimatedSatiety,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'imageUrl': imageUrl,
    };
  }
}

/// Meal template model
class MealTemplate {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String foodName;
  final double fullnessVolume;
  final double absorptionRate;
  final AbsorptionProfile absorptionProfile;
  final int estimatedSatiety;
  final String category;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final DateTime createdAt;

  const MealTemplate({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.foodName,
    required this.fullnessVolume,
    required this.absorptionRate,
    required this.absorptionProfile,
    required this.estimatedSatiety,
    required this.category,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    required this.createdAt,
  });

  factory MealTemplate.fromJson(Map<String, dynamic> json) {
    return MealTemplate(
      id: json['id'].toString(),
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      foodName: json['foodName'] as String,
      fullnessVolume: (json['fullnessVolume'] as num).toDouble(),
      absorptionRate: (json['absorptionRate'] as num).toDouble(),
      absorptionProfile: AbsorptionProfile.fromString(json['absorptionProfile'] as String),
      estimatedSatiety: json['estimatedSatiety'] as int,
      category: json['category'] as String? ?? 'other',
      calories: json['calories'] as int?,
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'foodName': foodName,
      'fullnessVolume': fullnessVolume,
      'absorptionRate': absorptionRate,
      'absorptionProfile': absorptionProfile.toApiString(),
      'estimatedSatiety': estimatedSatiety,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

/// Custom food model
class CustomFood {
  final String id;
  final String userId;
  final String foodName;
  final double fullnessVolume;
  final double absorptionRate;
  final AbsorptionProfile absorptionProfile;
  final int estimatedSatiety;
  final String? servingSize;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final DateTime createdAt;

  const CustomFood({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.fullnessVolume,
    required this.absorptionRate,
    required this.absorptionProfile,
    required this.estimatedSatiety,
    this.servingSize,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    required this.createdAt,
  });

  factory CustomFood.fromJson(Map<String, dynamic> json) {
    return CustomFood(
      id: json['id'].toString(),
      userId: json['userId'] as String,
      foodName: json['foodName'] as String,
      fullnessVolume: (json['fullnessVolume'] as num).toDouble(),
      absorptionRate: (json['absorptionRate'] as num).toDouble(),
      absorptionProfile: AbsorptionProfile.fromString(json['absorptionProfile'] as String),
      estimatedSatiety: json['estimatedSatiety'] as int,
      servingSize: json['servingSize'] as String?,
      calories: json['calories'] as int?,
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'fullnessVolume': fullnessVolume,
      'absorptionRate': absorptionRate,
      'absorptionProfile': absorptionProfile.toApiString(),
      'estimatedSatiety': estimatedSatiety,
      'servingSize': servingSize,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

/// Custom activity model
class CustomActivity {
  final String id;
  final String userId;
  final String name;
  final double multiplier;
  final String? icon;
  final String? description;
  final DateTime createdAt;

  const CustomActivity({
    required this.id,
    required this.userId,
    required this.name,
    required this.multiplier,
    this.icon,
    this.description,
    required this.createdAt,
  });

  factory CustomActivity.fromJson(Map<String, dynamic> json) {
    return CustomActivity(
      id: json['id'].toString(),
      userId: json['userId'] as String,
      name: json['name'] as String,
      multiplier: (json['multiplier'] as num).toDouble(),
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'multiplier': multiplier,
      'icon': icon,
      'description': description,
    };
  }
}
