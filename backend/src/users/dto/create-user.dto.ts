import {
  IsEmail,
  IsString,
  IsOptional,
  IsEnum,
  IsBoolean,
  IsInt,
  MinLength,
  Min,
  Max,
  IsIn,
} from 'class-validator';

export enum SensitivityLevel {
  SENSITIVE = 'Sensitive',
  NORMAL = 'Normal',
  LOW = 'Low',
}

export enum TargetGoal {
  MAINTENANCE = 'Maintenance',
  BULKING = 'Bulking',
  CUTTING = 'Cutting',
}

export class CreateUserDto {
  @IsEmail()
  email: string;

  @IsString()
  @IsOptional()
  @MinLength(2)
  name?: string;

  @IsEnum(SensitivityLevel)
  @IsOptional()
  sensitivityLevel?: SensitivityLevel = SensitivityLevel.SENSITIVE;

  @IsEnum(TargetGoal)
  @IsOptional()
  targetGoal?: TargetGoal = TargetGoal.MAINTENANCE;

  @IsString()
  @IsOptional()
  timezone?: string = 'UTC';

  @IsString()
  @IsOptional()
  @IsIn(['metric', 'imperial'])
  units?: string = 'metric';

  @IsString()
  @IsOptional()
  avatarUrl?: string;

  @IsBoolean()
  @IsOptional()
  onboardingCompleted?: boolean;

  @IsBoolean()
  @IsOptional()
  notifyOnLowEnergy?: boolean;

  @IsBoolean()
  @IsOptional()
  notifyMealReminders?: boolean;

  @IsInt()
  @IsOptional()
  @Min(60)
  @Max(720)
  mealReminderInterval?: number;
}
