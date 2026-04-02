import {
  Injectable,
  Logger,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateCustomActivityDto,
  CreateActivityGoalDto,
} from './dto/create-custom-activity.dto';
import {
  UpdateCustomActivityDto,
  UpdateActivityGoalDto,
} from './dto/update-custom-activity.dto';

@Injectable()
export class CustomActivitiesService {
  private readonly logger = new Logger(CustomActivitiesService.name);

  constructor(private prisma: PrismaService) {}

  // ============================================
  // CUSTOM ACTIVITIES
  // ============================================

  async createCustomActivity(userId: string, dto: CreateCustomActivityDto) {
    // Check for duplicate name
    const existing = await this.prisma.customActivity.findFirst({
      where: { userId, name: dto.name },
    });
    if (existing) {
      throw new ConflictException('Activity with this name already exists');
    }

    return this.prisma.customActivity.create({
      data: {
        userId,
        ...dto,
      },
    });
  }

  async getCustomActivities(userId: string) {
    return this.prisma.customActivity.findMany({
      where: { userId },
      orderBy: { name: 'asc' },
    });
  }

  async getCustomActivity(userId: string, id: number) {
    const activity = await this.prisma.customActivity.findFirst({
      where: { id, userId },
    });
    if (!activity) {
      throw new NotFoundException('Custom activity not found');
    }
    return activity;
  }

  async updateCustomActivity(
    userId: string,
    id: number,
    dto: UpdateCustomActivityDto,
  ) {
    await this.getCustomActivity(userId, id); // Check ownership

    // Check for duplicate name if name is being updated
    if (dto.name) {
      const existing = await this.prisma.customActivity.findFirst({
        where: { userId, name: dto.name, id: { not: id } },
      });
      if (existing) {
        throw new ConflictException('Activity with this name already exists');
      }
    }

    return this.prisma.customActivity.update({
      where: { id },
      data: dto,
    });
  }

  async deleteCustomActivity(userId: string, id: number) {
    await this.getCustomActivity(userId, id); // Check ownership
    return this.prisma.customActivity.delete({
      where: { id },
    });
  }

  /**
   * Get all activities (built-in + custom) for a user
   */
  async getAllActivities(userId: string) {
    const customActivities = await this.getCustomActivities(userId);

    // Built-in activities
    const builtInActivities = [
      {
        name: 'Resting',
        multiplier: 1.0,
        icon: '😴',
        description: 'Sleeping or relaxing',
        isBuiltIn: true,
      },
      {
        name: 'Coding',
        multiplier: 1.3,
        icon: '💻',
        description: 'Mental work, sitting',
        isBuiltIn: true,
      },
      {
        name: 'Studying',
        multiplier: 1.6,
        icon: '📚',
        description: 'Reading, learning',
        isBuiltIn: true,
      },
      {
        name: 'GymStrength',
        multiplier: 3.5,
        icon: '🏋️',
        description: 'Weightlifting',
        isBuiltIn: true,
      },
      {
        name: 'GymCardio',
        multiplier: 5.0,
        icon: '🏃',
        description: 'Running, intense cardio',
        isBuiltIn: true,
      },
    ];

    return {
      builtIn: builtInActivities,
      custom: customActivities.map((a) => ({ ...a, isBuiltIn: false })),
    };
  }

  /**
   * Get multiplier for an activity (built-in or custom)
   */
  async getMultiplierForActivity(
    userId: string,
    activityName: string,
  ): Promise<number> {
    // Check built-in activities first
    const builtInMultipliers: Record<string, number> = {
      Resting: 1.0,
      Coding: 1.3,
      Studying: 1.6,
      GymStrength: 3.5,
      GymCardio: 5.0,
    };

    if (builtInMultipliers[activityName] !== undefined) {
      return builtInMultipliers[activityName];
    }

    // Check custom activities
    const customActivity = await this.prisma.customActivity.findFirst({
      where: { userId, name: activityName },
    });

    if (customActivity) {
      return customActivity.multiplier;
    }

    // Default to Resting if not found
    return 1.0;
  }

  // ============================================
  // ACTIVITY GOALS
  // ============================================

  async createActivityGoal(userId: string, dto: CreateActivityGoalDto) {
    // Check for duplicate
    const existing = await this.prisma.activityGoal.findFirst({
      where: { userId, activityType: dto.activityType, period: dto.period },
    });
    if (existing) {
      throw new ConflictException(
        'Goal for this activity and period already exists',
      );
    }

    return this.prisma.activityGoal.create({
      data: {
        userId,
        ...dto,
      },
    });
  }

  async getActivityGoals(userId: string) {
    return this.prisma.activityGoal.findMany({
      where: { userId },
      orderBy: { activityType: 'asc' },
    });
  }

  async getActivityGoal(userId: string, id: number) {
    const goal = await this.prisma.activityGoal.findFirst({
      where: { id, userId },
    });
    if (!goal) {
      throw new NotFoundException('Activity goal not found');
    }
    return goal;
  }

  async updateActivityGoal(
    userId: string,
    id: number,
    dto: UpdateActivityGoalDto,
  ) {
    await this.getActivityGoal(userId, id); // Check ownership
    return this.prisma.activityGoal.update({
      where: { id },
      data: dto,
    });
  }

  async deleteActivityGoal(userId: string, id: number) {
    await this.getActivityGoal(userId, id); // Check ownership
    return this.prisma.activityGoal.delete({
      where: { id },
    });
  }

  /**
   * Get goal progress for all goals
   */
  async getGoalProgress(userId: string) {
    const goals = await this.getActivityGoals(userId);
    const now = new Date();

    const progressPromises = goals.map(async (goal) => {
      let startDate: Date;

      if (goal.period === 'daily') {
        startDate = new Date(now);
        startDate.setHours(0, 0, 0, 0);
      } else {
        // Weekly - start of current week (Sunday)
        startDate = new Date(now);
        startDate.setDate(now.getDate() - now.getDay());
        startDate.setHours(0, 0, 0, 0);
      }

      // Get activities of this type in the period
      const activities = await this.prisma.activityLog.findMany({
        where: {
          userId,
          modeType: goal.activityType,
          startTime: { gte: startDate },
        },
      });

      // Calculate total minutes
      let totalMinutes = 0;
      for (const activity of activities) {
        const endTime = activity.endTime || now;
        totalMinutes +=
          (endTime.getTime() - activity.startTime.getTime()) / (1000 * 60);
      }

      return {
        goal,
        currentMinutes: Math.round(totalMinutes),
        targetMinutes: goal.targetMinutes,
        progressPercent: Math.min(
          100,
          Math.round((totalMinutes / goal.targetMinutes) * 100),
        ),
        isComplete: totalMinutes >= goal.targetMinutes,
      };
    });

    return Promise.all(progressPromises);
  }
}
