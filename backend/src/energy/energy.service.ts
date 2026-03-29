import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  ENERGY_CONSTANTS,
  EnergyCalculationInput,
  EnergyState,
  EnergyStatus,
  ActivityMode,
  ACTIVITY_MULTIPLIERS,
  MealContribution,
} from './energy.constants';

@Injectable()
export class EnergyService {
  constructor(private readonly prisma: PrismaService) {}
  /**
   * Calculate remaining energy volume using the digestion decay formula
   *
   * Formula: V_remaining = V_start - (R_base * G_index * M_activity * Δt)
   *
   * @param input - Energy calculation parameters
   * @returns Remaining volume percentage (0-100)
   */
  calculateRemainingVolume(input: EnergyCalculationInput): number {
    const { startVolume, glycemicIndex, activityMultiplier, elapsedMinutes } =
      input;

    // Normalize glycemic index from 1-100 scale to 0.01-1.0 for calculation
    const normalizedGIndex = glycemicIndex / 100;

    // Apply the decay formula
    const drainAmount =
      ENERGY_CONSTANTS.R_BASE *
      normalizedGIndex *
      activityMultiplier *
      elapsedMinutes;

    const remaining = startVolume - drainAmount;

    // Clamp between 0 and 100
    return Math.max(
      ENERGY_CONSTANTS.MIN_FULLNESS,
      Math.min(ENERGY_CONSTANTS.MAX_FULLNESS, remaining),
    );
  }

  /**
   * Calculate the full energy state including ETC (Estimated Time to Crash)
   *
   * @param currentVolume - Current energy volume (0-100)
   * @param glycemicIndex - Current effective glycemic index
   * @param activityMultiplier - Current activity multiplier
   * @returns Complete energy state
   */
  calculateEnergyState(
    currentVolume: number,
    glycemicIndex: number,
    activityMultiplier: number,
  ): EnergyState {
    const status = this.getEnergyStatus(currentVolume);

    // Calculate drain rate per minute
    const normalizedGIndex = glycemicIndex / 100;
    const drainRatePerMinute =
      ENERGY_CONSTANTS.R_BASE * normalizedGIndex * activityMultiplier;

    // Calculate ETC to 30% threshold
    let etcMinutes: number | null = null;
    if (currentVolume > ENERGY_CONSTANTS.CRITICAL_THRESHOLD) {
      const volumeToThreshold =
        currentVolume - ENERGY_CONSTANTS.CRITICAL_THRESHOLD;
      etcMinutes =
        drainRatePerMinute > 0
          ? Math.ceil(volumeToThreshold / drainRatePerMinute)
          : null;
    }

    // Calculate ETC to 0%
    let etcZeroMinutes: number | null = null;
    if (currentVolume > 0) {
      etcZeroMinutes =
        drainRatePerMinute > 0
          ? Math.ceil(currentVolume / drainRatePerMinute)
          : null;
    }

    return {
      volumeRemaining: Math.round(currentVolume * 100) / 100, // Round to 2 decimal places
      status,
      etcMinutes,
      etcZeroMinutes,
    };
  }

  /**
   * Get energy status based on current volume
   *
   * @param volume - Current energy volume (0-100)
   * @returns Energy status enum
   */
  getEnergyStatus(volume: number): EnergyStatus {
    if (volume > ENERGY_CONSTANTS.WARNING_THRESHOLD) {
      return EnergyStatus.OPTIMAL;
    } else if (volume > ENERGY_CONSTANTS.CRITICAL_THRESHOLD) {
      return EnergyStatus.WARNING;
    }
    return EnergyStatus.CRITICAL;
  }

  /**
   * Calculate new fullness after adding a meal
   * Handles the multi-meal case by adding to current volume and capping at 100%
   *
   * @param currentVolume - Current energy volume (0-100)
   * @param mealContribution - Meal data from AI analysis
   * @returns New volume after meal (capped at 100%)
   */
  addMealToVolume(
    currentVolume: number,
    mealContribution: MealContribution,
  ): number {
    const newVolume = currentVolume + mealContribution.fullnessVolume;
    return Math.min(ENERGY_CONSTANTS.MAX_FULLNESS, newVolume);
  }

  /**
   * Calculate weighted average glycemic index when multiple meals are active
   *
   * @param meals - Array of active meal contributions with remaining volumes
   * @returns Weighted average glycemic index
   */
  calculateEffectiveGlycemicIndex(
    meals: Array<{ glycemicIndex: number; remainingVolume: number }>,
  ): number {
    if (meals.length === 0) return 50; // Default neutral value

    const totalVolume = meals.reduce((sum, m) => sum + m.remainingVolume, 0);
    if (totalVolume === 0) return 50;

    const weightedSum = meals.reduce(
      (sum, m) => sum + m.glycemicIndex * m.remainingVolume,
      0,
    );

    return weightedSum / totalVolume;
  }

