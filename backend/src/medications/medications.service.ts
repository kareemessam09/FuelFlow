import {
  Injectable,
  NotFoundException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMedicationDto } from './dto/create-medication.dto';
import { UpdateMedicationDto } from './dto/update-medication.dto';
import { LogMedicationDto } from './dto/log-medication.dto';
import { CreateMedicationScheduleDto } from './dto/create-medication-schedule.dto';

@Injectable()
export class MedicationsService {
  private readonly logger = new Logger(MedicationsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new medication for a user
   */
  async create(userId: string, createDto: CreateMedicationDto) {
    // Check if medication with same name already exists for this user
    const existing = await this.prisma.medication.findUnique({
      where: {
        userId_name: {
          userId,
          name: createDto.name,
        },
      },
    });

    if (existing) {
      throw new ConflictException(
        `Medication "${createDto.name}" already exists`,
      );
    }

    const medication = await this.prisma.medication.create({
      data: {
        userId,
        ...createDto,
      },
      include: {
        schedules: true,
      },
    });

    this.logger.log(
      `Created medication "${medication.name}" for user ${userId}`,
    );

    return medication;
  }

  /**
   * Get all medications for a user
   */
  async findAll(userId: string) {
    return this.prisma.medication.findMany({
      where: { userId },
      include: {
        schedules: true,
        logs: {
          orderBy: { takenAt: 'desc' },
          take: 5, // Last 5 logs per medication
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get a single medication by ID
   */
  async findOne(userId: string, id: number) {
    const medication = await this.prisma.medication.findFirst({
      where: { id, userId },
      include: {
        schedules: true,
        logs: {
          orderBy: { takenAt: 'desc' },
          take: 10,
        },
      },
    });

    if (!medication) {
      throw new NotFoundException(`Medication with ID ${id} not found`);
    }

    return medication;
  }

  /**
   * Update a medication
   */
  async update(userId: string, id: number, updateDto: UpdateMedicationDto) {
    // Verify ownership
    const medication = await this.prisma.medication.findFirst({
      where: { id, userId },
    });

    if (!medication) {
      throw new NotFoundException(`Medication with ID ${id} not found`);
    }

    // Check for name conflict if name is being changed
    if (updateDto.name && updateDto.name !== medication.name) {
      const conflict = await this.prisma.medication.findUnique({
        where: {
          userId_name: {
            userId,
            name: updateDto.name,
          },
        },
      });

      if (conflict) {
        throw new ConflictException(
          `Medication "${updateDto.name}" already exists`,
        );
      }
    }

    const updated = await this.prisma.medication.update({
      where: { id },
      data: updateDto,
      include: {
        schedules: true,
      },
    });

    this.logger.log(`Updated medication ${id} for user ${userId}`);

    return updated;
  }

  /**
   * Delete a medication
   */
  async remove(userId: string, id: number) {
    // Verify ownership
    const medication = await this.prisma.medication.findFirst({
      where: { id, userId },
    });

    if (!medication) {
      throw new NotFoundException(`Medication with ID ${id} not found`);
    }

    await this.prisma.medication.delete({
      where: { id },
    });

    this.logger.log(`Deleted medication ${id} for user ${userId}`);

    return { success: true, message: 'Medication deleted' };
  }

  /**
   * Log that a medication was taken
   */
  async logMedication(userId: string, logDto: LogMedicationDto) {
    // Verify medication exists and belongs to user
    const medication = await this.prisma.medication.findFirst({
      where: {
        id: logDto.medicationId,
        userId,
      },
    });

    if (!medication) {
      throw new NotFoundException(
        `Medication with ID ${logDto.medicationId} not found`,
      );
    }

    // Verify meal if mealId provided
    if (logDto.mealId) {
      const meal = await this.prisma.mealLog.findFirst({
        where: {
          id: logDto.mealId,
          userId,
        },
      });

      if (!meal) {
        throw new NotFoundException(`Meal with ID ${logDto.mealId} not found`);
      }
    }

    const log = await this.prisma.medicationLog.create({
      data: {
        userId,
        medicationId: logDto.medicationId,
        mealId: logDto.mealId,
        takenAt: logDto.takenAt ? new Date(logDto.takenAt) : new Date(),
        notes: logDto.notes,
      },
      include: {
        medication: true,
        meal: true,
      },
    });

    this.logger.log(`Logged medication ${medication.name} for user ${userId}`);

    return log;
  }

  /**
   * Get medication logs for a user (optionally filtered by date)
   */
  async getMedicationLogs(userId: string, startDate?: Date, endDate?: Date) {
    const where: any = { userId };

    if (startDate || endDate) {
      where.takenAt = {};
      if (startDate) where.takenAt.gte = startDate;
      if (endDate) where.takenAt.lte = endDate;
    }

    return this.prisma.medicationLog.findMany({
      where,
      include: {
        medication: true,
        meal: true,
      },
      orderBy: { takenAt: 'desc' },
    });
  }

  /**
   * Get medications required before a specific meal type
   * Used to check if user needs to take meds before logging meal
   */
  async getRequiredBeforeMeal(userId: string, mealType: string) {
    const medications = await this.prisma.medication.findMany({
      where: {
        userId,
        timing: 'before',
        OR: [{ mealType }, { mealType: 'any' }],
        reminderEnabled: true,
      },
    });

    // Check which ones haven't been taken today
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const notTakenToday = [];

    for (const med of medications) {
      const log = await this.prisma.medicationLog.findFirst({
        where: {
          medicationId: med.id,
          userId,
          takenAt: {
            gte: today,
          },
        },
      });

      if (!log) {
        notTakenToday.push(med);
      }
    }

    return notTakenToday;
  }

  /**
   * Get medications that should be taken after a meal
   * Used to schedule post-meal reminders
   */
  async getRequiredAfterMeal(userId: string, mealType: string) {
    return this.prisma.medication.findMany({
      where: {
        userId,
        timing: 'after',
        OR: [{ mealType }, { mealType: 'any' }],
        reminderEnabled: true,
      },
    });
  }

  /**
   * Create a medication reminder schedule
   */
  async createSchedule(userId: string, createDto: CreateMedicationScheduleDto) {
    // Verify medication exists and belongs to user
    const medication = await this.prisma.medication.findFirst({
      where: {
        id: createDto.medicationId,
        userId,
      },
    });

    if (!medication) {
      throw new NotFoundException(
        `Medication with ID ${createDto.medicationId} not found`,
      );
    }

    // Convert daysOfWeek array to comma-separated string
    const daysOfWeekStr = createDto.daysOfWeek.sort().join(',');

    const schedule = await this.prisma.medicationSchedule.create({
      data: {
        userId,
        medicationId: createDto.medicationId,
        daysOfWeek: daysOfWeekStr,
        time: createDto.time,
        enabled: createDto.enabled ?? true,
      },
      include: {
        medication: true,
      },
    });

    this.logger.log(
      `Created schedule for medication ${medication.name} (${createDto.time} on days ${daysOfWeekStr})`,
    );

    return schedule;
  }

  /**
   * Get all medication schedules for a user
   */
  async getSchedules(userId: string) {
    return this.prisma.medicationSchedule.findMany({
      where: { userId },
      include: {
        medication: true,
      },
      orderBy: { time: 'asc' },
    });
  }

  /**
   * Update a medication schedule
   */
  async updateSchedule(
    userId: string,
    id: number,
    updateData: Partial<CreateMedicationScheduleDto>,
  ) {
    const schedule = await this.prisma.medicationSchedule.findFirst({
      where: { id, userId },
    });

    if (!schedule) {
      throw new NotFoundException(`Schedule with ID ${id} not found`);
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const data: any = {};
    if (updateData.daysOfWeek) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
      data.daysOfWeek = updateData.daysOfWeek.sort().join(',');
    }
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    if (updateData.time) data.time = updateData.time;
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    if (updateData.enabled !== undefined) data.enabled = updateData.enabled;

    return this.prisma.medicationSchedule.update({
      where: { id },
      data,
      include: {
        medication: true,
      },
    });
  }

  /**
   * Delete a medication schedule
   */
  async deleteSchedule(userId: string, id: number) {
    const schedule = await this.prisma.medicationSchedule.findFirst({
      where: { id, userId },
    });

    if (!schedule) {
      throw new NotFoundException(`Schedule with ID ${id} not found`);
    }

    await this.prisma.medicationSchedule.delete({
      where: { id },
    });

    return { success: true, message: 'Schedule deleted' };
  }

  /**
   * Get today's medication logs for a user
   */
  async getTodayLogs(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    return this.prisma.medicationLog.findMany({
      where: {
        userId,
        takenAt: {
          gte: today,
          lt: tomorrow,
        },
      },
      include: {
        medication: true,
        meal: true,
      },
      orderBy: { takenAt: 'desc' },
    });
  }
}
