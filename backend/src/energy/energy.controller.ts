import {
  Controller,
  Get,
  Param,
  NotFoundException,
  UseGuards,
} from '@nestjs/common';
import { EnergyService } from './energy.service';
import { PrismaService } from '../prisma/prisma.service';
import { ACTIVITY_MULTIPLIERS, ActivityMode } from './energy.constants';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { CurrentUserType } from '../auth/decorators/current-user.decorator';

// Snapshot validity period (5 minutes)
const SNAPSHOT_TTL_MS = 5 * 60 * 1000;

@Controller('energy')
export class EnergyController {
  constructor(
    private readonly energyService: EnergyService,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * GET /api/energy/status
   * Get current energy state for authenticated user
   * Uses delta-computation from last snapshot to avoid O(n) replay
   * 
   * Optimization: Instead of replaying all meals from scratch on every poll,
   * we use cached snapshots and only compute from the snapshot forward.
   */
  @Get('status')
  @UseGuards(JwtAuthGuard)
  async getEnergyStatus(@CurrentUser() user: CurrentUserType) {
    const userId = user.userId;
    
    // Verify user exists
    const userRecord = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!userRecord) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    const now = new Date();

    // Try to get latest snapshot for delta-computation
    const latestSnapshot = await this.energyService.getLatestSnapshot(userId);
    
    // Get current activity
    const currentActivity = await this.prisma.activityLog.findFirst({
      where: {
        userId,
        endTime: null,
      },
      orderBy: { startTime: 'desc' },
    });

    const currentMultiplier = currentActivity?.multiplier ?? 1.0;

    // Determine if we can use delta-computation
    const canUseDelta = latestSnapshot && 
      (now.getTime() - latestSnapshot.snapshotAt.getTime()) < SNAPSHOT_TTL_MS;

    let currentVolume: number;
    let effectiveGI: number;

    if (canUseDelta) {
      // Delta-computation: start from snapshot and apply decay
      const result = await this.computeFromSnapshot(
        userId,
        latestSnapshot,
        now,
        currentMultiplier,
      );
      currentVolume = result.currentVolume;
      effectiveGI = result.effectiveGI;
    } else {
      // Full replay (first request or stale snapshot)
      const result = await this.computeFullReplay(userId, now, currentMultiplier);
      currentVolume = result.currentVolume;
      effectiveGI = result.effectiveGI;
    }

    // Calculate energy state
    const energyState = this.energyService.calculateEnergyState(
      currentVolume,
      effectiveGI,
      currentMultiplier,
    );

    // Save new snapshot for future delta-computation
    // Only save if significant time has passed or no snapshot exists
    const shouldSaveSnapshot = !latestSnapshot || 
      (now.getTime() - latestSnapshot.snapshotAt.getTime()) > SNAPSHOT_TTL_MS / 2;
    
    if (shouldSaveSnapshot) {
      await this.energyService.saveSnapshot(
        userId,
        currentVolume,
        effectiveGI,
        energyState.etcMinutes,
      );
    }

    // Calculate alert time
    const alertTime = this.energyService.calculateAlertTime(
      currentVolume,
      effectiveGI,
      currentMultiplier,
    );

    return {
      userId,
      timestamp: now.toISOString(),
      energyState,
      currentActivity: currentActivity
        ? {
            modeType: currentActivity.modeType,
            multiplier: currentActivity.multiplier,
            startTime: currentActivity.startTime,
          }
        : null,
      effectiveGlycemicIndex: effectiveGI,
      alertTime: alertTime?.toISOString() ?? null,
      usedDeltaComputation: canUseDelta,
    };
  }

  /**
   * Compute energy state from a snapshot using delta-computation
   * Only processes meals and activities AFTER the snapshot time
   */
  private async computeFromSnapshot(
    userId: string,
    snapshot: {
      volumeRemaining: number;
      glycemicIndex: number;
      snapshotAt: Date;
    },
    now: Date,
    currentMultiplier: number,
  ): Promise<{ currentVolume: number; effectiveGI: number }> {
    // Get meals since snapshot
    const newMeals = await this.prisma.mealLog.findMany({
      where: {
        userId,
        createdAt: { gt: snapshot.snapshotAt },
      },
      orderBy: { createdAt: 'asc' },
    });

    // Get activity logs since snapshot
    const activityLogs = await this.prisma.activityLog.findMany({
      where: {
        userId,
        startTime: { gte: snapshot.snapshotAt },
      },
      orderBy: { startTime: 'asc' },
    });

    let currentVolume = snapshot.volumeRemaining;
    let effectiveGI = snapshot.glycemicIndex;
    let lastEventTime = snapshot.snapshotAt;

    // Process new meals since snapshot
    for (const meal of newMeals) {
      const minutesSinceLastEvent =
        (meal.createdAt.getTime() - lastEventTime.getTime()) / (1000 * 60);

      if (minutesSinceLastEvent > 0) {
        const multiplier = this.getMultiplierForTime(activityLogs, lastEventTime);
        currentVolume = this.energyService.calculateRemainingVolume({
          startVolume: currentVolume,
          glycemicIndex: effectiveGI,
          activityMultiplier: multiplier,
          elapsedMinutes: minutesSinceLastEvent,
        });
      }

      currentVolume = this.energyService.addMealToVolume(currentVolume, {
        fullnessVolume: meal.fullnessVolume,
        glycemicIndex: meal.absorptionRate,
        absorptionProfile: meal.absorptionProfile as any,
        estimatedSatiety: meal.estimatedSatiety,
      });

      lastEventTime = meal.createdAt;
    }

    // Calculate weighted effective GI from all active meals
    effectiveGI = await this.calculateWeightedGI(userId, now, currentMultiplier);

    // Apply decay from last event to now
    const minutesSinceLastEvent =
      (now.getTime() - lastEventTime.getTime()) / (1000 * 60);
    
    if (minutesSinceLastEvent > 0) {
      currentVolume = this.energyService.calculateRemainingVolume({
        startVolume: currentVolume,
        glycemicIndex: effectiveGI,
        activityMultiplier: currentMultiplier,
        elapsedMinutes: minutesSinceLastEvent,
      });
    }

    return { currentVolume, effectiveGI };
  }

