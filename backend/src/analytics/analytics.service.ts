import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface MealStats {
  totalMeals: number;
  avgMealsPerDay: number;
  avgFullnessVolume: number;
  avgGlycemicIndex: number;
  topFoods: { foodName: string; count: number }[];
  categoryBreakdown: Record<string, number>;
}

export interface ActivityStats {
  totalActivities: number;
  totalMinutes: number;
  modeBreakdown: Record<string, number>;
  avgSessionDuration: number;
}

export interface EnergyStats {
  avgEnergyLevel: number;
  minEnergyLevel: number;
  maxEnergyLevel: number;
  timeInOptimal: number;
  timeInWarning: number;
  timeInCritical: number;
  crashCount: number; // Times energy went below 20%
}

@Injectable()
export class AnalyticsService {
  private readonly logger = new Logger(AnalyticsService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Get weekly energy report
   */
  async getWeeklyReport(userId: string, weeksAgo: number = 0) {
    const now = new Date();
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay() - weeksAgo * 7);
    startOfWeek.setHours(0, 0, 0, 0);

    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 7);

    const [mealStats, activityStats, dailySummaries] = await Promise.all([
      this.getMealStats(userId, startOfWeek, endOfWeek),
      this.getActivityStats(userId, startOfWeek, endOfWeek),
      this.getDailySummaries(userId, startOfWeek, endOfWeek),
    ]);

    const energyStats = this.calculateEnergyStatsFromSummaries(dailySummaries);

