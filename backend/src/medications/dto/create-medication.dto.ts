import {
  IsString,
  IsBoolean,
  IsOptional,
  IsIn,
  MinLength,
  MaxLength,
} from 'class-validator';

/**
 * DTO for creating a new medication
 */
export class CreateMedicationDto {
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name: string;

  @IsString()
  @IsIn(['before', 'after'])
  timing: string;

  @IsString()
  @IsOptional()
  @IsIn(['breakfast', 'lunch', 'dinner', 'any'])
  mealType?: string = 'any';

  @IsString()
  @IsOptional()
  @MaxLength(50)
  dosage?: string;

  @IsString()
  @IsOptional()
  @MaxLength(500)
  notes?: string;

  @IsBoolean()
  @IsOptional()
  reminderEnabled?: boolean = true;
}