  /**
   * Full replay computation (used when no valid snapshot exists)
   * This is O(n) but only runs on first request or when snapshot is stale
   */
  private async computeFullReplay(
    userId: string,
    now: Date,
    currentMultiplier: number,
  ): Promise<{ currentVolume: number; effectiveGI: number }> {
    // Get recent meals (last 24 hours)
    const recentMeals = await this.prisma.mealLog.findMany({
      where: {
        userId,
        createdAt: {
          gte: new Date(now.getTime() - 24 * 60 * 60 * 1000),
        },
      },
      orderBy: { createdAt: 'asc' },
    });

    // Get activity logs
    const activityLogs = await this.prisma.activityLog.findMany({
      where: {
        userId,
        startTime: {
          gte: new Date(now.getTime() - 24 * 60 * 60 * 1000),
        },
      },
      orderBy: { startTime: 'asc' },
    });

    let currentVolume = 0;
    let effectiveGI = 50;
    let lastEventTime = recentMeals.length > 0 ? recentMeals[0].createdAt : now;

    for (const meal of recentMeals) {
      const minutesSinceLastEvent =
        (meal.createdAt.getTime() - lastEventTime.getTime()) / (1000 * 60);

      if (minutesSinceLastEvent > 0) {
        const multiplier = this.getMultiplierForTime(activityLogs, lastEventTime);
        currentVolume = this.energyService.calculateRemainingVolume({
          startVolume: currentVolume,
          glycemicIndex: effectiveGI,
          activityMultiplier: multiplier,
          elapsedMinutes: minutesSinceLastEvent,
        });
      }

      currentVolume = this.energyService.addMealToVolume(currentVolume, {
        fullnessVolume: meal.fullnessVolume,
        glycemicIndex: meal.absorptionRate,
        absorptionProfile: meal.absorptionProfile as any,
        estimatedSatiety: meal.estimatedSatiety,
      });

      lastEventTime = meal.createdAt;
    }

    // Calculate weighted effective GI from all active meals
    effectiveGI = await this.calculateWeightedGI(userId, now, currentMultiplier);

    // Apply drain from last event to now
    if (recentMeals.length > 0) {
      const minutesSinceLastMeal =
        (now.getTime() - lastEventTime.getTime()) / (1000 * 60);

      currentVolume = this.energyService.calculateRemainingVolume({
        startVolume: currentVolume,
        glycemicIndex: effectiveGI,
        activityMultiplier: currentMultiplier,
        elapsedMinutes: minutesSinceLastMeal,
      });
    }

    return { currentVolume, effectiveGI };
  }

  /**
   * Calculate weighted effective GI from all active meals
   * Uses the calculateEffectiveGlycemicIndex method from EnergyService
   * 
   * This properly handles overlapping meals by weighting based on
   * remaining volume contribution of each meal.
   */
  private async calculateWeightedGI(
    userId: string,
    now: Date,
    currentMultiplier: number,
  ): Promise<number> {
    // Get meals still within their satiety window (approx 4-6 hours)
    const activeMeals = await this.prisma.mealLog.findMany({
      where: {
        userId,
        createdAt: {
          gte: new Date(now.getTime() - 6 * 60 * 60 * 1000), // 6 hours ago
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (activeMeals.length === 0) {
      return 50; // Default neutral GI
    }

    // Calculate remaining volume for each meal
    const mealsWithRemaining = activeMeals
      .map((meal) => {
        const remaining = this.energyService.calculateMealRemainingVolume(
          {
            fullnessVolume: meal.fullnessVolume,
            absorptionRate: meal.absorptionRate,
            estimatedSatiety: meal.estimatedSatiety,
            createdAt: meal.createdAt,
          },
          now,
          currentMultiplier,
        );

        return {
          glycemicIndex: meal.absorptionRate,
          remainingVolume: remaining,
        };
      })
      .filter((m) => m.remainingVolume > 0); // Only include meals with remaining contribution

    // Use the weighted GI calculation from EnergyService
    return this.energyService.calculateEffectiveGlycemicIndex(mealsWithRemaining);
  }

  /**
   * GET /api/energy/constants
   * Get energy calculation constants (for Flutter app)
   * This endpoint is public (no auth required)
   */
  @Get('constants')
  getConstants() {
    return {
      activityMultipliers: ACTIVITY_MULTIPLIERS,
      thresholds: {
        optimal: 60,
        warning: 30,
        critical: 0,
      },
      baseMetabolicRate: 0.5,
    };
  }

  private getMultiplierForTime(
    activityLogs: Array<{
      modeType: string;
      multiplier: number;
      startTime: Date;
      endTime: Date | null;
    }>,
    time: Date,
  ): number {
    const activeLog = activityLogs.find(
      (log) =>
        log.startTime <= time && (log.endTime === null || log.endTime >= time),
    );
    return activeLog?.multiplier ?? 1.0;
  }
}
