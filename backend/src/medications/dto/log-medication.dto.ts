import {
  IsInt,
  IsOptional,
  IsString,
  IsDateString,
  MaxLength,
} from 'class-validator';

/**
 * DTO for logging that a medication was taken
 */
export class LogMedicationDto {
  @IsInt()
  medicationId: number;

  @IsInt()
  @IsOptional()
  mealId?: number;

  @IsDateString()
  @IsOptional()
  takenAt?: string; // ISO 8601 format, defaults to now

  @IsString()
  @IsOptional()
  @MaxLength(500)
  notes?: string;
}