  /**
   * Get activity multiplier for a given mode
   *
   * @param mode - Activity mode string
   * @returns Multiplier value
   */
  getActivityMultiplier(mode: string): number {
    const activityMode = mode as ActivityMode;
    return ACTIVITY_MULTIPLIERS[activityMode] ?? ACTIVITY_MULTIPLIERS.Resting;
  }

  /**
   * Calculate the timestamp when alert should be triggered
   *
   * @param currentVolume - Current energy volume
   * @param glycemicIndex - Current glycemic index
   * @param activityMultiplier - Current activity multiplier
   * @returns Date when 30% threshold will be reached, or null if already below
   */
  calculateAlertTime(
    currentVolume: number,
    glycemicIndex: number,
    activityMultiplier: number,
  ): Date | null {
    if (currentVolume <= ENERGY_CONSTANTS.ALERT_THRESHOLD) {
      return null; // Already below threshold
    }

    const state = this.calculateEnergyState(
      currentVolume,
      glycemicIndex,
      activityMultiplier,
    );

    if (state.etcMinutes === null) {
      return null;
    }

    const alertTime = new Date();
    alertTime.setMinutes(alertTime.getMinutes() + state.etcMinutes);
    return alertTime;
  }

  /**
   * Simulate energy drain over a period with activity changes
   * Useful for calculating current state from historical logs
   *
   * @param startVolume - Starting volume
   * @param glycemicIndex - Food glycemic index
   * @param activitySegments - Array of activity periods
   * @returns Final volume after all segments
   */
  simulateEnergyDrain(
    startVolume: number,
    glycemicIndex: number,
    activitySegments: Array<{
      mode: ActivityMode;
      durationMinutes: number;
    }>,
  ): number {
    let currentVolume = startVolume;

    for (const segment of activitySegments) {
      const multiplier = ACTIVITY_MULTIPLIERS[segment.mode];
      currentVolume = this.calculateRemainingVolume({
        startVolume: currentVolume,
        glycemicIndex,
        activityMultiplier: multiplier,
        elapsedMinutes: segment.durationMinutes,
      });

      // Stop if already at 0
      if (currentVolume <= 0) break;
    }

    return currentVolume;
  }

  // ============================================
  // SNAPSHOT METHODS - For O(1) status polling
  // ============================================

  /**
   * Get the latest energy snapshot for a user
   * Used as a starting point for delta-computation
   *
   * @param userId - User ID
   * @returns Latest snapshot or null if none exists
   */
  async getLatestSnapshot(userId: string): Promise<{
    id: number;
    volumeRemaining: number;
    glycemicIndex: number;
    etcMinutes: number | null;
    snapshotAt: Date;
  } | null> {
    return this.prisma.energySnapshot.findFirst({
      where: { userId },
      orderBy: { snapshotAt: 'desc' },
    });
  }

  /**
   * Save a new energy snapshot for a user
   * Called after computing the current state to avoid re-computation
   *
   * @param userId - User ID
   * @param volumeRemaining - Current volume (0-100)
   * @param glycemicIndex - Effective GI at snapshot time
   * @param etcMinutes - Estimated time to crash (optional)
   * @returns Created snapshot
   */
  async saveSnapshot(
    userId: string,
    volumeRemaining: number,
    glycemicIndex: number,
    etcMinutes: number | null,
  ) {
    return this.prisma.energySnapshot.create({
      data: {
        userId,
        volumeRemaining,
        glycemicIndex,
        etcMinutes,
        snapshotAt: new Date(),
      },
    });
  }

  /**
   * Calculate remaining volume for a single meal based on time elapsed
   * Used for per-meal tracking in weighted GI calculation
   *
   * @param meal - Meal log data
   * @param now - Current timestamp
   * @param activityMultiplier - Current activity multiplier
   * @returns Remaining volume contribution from this meal
   */
  calculateMealRemainingVolume(
    meal: {
      fullnessVolume: number;
      absorptionRate: number;
      estimatedSatiety: number;
      createdAt: Date;
    },
    now: Date,
    activityMultiplier: number,
  ): number {
    const elapsedMinutes =
      (now.getTime() - meal.createdAt.getTime()) / (1000 * 60);

    if (elapsedMinutes <= 0) return meal.fullnessVolume;

    // Calculate decay for this specific meal
    const remaining = this.calculateRemainingVolume({
      startVolume: meal.fullnessVolume,
      glycemicIndex: meal.absorptionRate,
      activityMultiplier,
      elapsedMinutes,
    });

    return Math.max(0, remaining);
  }
}
