import {
  IsString,
  IsUUID,
  IsNumber,
  IsOptional,
  IsEnum,
  IsIn,
  Min,
  Max,
} from 'class-validator';
import { AbsorptionProfile } from '../../energy/energy.constants';

/**
 * DTO for creating a meal via image upload
 * Most fields are populated by the AI analysis
 */
export class CreateMealDto {
  @IsUUID()
  userId: string;
}

/**
 * DTO for manually creating a meal (without image)
 */
export class CreateMealManualDto {
  @IsUUID()
  userId: string;

  @IsString()
  foodName: string;

  @IsNumber()
  @Min(0)
  @Max(100)
  fullnessVolume: number;

  @IsNumber()
  @Min(1)
  @Max(100)
  absorptionRate: number;

  @IsEnum(AbsorptionProfile)
  @IsOptional()
  absorptionProfile?: AbsorptionProfile = AbsorptionProfile.BALANCED;

  @IsNumber()
  @Min(10)
  @Max(480)
  estimatedSatiety: number;

  @IsString()
  @IsOptional()
  imageUrl?: string;

  @IsOptional()
  @IsString()
  @IsIn(['breakfast', 'lunch', 'dinner', 'snack', 'other'])
  category?: string = 'other';

  @IsOptional()
  @IsNumber()
  calories?: number;

  @IsOptional()
  @IsNumber()
  protein?: number;

  @IsOptional()
  @IsNumber()
  carbs?: number;

  @IsOptional()
  @IsNumber()
  fat?: number;
}

/**
 * DTO for updating a meal
 */
export class UpdateMealDto {
  @IsOptional()
  @IsString()
  foodName?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  fullnessVolume?: number;

  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(100)
  absorptionRate?: number;

  @IsOptional()
  @IsEnum(AbsorptionProfile)
  absorptionProfile?: AbsorptionProfile;

  @IsOptional()
  @IsNumber()
  @Min(10)
  @Max(480)
  estimatedSatiety?: number;

  @IsOptional()
  @IsString()
  @IsIn(['breakfast', 'lunch', 'dinner', 'snack', 'other'])
  category?: string;

  @IsOptional()
  @IsNumber()
  calories?: number;

  @IsOptional()
  @IsNumber()
  protein?: number;

  @IsOptional()
  @IsNumber()
  carbs?: number;

  @IsOptional()
  @IsNumber()
  fat?: number;
}

/**
 * Response DTO for meal creation with energy state
 */
export class MealResponseDto {
  id: number;
  userId: string;
  foodName: string;
  fullnessVolume: number;
  absorptionRate: number;
  absorptionProfile: string;
  estimatedSatiety: number;
  imageUrl: string | null;
  category: string;
  calories: number | null;
  protein: number | null;
  carbs: number | null;
  fat: number | null;
  createdAt: Date;
  updatedAt: Date;

  // Energy state after meal
  energyState: {
    volumeRemaining: number;
    status: string;
    etcMinutes: number | null;
    etcZeroMinutes: number | null;
  };

  // AI analysis metadata
  aiAnalysis?: {
    confidence: number;
    notes?: string;
  };
}
