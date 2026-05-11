/// Weekly analytics report model
class WeeklyReport {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final double avgEnergyLevel;
  final double minEnergyLevel;
  final double maxEnergyLevel;
  final int totalMeals;
  final Map<String, int> activityBreakdown; // minutes per activity
  final int timeInOptimal;
  final int timeInWarning;
  final int timeInCritical;

  const WeeklyReport({
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.avgEnergyLevel,
    required this.minEnergyLevel,
    required this.maxEnergyLevel,
    required this.totalMeals,
    required this.activityBreakdown,
    required this.timeInOptimal,
    required this.timeInWarning,
    required this.timeInCritical,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    // Backend nests stats under energyStats / mealStats / activityStats sub-objects
    final energy = json['energyStats'] as Map<String, dynamic>? ?? {};
    final meals = json['mealStats'] as Map<String, dynamic>? ?? {};
    final activity = json['activityStats'] as Map<String, dynamic>? ?? {};
    final rawBreakdown = activity['modeBreakdown'] as Map? ?? {};

    return WeeklyReport(
      userId: json['userId'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      avgEnergyLevel: (energy['avgEnergyLevel'] as num? ?? 0).toDouble(),
      minEnergyLevel: (energy['minEnergyLevel'] as num? ?? 0).toDouble(),
      maxEnergyLevel: (energy['maxEnergyLevel'] as num? ?? 0).toDouble(),
      totalMeals: (meals['totalMeals'] as num? ?? 0).toInt(),
      activityBreakdown: Map<String, int>.from(
        rawBreakdown.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
      ),
      timeInOptimal: (energy['timeInOptimal'] as num? ?? 0).toInt(),
      timeInWarning: (energy['timeInWarning'] as num? ?? 0).toInt(),
      timeInCritical: (energy['timeInCritical'] as num? ?? 0).toInt(),
    );
  }
}

/// Meal statistics model
class MealStats {
  final int totalMeals;
  final double avgFullness;
  final double avgGlycemicIndex;
  final double mealsPerDay;
  final Map<String, int> categoryBreakdown;

  const MealStats({
    required this.totalMeals,
    required this.avgFullness,
    required this.avgGlycemicIndex,
    required this.mealsPerDay,
    required this.categoryBreakdown,
  });

  factory MealStats.fromJson(Map<String, dynamic> json) {
    // Backend fields: avgFullnessVolume, avgMealsPerDay, categoryBreakdown
    final rawBreakdown = json['categoryBreakdown'] as Map? ?? {};
    return MealStats(
      totalMeals: (json['totalMeals'] as num? ?? 0).toInt(),
      avgFullness: (json['avgFullnessVolume'] as num? ?? json['avgFullness'] as num? ?? 0).toDouble(),
      avgGlycemicIndex: (json['avgGlycemicIndex'] as num? ?? 0).toDouble(),
      mealsPerDay: (json['avgMealsPerDay'] as num? ?? json['mealsPerDay'] as num? ?? 0).toDouble(),
      categoryBreakdown: Map<String, int>.from(
        rawBreakdown.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
      ),
    );
  }
}

/// Activity statistics model
class ActivityStats {
  final Map<String, int> activityMinutes;
  final String mostCommonActivity;
  final int totalActiveMinutes;
  final double avgActivityMultiplier;

  const ActivityStats({
    required this.activityMinutes,
    required this.mostCommonActivity,
    required this.totalActiveMinutes,
    required this.avgActivityMultiplier,
  });

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    // Backend fields: modeBreakdown, totalMinutes, avgSessionDuration
    final rawBreakdown = json['modeBreakdown'] as Map? ?? json['activityMinutes'] as Map? ?? {};
    final modeBreakdown = Map<String, int>.from(
      rawBreakdown.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
    );
    final mostCommon = modeBreakdown.isEmpty
        ? 'Resting'
        : (modeBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b).key);
    return ActivityStats(
      activityMinutes: modeBreakdown,
      mostCommonActivity: mostCommon,
      totalActiveMinutes: (json['totalMinutes'] as num? ?? json['totalActiveMinutes'] as num? ?? 0).toInt(),
      avgActivityMultiplier: (json['avgSessionDuration'] as num? ?? json['avgActivityMultiplier'] as num? ?? 1.0).toDouble(),
    );
  }
}

/// Goal progress model
class GoalProgress {
  final String goalId;
  final String activityType;
  final int targetMinutes;
  final int completedMinutes;
  final double progress;
  final String period;

  const GoalProgress({
    required this.goalId,
    required this.activityType,
    required this.targetMinutes,
    required this.completedMinutes,
    required this.progress,
    required this.period,
  });

  factory GoalProgress.fromJson(Map<String, dynamic> json) {
    // Supports both:
    // 1) flat shape: { id, activityType, targetMinutes, completedMinutes, progress, period }
    // 2) nested shape from /custom-activities/goals/progress:
    //    { goal: {...}, currentMinutes, progressPercent, ... }
    final nestedGoal = json['goal'] as Map<String, dynamic>?;
    final source = nestedGoal ?? json;
    final progressPercent =
        (json['progressPercent'] as num?)?.toDouble() ??
        ((json['progress'] as num?)?.toDouble() ?? 0.0) * 100.0;

    return GoalProgress(
      goalId: (source['id'] ?? '').toString(),
      activityType: (source['activityType'] as String?) ?? 'Activity',
      targetMinutes: (source['targetMinutes'] as num? ?? 0).toInt(),
      completedMinutes:
          (json['currentMinutes'] as num? ?? json['completedMinutes'] as num? ?? 0)
              .toInt(),
      progress: (progressPercent / 100.0).clamp(0.0, 1.0),
      period: (source['period'] as String?) ?? 'daily',
    );
  }
}
