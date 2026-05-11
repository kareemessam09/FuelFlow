import {
  IsInt,
  IsString,
  IsBoolean,
  IsOptional,
  Matches,
  IsArray,
  ArrayMinSize,
  ArrayMaxSize,
  Min,
  Max,
} from 'class-validator';

/**
 * DTO for creating a medication reminder schedule
 */
export class CreateMedicationScheduleDto {
  @IsInt()
  medicationId: number;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(7)
  @IsInt({ each: true })
  @Min(1, { each: true })
  @Max(7, { each: true })
  daysOfWeek: number[]; // 1-7 (Mon-Sun)

  @IsString()
  @Matches(/^([0-1][0-9]|2[0-3]):[0-5][0-9]$/, {
    message: 'time must be in HH:MM format (e.g., "08:00", "14:30")',
  })
  time: string; // HH:MM format

  @IsBoolean()
  @IsOptional()
  enabled?: boolean = true;
}
