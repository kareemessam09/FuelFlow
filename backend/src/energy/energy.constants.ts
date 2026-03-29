/**
 * Activity Mode Types
 * These represent different user states that affect energy drain rate
 */
export enum ActivityMode {
  RESTING = 'Resting',
  CODING = 'Coding',
  STUDYING = 'Studying',
  GYM_STRENGTH = 'GymStrength',
  GYM_CARDIO = 'GymCardio',
}

/**
 * Activity Multipliers Map
 * Higher values = faster energy drain
 */
export const ACTIVITY_MULTIPLIERS: Record<ActivityMode, number> = {
  [ActivityMode.RESTING]: 1.0,
  [ActivityMode.CODING]: 1.3,
  [ActivityMode.STUDYING]: 1.6,
  [ActivityMode.GYM_STRENGTH]: 3.5,
  [ActivityMode.GYM_CARDIO]: 5.0,
};

/**
 * Energy Status Thresholds
 */
export enum EnergyStatus {
  OPTIMAL = 'OPTIMAL', // > 60%
  WARNING = 'WARNING', // 30-60%
  CRITICAL = 'CRITICAL', // < 30%
}

/**
 * Absorption Profile Types
 * Affects how quickly food energy is released
 */
export enum AbsorptionProfile {
  FAST = 'Fast', // Quick energy spike, faster drain
  BALANCED = 'Balanced', // Moderate release
  SLOW = 'Slow', // Slow release, longer lasting
}

/**
 * Core Algorithm Constants
 */
export const ENERGY_CONSTANTS = {
  /**
   * Base metabolic drain rate (% per minute)
   * This is the rate at which energy depletes at rest (1.0x multiplier)
   */
  R_BASE: 0.5,

  /**
   * Maximum fullness percentage
   */
  MAX_FULLNESS: 100,

  /**
   * Minimum fullness percentage
   */
  MIN_FULLNESS: 0,

  /**
   * Warning threshold (%)
   */
  WARNING_THRESHOLD: 60,

  /**
   * Critical threshold (%)
   */
  CRITICAL_THRESHOLD: 30,

  /**
   * Safety buffer threshold for proactive alerts (%)
   */
  ALERT_THRESHOLD: 30,
};

/**
 * Interface for energy calculation input
 */
export interface EnergyCalculationInput {
  startVolume: number; // V_start (0-100)
  glycemicIndex: number; // G_index (1-100, normalized to 0.01-1.0)
  activityMultiplier: number; // M_activity
  elapsedMinutes: number; // Δt
}

/**
 * Interface for energy status response
 */
export interface EnergyState {
  volumeRemaining: number; // Current % (0-100)
  status: EnergyStatus;
  etcMinutes: number | null; // Estimated minutes to crash (30% threshold)
  etcZeroMinutes: number | null; // Estimated minutes to 0%
}

/**
 * Interface for meal contribution
 */
export interface MealContribution {
  fullnessVolume: number; // How much % this meal adds
  glycemicIndex: number; // Affects drain rate
  absorptionProfile: AbsorptionProfile;
  estimatedSatiety: number; // Minutes at 1.0x
}
