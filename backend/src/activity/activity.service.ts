import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EnergyService } from '../energy/energy.service';
import { MealsService } from '../meals/meals.service';
import {
  ToggleActivityDto,
  ActivityResponseDto,
  CurrentActivityDto,
} from './dto/create-activity.dto';
import { ACTIVITY_MULTIPLIERS, ActivityMode } from '../energy/energy.constants';

@Injectable()
export class ActivityService {
  private readonly logger = new Logger(ActivityService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly energyService: EnergyService,
    private readonly mealsService: MealsService,
  ) {}

  /**
   * Toggle activity mode
   * Closes the previous activity log and starts a new one
   */
  async toggle(dto: ToggleActivityDto): Promise<ActivityResponseDto> {
    // Verify user exists
    const user = await this.prisma.user.findUnique({
      where: { id: dto.userId },
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${dto.userId} not found`);
    }

    const now = new Date();

    // Close any currently active activity
    await this.prisma.activityLog.updateMany({
      where: {
        userId: dto.userId,
        endTime: null,
      },
      data: {
        endTime: now,
      },
    });

    // Get the multiplier for the new mode
    const multiplier =
      ACTIVITY_MULTIPLIERS[dto.modeType] ?? ACTIVITY_MULTIPLIERS.Resting;

    // Create new activity log
    const activity = await this.prisma.activityLog.create({
      data: {
        userId: dto.userId,
        modeType: dto.modeType,
        multiplier,
        startTime: now,
      },
    });

    this.logger.log(
      `Activity toggled for user ${dto.userId}: ${dto.modeType} (${multiplier}x)`,
    );

    // Calculate current energy state
    const energyState =
      await this.mealsService.calculateCurrentEnergyState(dto.userId);

    // Calculate alert time
    const alertTime = this.energyService.calculateAlertTime(
      energyState.volumeRemaining,
      50, // Default GI for alert calculation
      multiplier,
    );

    return {
      ...activity,
      energyState,
      alertTime,
    };
  }

  /**
   * Get current activity status for a user
   */
  async getCurrentStatus(userId: string): Promise<CurrentActivityDto> {
    // Verify user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    // Get active activity
    const activeActivity = await this.prisma.activityLog.findFirst({
      where: {
        userId,
        endTime: null,
      },
      orderBy: { startTime: 'desc' },
    });

    // Calculate current energy state
    const energyState =
      await this.mealsService.calculateCurrentEnergyState(userId);

    // Calculate duration if there's an active activity
    let currentActivity = null;
    if (activeActivity) {
      const durationMs = Date.now() - activeActivity.startTime.getTime();
      currentActivity = {
        id: activeActivity.id,
        modeType: activeActivity.modeType,
        multiplier: activeActivity.multiplier,
        startTime: activeActivity.startTime,
        durationMinutes: Math.floor(durationMs / (1000 * 60)),
      };
    }

    // Calculate alert time
    const multiplier = activeActivity?.multiplier ?? 1.0;
    const alertTime = this.energyService.calculateAlertTime(
      energyState.volumeRemaining,
      50,
      multiplier,
    );

    return {
      currentActivity,
      energyState,
      alertTime,
    };
  }

  /**
   * Get activity history for a user
   */
  async getHistory(userId: string, limit = 20) {
    return this.prisma.activityLog.findMany({
      where: { userId },
      orderBy: { startTime: 'desc' },
      take: limit,
    });
  }

  /**
   * Get today's activity summary
   */
  async getTodaySummary(userId: string) {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const activities = await this.prisma.activityLog.findMany({
      where: {
        userId,
        startTime: {
          gte: startOfDay,
        },
      },
      orderBy: { startTime: 'asc' },
    });

    // Calculate time spent in each mode
    const summary: Record<string, number> = {};
    const now = new Date();

    for (const activity of activities) {
      const endTime = activity.endTime ?? now;
      const durationMinutes =
        (endTime.getTime() - activity.startTime.getTime()) / (1000 * 60);

      if (!summary[activity.modeType]) {
        summary[activity.modeType] = 0;
      }
      summary[activity.modeType] += durationMinutes;
    }

    // Round to whole minutes
    for (const mode in summary) {
      summary[mode] = Math.round(summary[mode]);
    }

    return {
      date: startOfDay.toISOString().split('T')[0],
      activities: activities.length,
      summary,
    };
  }

  /**
   * End current activity (return to Resting)
   */
  async endCurrentActivity(userId: string): Promise<ActivityResponseDto> {
    return this.toggle({
      userId,
      modeType: ActivityMode.RESTING,
    });
  }
}
