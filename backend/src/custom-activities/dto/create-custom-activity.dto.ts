import {
  IsString,
  IsNumber,
  IsOptional,
  Min,
  Max,
  IsIn,
} from 'class-validator';

export class CreateCustomActivityDto {
  @IsString()
  name: string;

  @IsNumber()
  @Min(0.5)
  @Max(10)
  multiplier: number;

  @IsOptional()
  @IsString()
  icon?: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class CreateActivityGoalDto {
  @IsString()
  activityType: string;

  @IsNumber()
  @Min(1)
  @Max(1440) // Max 24 hours in a day
  targetMinutes: number;

  @IsString()
  @IsIn(['daily', 'weekly'])
  period: string;
}
