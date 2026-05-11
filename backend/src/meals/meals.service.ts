import {
  Injectable,
  NotFoundException,
  Logger,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { GeminiService } from '../gemini/gemini.service';
import { EnergyService } from '../energy/energy.service';
import { MedicationsService } from '../medications/medications.service';
import { AbsorptionProfile } from '../energy/energy.constants';
import {
  CreateMealManualDto,
  MealResponseDto,
  UpdateMealDto,
} from './dto/create-meal.dto';

@Injectable()
export class MealsService {
  private readonly logger = new Logger(MealsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly geminiService: GeminiService,
    private readonly energyService: EnergyService,
    private readonly medicationsService: MedicationsService,
  ) {}

  /**
   * Analyze food image and create a meal log
   * This is the main "Snap & Fuel" feature
   */
  async createFromImage(
    userId: string,
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<MealResponseDto> {
    // Verify user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    const inferredMealCategory = this.inferMealCategory(user.timezone);
    await this.ensureBeforeMealMedicationsTaken(
      userId,
      this.normalizeMealTypeForMedication(inferredMealCategory),
    );

    // Analyze the food image with Gemini
    const analysis = await this.geminiService.analyzeFoodImage(
      imageBuffer,
      mimeType,
    );

    this.logger.log(
      `Food analyzed for user ${userId}: ${analysis.foodName} (GI: ${analysis.glycemicIndex})`,
    );

    // Get current energy state to calculate new volume
    const currentState = await this.calculateCurrentEnergyState(userId);

    // Add meal to current volume (capped at 100%)
    const newVolume = this.energyService.addMealToVolume(
      currentState.volumeRemaining,
      {
        fullnessVolume: analysis.fullnessVolume,
        glycemicIndex: analysis.glycemicIndex,
        absorptionProfile: analysis.absorptionProfile,
        estimatedSatiety: analysis.estimatedSatietyMinutes,
      },
    );

    // Create the meal log
    const meal = await this.prisma.mealLog.create({
      data: {
        userId,
        foodName: analysis.foodName,
        fullnessVolume: analysis.fullnessVolume,
        absorptionRate: analysis.glycemicIndex,
        absorptionProfile: analysis.absorptionProfile,
        estimatedSatiety: analysis.estimatedSatietyMinutes,
        imageUrl: null, // Could store in cloud storage if needed
        category: inferredMealCategory,
      },
    });

    // Get current activity multiplier
    const activeActivity = await this.getActiveActivity(userId);
    const multiplier = activeActivity?.multiplier ?? 1.0;

    // Calculate energy state after meal
    const energyState = this.energyService.calculateEnergyState(
      newVolume,
      analysis.glycemicIndex,
      multiplier,
    );

    // Schedule post-meal medication reminders
    await this.schedulePostMealMedicationReminders(
      userId,
      meal.id,
      meal.category,
    );

    return {
      ...meal,
      energyState,
      aiAnalysis: {
        confidence: analysis.confidence,
        notes: analysis.notes,
      },
    };
  }

  /**
   * Create a meal manually (without image analysis)
   */
  async createManual(dto: CreateMealManualDto): Promise<MealResponseDto> {
    // Verify user exists
    const user = await this.prisma.user.findUnique({
      where: { id: dto.userId },
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${dto.userId} not found`);
    }

    await this.ensureBeforeMealMedicationsTaken(
      dto.userId,
      this.normalizeMealTypeForMedication(dto.category),
    );

    const absorptionProfile =
      dto.absorptionProfile ?? AbsorptionProfile.BALANCED;

    // Get current energy state
    const currentState = await this.calculateCurrentEnergyState(dto.userId);

    // Add meal to current volume
    const newVolume = this.energyService.addMealToVolume(
      currentState.volumeRemaining,
      {
        fullnessVolume: dto.fullnessVolume,
        glycemicIndex: dto.absorptionRate,
        absorptionProfile,
        estimatedSatiety: dto.estimatedSatiety,
      },
    );

    // Create the meal log
    const meal = await this.prisma.mealLog.create({
      data: {
        userId: dto.userId,
        foodName: dto.foodName,
        fullnessVolume: dto.fullnessVolume,
        absorptionRate: dto.absorptionRate,
        absorptionProfile,
        estimatedSatiety: dto.estimatedSatiety,
        imageUrl: dto.imageUrl,
        category: dto.category ?? 'other',
        calories: dto.calories,
        protein: dto.protein,
        carbs: dto.carbs,
        fat: dto.fat,
      },
    });

    // Get current activity multiplier
    const activeActivity = await this.getActiveActivity(dto.userId);
    const multiplier = activeActivity?.multiplier ?? 1.0;

    // Calculate energy state after meal
    const energyState = this.energyService.calculateEnergyState(
      newVolume,
      dto.absorptionRate,
      multiplier,
    );

    // Schedule post-meal medication reminders
    await this.schedulePostMealMedicationReminders(
      dto.userId,
      meal.id,
      meal.category,
    );

    return {
      ...meal,
      energyState,
    };
  }

  private async ensureBeforeMealMedicationsTaken(
    userId: string,
    mealType: string,
  ): Promise<void> {
    const requiredMeds = await this.medicationsService.getRequiredBeforeMeal(
      userId,
      mealType,
    );

    if (requiredMeds.length === 0) {
      return;
    }

    const medicationNames = requiredMeds.map((med) => med.name).join(', ');
    throw new ForbiddenException(
      `Please take required medications before logging this meal: ${medicationNames}`,
    );
  }

  private normalizeMealTypeForMedication(category?: string): string {
    const normalized = (category ?? '').toLowerCase();
    if (normalized === 'breakfast' || normalized === 'lunch' || normalized === 'dinner') {
      return normalized;
    }
    return 'any';
  }

  private inferMealCategory(timezone?: string): string {
    const now = new Date();
    const localHour = this.resolveUserHour(now, timezone);

    if (localHour >= 5 && localHour < 11) return 'breakfast';
    if (localHour >= 11 && localHour < 16) return 'lunch';
    if (localHour >= 16 && localHour < 23) return 'dinner';
    return 'other';
  }

  private resolveUserHour(date: Date, timezone?: string): number {
    const safeTimezone = timezone?.trim() || 'UTC';

    try {
      const formatter = new Intl.DateTimeFormat('en-US', {
        timeZone: safeTimezone,
        hour: '2-digit',
        hour12: false,
      });
      const parts = formatter.formatToParts(date);
      const hour = Number(parts.find((part) => part.type === 'hour')?.value);
      if (Number.isInteger(hour) && hour >= 0 && hour <= 23) {
        return hour;
      }
      throw new Error('Failed to parse local hour');
    } catch {
      this.logger.warn(
        `Invalid or unsupported timezone "${safeTimezone}". Using server hour.`,
      );
      return date.getHours();
    }
  }

  /**
   * Get all meals for a user
   */
  async findAllByUser(userId: string) {
    return this.prisma.mealLog.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get a single meal
   */
  async findOne(id: number) {
    const meal = await this.prisma.mealLog.findUnique({
      where: { id },
    });

    if (!meal) {
      throw new NotFoundException(`Meal with ID ${id} not found`);
    }

    return meal;
  }

  /**
   * Delete a meal
   */
  async remove(id: number) {
    await this.findOne(id);

    return this.prisma.mealLog.delete({
      where: { id },
    });
  }

  /**
   * Update a meal
   */
  async update(id: number, dto: UpdateMealDto) {
    await this.findOne(id);

    return this.prisma.mealLog.update({
      where: { id },
      data: dto,
    });
  }

  /**
   * Get today's meals for a user
   */
  async findTodaysMeals(userId: string) {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    return this.prisma.mealLog.findMany({
      where: {
        userId,
        createdAt: {
          gte: startOfDay,
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Calculate current energy state for a user
   * This considers all meals and activity logs
   */
  async calculateCurrentEnergyState(userId: string) {
    const now = new Date();

    // Get recent meals (last 24 hours)
    const recentMeals = await this.prisma.mealLog.findMany({
      where: {
        userId,
        createdAt: {
          gte: new Date(now.getTime() - 24 * 60 * 60 * 1000),
        },
      },
      orderBy: { createdAt: 'asc' },
    });

    // Get activity logs for the period
    const activityLogs = await this.prisma.activityLog.findMany({
      where: {
        userId,
        startTime: {
          gte: new Date(now.getTime() - 24 * 60 * 60 * 1000),
        },
      },
      orderBy: { startTime: 'asc' },
    });

    if (recentMeals.length === 0) {
      // No recent meals, return empty state
      return this.energyService.calculateEnergyState(0, 50, 1.0);
    }

    // Calculate volume by processing each meal and applying drain
    let currentVolume = 0;
    let effectiveGI = 50;
    let lastEventTime = recentMeals[0].createdAt;

    for (const meal of recentMeals) {
      // Apply drain from last event to this meal
      const minutesSinceLastEvent =
        (meal.createdAt.getTime() - lastEventTime.getTime()) / (1000 * 60);

      if (minutesSinceLastEvent > 0) {
        const multiplier = this.getMultiplierForTime(
          activityLogs,
          lastEventTime,
        );
        currentVolume = this.energyService.calculateRemainingVolume({
          startVolume: currentVolume,
          glycemicIndex: effectiveGI,
          activityMultiplier: multiplier,
          elapsedMinutes: minutesSinceLastEvent,
        });
      }

      // Add this meal
      currentVolume = this.energyService.addMealToVolume(currentVolume, {
        fullnessVolume: meal.fullnessVolume,
        glycemicIndex: meal.absorptionRate,
        absorptionProfile: meal.absorptionProfile as any,
        estimatedSatiety: meal.estimatedSatiety,
      });

      effectiveGI = meal.absorptionRate;
      lastEventTime = meal.createdAt;
    }

    // Apply drain from last meal to now
    const minutesSinceLastMeal =
      (now.getTime() - lastEventTime.getTime()) / (1000 * 60);
    const currentMultiplier = this.getMultiplierForTime(activityLogs, now);

    currentVolume = this.energyService.calculateRemainingVolume({
      startVolume: currentVolume,
      glycemicIndex: effectiveGI,
      activityMultiplier: currentMultiplier,
      elapsedMinutes: minutesSinceLastMeal,
    });

    return this.energyService.calculateEnergyState(
      currentVolume,
      effectiveGI,
      currentMultiplier,
    );
  }

  /**
   * Get the activity multiplier that was active at a given time
   */
  private getMultiplierForTime(
    activityLogs: Array<{
      modeType: string;
      multiplier: number;
      startTime: Date;
      endTime: Date | null;
    }>,
    time: Date,
  ): number {
    // Find the activity that was active at the given time
    const activeLog = activityLogs.find(
      (log) =>
        log.startTime <= time && (log.endTime === null || log.endTime >= time),
    );

    return activeLog?.multiplier ?? 1.0; // Default to Resting
  }

  /**
   * Get the currently active activity for a user
   */
  private async getActiveActivity(userId: string) {
    return this.prisma.activityLog.findFirst({
      where: {
        userId,
        endTime: null,
      },
      orderBy: { startTime: 'desc' },
    });
  }

  /**
   * Schedule post-meal medication reminders
   * Schedules notifications for medications that should be taken after a meal
   */
  private async schedulePostMealMedicationReminders(
    userId: string,
    mealId: number,
    mealType: string,
  ): Promise<void> {
    try {
      const medications =
        await this.medicationsService.getRequiredAfterMeal(userId, mealType);

      if (medications.length === 0) return;

      // Schedule reminders 30 minutes after meal
      const reminderTime = new Date(Date.now() + 30 * 60 * 1000);
      const normalizedMealType = this.normalizeMealTypeForMedication(mealType);

      for (const medication of medications) {
        await this.prisma.notification.create({
          data: {
            userId,
            type: 'medication_reminder',
            title: '💊 Medication Reminder',
            body: `Time to take ${medication.name}${medication.dosage ? ` (${medication.dosage})` : ''} after your meal`,
            status: 'scheduled',
            scheduledFor: reminderTime,
            data: {
              medicationId: medication.id,
              medicationName: medication.name,
              mealId,
              timing: 'after',
              mealType: normalizedMealType,
              action: 'log_medication',
            },
          },
        });
      }

      this.logger.log(
        `Scheduled ${medications.length} post-meal medication reminders for user ${userId}`,
      );
    } catch (error) {
      this.logger.error('Error scheduling post-meal medication reminders', error);
    }
  }
}
