import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  ParseIntPipe,
  Query,
  HttpCode,
  HttpStatus,
  UseGuards,
} from '@nestjs/common';
import { MedicationsService } from './medications.service';
import { CreateMedicationDto } from './dto/create-medication.dto';
import { UpdateMedicationDto } from './dto/update-medication.dto';
import { LogMedicationDto } from './dto/log-medication.dto';
import { CreateMedicationScheduleDto } from './dto/create-medication-schedule.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { CurrentUserType } from '../auth/decorators/current-user.decorator';

@Controller('medications')
@UseGuards(JwtAuthGuard)
export class MedicationsController {
  constructor(private readonly medicationsService: MedicationsService) {}

  /**
   * POST /api/medications
   * Create a new medication
   */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @CurrentUser() user: CurrentUserType,
    @Body() createDto: CreateMedicationDto,
  ) {
    return this.medicationsService.create(user.userId, createDto);
  }

  /**
   * GET /api/medications
   * Get all medications for the current user
   */
  @Get()
  async findAll(@CurrentUser() user: CurrentUserType) {
    return this.medicationsService.findAll(user.userId);
  }

  /**
   * PATCH /api/medications/:id
   * Update a medication
   */
  @Patch(':id')
  async update(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
    @Body() updateDto: UpdateMedicationDto,
  ) {
    return this.medicationsService.update(user.userId, id, updateDto);
  }

  /**
   * DELETE /api/medications/:id
   * Delete a medication
   */
  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  async remove(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.medicationsService.remove(user.userId, id);
  }

  /**
   * POST /api/medications/logs
   * Log that a medication was taken
   */
  @Post('logs')
  @HttpCode(HttpStatus.CREATED)
  async logMedication(
    @CurrentUser() user: CurrentUserType,
    @Body() logDto: LogMedicationDto,
  ) {
    return this.medicationsService.logMedication(user.userId, logDto);
  }

  /**
   * GET /api/medications/logs/today
   * Get today's medication logs
   */
  @Get('logs/today')
  async getTodayLogs(@CurrentUser() user: CurrentUserType) {
    return this.medicationsService.getTodayLogs(user.userId);
  }

  /**
   * GET /api/medications/logs/history
   * Get medication logs with optional date filtering
   */
  @Get('logs/history')
  async getHistory(
    @CurrentUser() user: CurrentUserType,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const start = startDate ? new Date(startDate) : undefined;
    const end = endDate ? new Date(endDate) : undefined;
    return this.medicationsService.getMedicationLogs(user.userId, start, end);
  }

  /**
   * GET /api/medications/check-before-meal
   * Check if any medications are required before logging a meal
   * Returns medications that need to be taken before the specified meal type
   */
  @Get('check-before-meal')
  async checkBeforeMeal(
    @CurrentUser() user: CurrentUserType,
    @Query('mealType') mealType: string = 'any',
  ) {
    const required = await this.medicationsService.getRequiredBeforeMeal(
      user.userId,
      mealType,
    );

    return {
      hasRequiredMedications: required.length > 0,
      medications: required,
      message:
        required.length > 0
          ? 'Please take your medications before logging this meal'
          : 'No medications required before this meal',
    };
  }

  /**
   * GET /api/medications/after-meal
   * Get medications that should be taken after a specific meal type
   * Used to schedule post-meal reminders
   */
  @Get('after-meal')
  async getAfterMeal(
    @CurrentUser() user: CurrentUserType,
    @Query('mealType') mealType: string = 'any',
  ) {
    return this.medicationsService.getRequiredAfterMeal(user.userId, mealType);
  }

  /**
   * POST /api/medications/schedules
   * Create a medication reminder schedule
   */
  @Post('schedules')
  @HttpCode(HttpStatus.CREATED)
  async createSchedule(
    @CurrentUser() user: CurrentUserType,
    @Body() createDto: CreateMedicationScheduleDto,
  ) {
    return this.medicationsService.createSchedule(user.userId, createDto);
  }

  /**
   * GET /api/medications/schedules
   * Get all medication schedules for the current user
   */
  @Get('schedules')
  async getSchedules(@CurrentUser() user: CurrentUserType) {
    return this.medicationsService.getSchedules(user.userId);
  }

  /**
   * GET /api/medications/:id
   * Get a single medication by ID
   *
   * NOTE: keep this route after all static GET routes to avoid
   * collisions with endpoints like "check-before-meal" and "after-meal".
   */
  @Get(':id')
  async findOne(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.medicationsService.findOne(user.userId, id);
  }

  /**
   * PATCH /api/medications/schedules/:id
   * Update a medication schedule
   */
  @Patch('schedules/:id')
  async updateSchedule(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
    @Body() updateData: Partial<CreateMedicationScheduleDto>,
  ) {
    return this.medicationsService.updateSchedule(user.userId, id, updateData);
  }

  /**
   * DELETE /api/medications/schedules/:id
   * Delete a medication schedule
   */
  @Delete('schedules/:id')
  @HttpCode(HttpStatus.OK)
  async deleteSchedule(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.medicationsService.deleteSchedule(user.userId, id);
  }
}