    return {
      period: 'weekly',
      startDate: startOfWeek.toISOString(),
      endDate: endOfWeek.toISOString(),
      mealStats,
      activityStats,
      energyStats,
      dailySummaries,
    };
  }

  /**
   * Get monthly energy report
   */
  async getMonthlyReport(userId: string, monthsAgo: number = 0) {
    const now = new Date();
    const startOfMonth = new Date(
      now.getFullYear(),
      now.getMonth() - monthsAgo,
      1,
    );
    const endOfMonth = new Date(
      now.getFullYear(),
      now.getMonth() - monthsAgo + 1,
      0,
      23,
      59,
      59,
    );

    const [mealStats, activityStats, dailySummaries] = await Promise.all([
      this.getMealStats(userId, startOfMonth, endOfMonth),
      this.getActivityStats(userId, startOfMonth, endOfMonth),
      this.getDailySummaries(userId, startOfMonth, endOfMonth),
    ]);

    const energyStats = this.calculateEnergyStatsFromSummaries(dailySummaries);

    return {
      period: 'monthly',
      startDate: startOfMonth.toISOString(),
      endDate: endOfMonth.toISOString(),
      mealStats,
      activityStats,
      energyStats,
      dailySummaries,
    };
  }

  /**
   * Get meal statistics for a date range
   */
  async getMealStats(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<MealStats> {
    const meals = await this.prisma.mealLog.findMany({
      where: {
        userId,
        createdAt: { gte: startDate, lte: endDate },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (meals.length === 0) {
      return {
        totalMeals: 0,
        avgMealsPerDay: 0,
        avgFullnessVolume: 0,
        avgGlycemicIndex: 0,
        topFoods: [],
        categoryBreakdown: {},
      };
    }

    const daysDiff = Math.ceil(
      (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24),
    );

    // Calculate top foods
    const foodCounts: Record<string, number> = {};
    const categoryCount: Record<string, number> = {};
    let totalFullness = 0;
    let totalGI = 0;

    for (const meal of meals) {
      foodCounts[meal.foodName] = (foodCounts[meal.foodName] || 0) + 1;
      categoryCount[meal.category] = (categoryCount[meal.category] || 0) + 1;
      totalFullness += meal.fullnessVolume;
      totalGI += meal.absorptionRate;
    }

    const topFoods = Object.entries(foodCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([foodName, count]) => ({ foodName, count }));

    return {
      totalMeals: meals.length,
      avgMealsPerDay: meals.length / daysDiff,
      avgFullnessVolume: totalFullness / meals.length,
      avgGlycemicIndex: totalGI / meals.length,
      topFoods,
      categoryBreakdown: categoryCount,
    };
  }

  /**
   * Get activity statistics for a date range
   */
  async getActivityStats(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<ActivityStats> {
    const activities = await this.prisma.activityLog.findMany({
      where: {
        userId,
        startTime: { gte: startDate, lte: endDate },
      },
    });

    if (activities.length === 0) {
      return {
        totalActivities: 0,
        totalMinutes: 0,
        modeBreakdown: {},
        avgSessionDuration: 0,
      };
    }

    const modeBreakdown: Record<string, number> = {};
    let totalMinutes = 0;

    for (const activity of activities) {
      const endTime = activity.endTime || new Date();
      const duration =
        (endTime.getTime() - activity.startTime.getTime()) / (1000 * 60);

      modeBreakdown[activity.modeType] =
        (modeBreakdown[activity.modeType] || 0) + duration;
      totalMinutes += duration;
    }

    return {
      totalActivities: activities.length,
      totalMinutes: Math.round(totalMinutes),
      modeBreakdown: Object.fromEntries(
        Object.entries(modeBreakdown).map(([k, v]) => [k, Math.round(v)]),
      ),
      avgSessionDuration: totalMinutes / activities.length,
    };
  }

  /**
   * Get daily summaries for a date range
   */
  async getDailySummaries(userId: string, startDate: Date, endDate: Date) {
    return this.prisma.dailySummary.findMany({
      where: {
        userId,
        date: { gte: startDate, lte: endDate },
      },
      orderBy: { date: 'asc' },
    });
  }

  /**
   * Calculate aggregate energy stats from daily summaries
   */
  private calculateEnergyStatsFromSummaries(summaries: any[]): EnergyStats {
    if (summaries.length === 0) {
      return {
        avgEnergyLevel: 0,
        minEnergyLevel: 0,
        maxEnergyLevel: 0,
        timeInOptimal: 0,
        timeInWarning: 0,
        timeInCritical: 0,
        crashCount: 0,
      };
    }

    let totalAvg = 0;
    let minEnergy = 100;
    let maxEnergy = 0;
    let totalOptimal = 0;
    let totalWarning = 0;
    let totalCritical = 0;
    let crashes = 0;

    for (const summary of summaries) {
      if (summary.avgEnergyLevel) totalAvg += summary.avgEnergyLevel;
      if (summary.minEnergyLevel !== null) {
        minEnergy = Math.min(minEnergy, summary.minEnergyLevel);
        if (summary.minEnergyLevel < 20) crashes++;
      }
      if (summary.maxEnergyLevel !== null) {
        maxEnergy = Math.max(maxEnergy, summary.maxEnergyLevel);
      }
      if (summary.timeInOptimal) totalOptimal += summary.timeInOptimal;
      if (summary.timeInWarning) totalWarning += summary.timeInWarning;
      if (summary.timeInCritical) totalCritical += summary.timeInCritical;
    }

    return {
      avgEnergyLevel: totalAvg / summaries.length,
      minEnergyLevel: minEnergy === 100 ? 0 : minEnergy,
      maxEnergyLevel: maxEnergy,
      timeInOptimal: totalOptimal,
      timeInWarning: totalWarning,
      timeInCritical: totalCritical,
      crashCount: crashes,
    };
  }

  /**
   * Export user data as JSON
   */
  async exportUserData(userId: string) {
    const [user, meals, activities, snapshots] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          email: true,
          name: true,
          sensitivityLevel: true,
          targetGoal: true,
          timezone: true,
          units: true,
          createdAt: true,
        },
      }),
      this.prisma.mealLog.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.activityLog.findMany({
        where: { userId },
        orderBy: { startTime: 'desc' },
      }),
      this.prisma.energySnapshot.findMany({
        where: { userId },
        orderBy: { snapshotAt: 'desc' },
        take: 1000, // Limit snapshots
      }),
    ]);

    return {
      exportDate: new Date().toISOString(),
      user,
      meals,
      activities,
      energySnapshots: snapshots,
    };
  }

  /**
   * Export meals as CSV format data
   */
  async exportMealsCSV(userId: string) {
    const meals = await this.prisma.mealLog.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    const headers = [
      'id',
      'foodName',
      'fullnessVolume',
      'absorptionRate',
      'absorptionProfile',
      'estimatedSatiety',
      'category',
      'calories',
      'protein',
      'carbs',
      'fat',
      'createdAt',
    ];

    const rows = meals.map((meal) => [
      meal.id,
      `"${meal.foodName.replace(/"/g, '""')}"`,
      meal.fullnessVolume,
      meal.absorptionRate,
      meal.absorptionProfile,
      meal.estimatedSatiety,
      meal.category,
      meal.calories || '',
      meal.protein || '',
      meal.carbs || '',
      meal.fat || '',
      meal.createdAt.toISOString(),
    ]);

    return {
      headers,
      rows,
      csv: [headers.join(','), ...rows.map((r) => r.join(','))].join('\n'),
    };
  }

  /**
   * Export activities as CSV format data
   */
  async exportActivitiesCSV(userId: string) {
    const activities = await this.prisma.activityLog.findMany({
      where: { userId },
      orderBy: { startTime: 'desc' },
    });

    const headers = [
      'id',
      'modeType',
      'multiplier',
      'startTime',
      'endTime',
      'durationMinutes',
    ];

    const rows = activities.map((activity) => {
      const endTime = activity.endTime || new Date();
      const duration =
        (endTime.getTime() - activity.startTime.getTime()) / (1000 * 60);
      return [
        activity.id,
        activity.modeType,
        activity.multiplier,
        activity.startTime.toISOString(),
        activity.endTime?.toISOString() || '',
        Math.round(duration),
      ];
    });

    return {
      headers,
      rows,
      csv: [headers.join(','), ...rows.map((r) => r.join(','))].join('\n'),
    };
  }

  /**
   * Get goal progress (for bulking/cutting/maintenance)
   */
  async getGoalProgress(userId: string, days: number = 7) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { targetGoal: true },
    });

    const mealStats = await this.getMealStats(userId, startDate, new Date());
    const activityStats = await this.getActivityStats(
      userId,
      startDate,
      new Date(),
    );

    // Simple goal progress calculation
    let progressScore = 50; // Neutral
    const goal = user?.targetGoal || 'Maintenance';

    if (goal === 'Bulking') {
      // Higher calories and fullness = better
      progressScore = Math.min(100, mealStats.avgFullnessVolume + 20);
    } else if (goal === 'Cutting') {
      // Lower fullness, more activity = better
      const activityBonus = Math.min(30, activityStats.totalMinutes / 100);
      progressScore = Math.min(
        100,
        (100 - mealStats.avgFullnessVolume) / 2 + activityBonus + 40,
      );
    } else {
      // Maintenance: balanced approach
      progressScore = Math.min(
        100,
        50 +
          (mealStats.avgMealsPerDay >= 3 ? 20 : 0) +
          (activityStats.totalMinutes > 60 * days ? 20 : 0),
      );
    }

    return {
      goal,
      days,
      progressScore: Math.round(progressScore),
      mealStats,
      activityStats,
      recommendations: this.getGoalRecommendations(
        goal,
        mealStats,
        activityStats,
      ),
    };
  }

  private getGoalRecommendations(
    goal: string,
    mealStats: MealStats,
    activityStats: ActivityStats,
  ): string[] {
    const recommendations: string[] = [];

    if (goal === 'Bulking') {
      if (mealStats.avgMealsPerDay < 4) {
        recommendations.push('Try to eat more frequently (4-5 meals/day)');
      }
      if (mealStats.avgFullnessVolume < 60) {
        recommendations.push('Consider larger portion sizes');
      }
    } else if (goal === 'Cutting') {
      if (mealStats.avgFullnessVolume > 50) {
        recommendations.push('Try smaller portion sizes');
      }
      if (activityStats.totalMinutes < 150) {
        recommendations.push(
          'Increase physical activity (aim for 150+ min/week)',
        );
      }
      if (mealStats.avgGlycemicIndex > 60) {
        recommendations.push('Choose lower GI foods for sustained energy');
      }
    } else {
      if (mealStats.avgMealsPerDay < 3) {
        recommendations.push('Maintain regular meal timing (3 meals/day)');
      }
    }

    if (recommendations.length === 0) {
      recommendations.push("You're on track! Keep up the good work.");
    }

    return recommendations;
  }
}
