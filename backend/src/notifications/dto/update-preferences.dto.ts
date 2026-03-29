import { IsBoolean, IsInt, IsOptional, Min, Max } from 'class-validator';

export class UpdateNotificationPreferencesDto {
  @IsOptional()
  @IsBoolean()
  notifyOnLowEnergy?: boolean;

  @IsOptional()
  @IsBoolean()
  notifyMealReminders?: boolean;

  @IsOptional()
  @IsInt()
  @Min(60) // Minimum 1 hour
  @Max(720) // Maximum 12 hours
  mealReminderInterval?: number;
}
