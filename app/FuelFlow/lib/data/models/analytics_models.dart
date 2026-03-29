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
    return WeeklyReport(
      userId: json['userId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      avgEnergyLevel: (json['avgEnergyLevel'] as num).toDouble(),
      minEnergyLevel: (json['minEnergyLevel'] as num).toDouble(),
      maxEnergyLevel: (json['maxEnergyLevel'] as num).toDouble(),
      totalMeals: json['totalMeals'] as int,
      activityBreakdown: Map<String, int>.from(json['activityBreakdown'] as Map),
      timeInOptimal: json['timeInOptimal'] as int,
      timeInWarning: json['timeInWarning'] as int,
      timeInCritical: json['timeInCritical'] as int,
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
    return MealStats(
      totalMeals: json['totalMeals'] as int,
      avgFullness: (json['avgFullness'] as num).toDouble(),
      avgGlycemicIndex: (json['avgGlycemicIndex'] as num).toDouble(),
      mealsPerDay: (json['mealsPerDay'] as num).toDouble(),
      categoryBreakdown: Map<String, int>.from(json['categoryBreakdown'] as Map? ?? {}),
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
    return ActivityStats(
      activityMinutes: Map<String, int>.from(json['activityMinutes'] as Map),
      mostCommonActivity: json['mostCommonActivity'] as String,
      totalActiveMinutes: json['totalActiveMinutes'] as int,
      avgActivityMultiplier: (json['avgActivityMultiplier'] as num).toDouble(),
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
    return GoalProgress(
      goalId: json['id'].toString(),
      activityType: json['activityType'] as String,
      targetMinutes: json['targetMinutes'] as int,
      completedMinutes: json['completedMinutes'] as int,
      progress: (json['progress'] as num).toDouble(),
      period: json['period'] as String,
    );
  }
}
