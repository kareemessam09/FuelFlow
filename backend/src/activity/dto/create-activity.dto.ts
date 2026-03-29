import { IsUUID, IsEnum } from 'class-validator';
import { ActivityMode } from '../../energy/energy.constants';

/**
 * DTO for toggling activity mode
 */
export class ToggleActivityDto {
  @IsUUID()
  userId: string;

  @IsEnum(ActivityMode)
  modeType: ActivityMode;
}

/**
 * Response DTO for activity toggle
 */
export class ActivityResponseDto {
  id: number;
  userId: string;
  modeType: string;
  multiplier: number;
  startTime: Date;
  endTime: Date | null;

  // Updated energy state after activity change
  energyState: {
    volumeRemaining: number;
    status: string;
    etcMinutes: number | null;
    etcZeroMinutes: number | null;
  };

  // Alert time for 30% threshold
  alertTime: Date | null;
}

/**
 * Response DTO for current activity status
 */
export class CurrentActivityDto {
  currentActivity: {
    id: number;
    modeType: string;
    multiplier: number;
    startTime: Date;
    durationMinutes: number;
  } | null;

  energyState: {
    volumeRemaining: number;
    status: string;
    etcMinutes: number | null;
    etcZeroMinutes: number | null;
  };

  alertTime: Date | null;
}
