import 'package:equatable/equatable.dart';

/// Absorption profile for food — how quickly nutrients are released
enum AbsorptionProfile {
  fast('Fast', 'Quick energy release, spikes glucose'),
  balanced('Balanced', 'Moderate energy release'),
  slowRelease('Slow-Release', 'Sustained energy over time');

  final String displayName;
  final String description;

  const AbsorptionProfile(this.displayName, this.description);

  static AbsorptionProfile fromString(String profile) {
    switch (profile.toLowerCase()) {
      case 'fast':
        return AbsorptionProfile.fast;
      case 'balanced':
        return AbsorptionProfile.balanced;
      case 'slow':
      case 'slow-release':
      case 'slow_release':
      case 'slowrelease':
        return AbsorptionProfile.slowRelease;
      default:
        return AbsorptionProfile.balanced;
    }
  }

  /// Convert to the backend's expected enum string (PascalCase, no hyphen)
  String toApiString() {
    switch (this) {
      case AbsorptionProfile.fast:
        return 'Fast';
      case AbsorptionProfile.balanced:
        return 'Balanced';
      case AbsorptionProfile.slowRelease:
        return 'Slow';
    }
  }
}

/// Meal log entity representing a logged meal with AI analysis
class MealLog extends Equatable {
  final String id;
  final String userId;
  final String foodName;
  final double fullnessVolume; // 0-100 percentage
  final double absorptionRate; // Glycemic index (1-100)
  final AbsorptionProfile absorptionProfile;
  final int estimatedSatietyMinutes; // How long this meal lasts at 1.0x
  final String? imageUrl;
  final DateTime createdAt;

  const MealLog({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.fullnessVolume,
    required this.absorptionRate,
    required this.absorptionProfile,
    required this.estimatedSatietyMinutes,
    this.imageUrl,
    required this.createdAt,
  });

  /// Calculate the effective G_index for the decay formula
  /// Higher GI = faster absorption = faster energy depletion
  double get glycemicIndexCoefficient {
    // Normalize GI to a coefficient (higher GI = faster decay)
    // GI of 100 = coefficient of 1.5
    // GI of 50 = coefficient of 1.0
    // GI of 20 = coefficient of 0.7
    return 0.5 + (absorptionRate / 100);
  }

  MealLog copyWith({
    String? id,
    String? userId,
    String? foodName,
    double? fullnessVolume,
    double? absorptionRate,
    AbsorptionProfile? absorptionProfile,
    int? estimatedSatietyMinutes,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return MealLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodName: foodName ?? this.foodName,
      fullnessVolume: fullnessVolume ?? this.fullnessVolume,
      absorptionRate: absorptionRate ?? this.absorptionRate,
      absorptionProfile: absorptionProfile ?? this.absorptionProfile,
      estimatedSatietyMinutes:
          estimatedSatietyMinutes ?? this.estimatedSatietyMinutes,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        foodName,
        fullnessVolume,
        absorptionRate,
        absorptionProfile,
        estimatedSatietyMinutes,
        imageUrl,
        createdAt,
      ];
}

/// Result from AI meal analysis (Gemini response)
class MealAnalysisResult extends Equatable {
  final String foodName;
  final AbsorptionProfile absorptionProfile;
  final double glycemicIndex; // 1-100
  final int estimatedSatietyMinutes;
  final double estimatedFullnessPercentage; // 0-100
  final String? nutritionSummary;
  final List<String>? detectedIngredients;

  const MealAnalysisResult({
    required this.foodName,
    required this.absorptionProfile,
    required this.glycemicIndex,
    required this.estimatedSatietyMinutes,
    required this.estimatedFullnessPercentage,
    this.nutritionSummary,
    this.detectedIngredients,
  });

  @override
  List<Object?> get props => [
        foodName,
        absorptionProfile,
        glycemicIndex,
        estimatedSatietyMinutes,
        estimatedFullnessPercentage,
        nutritionSummary,
        detectedIngredients,
      ];
}
