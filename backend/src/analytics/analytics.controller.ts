import {
  Controller,
  Get,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { CurrentUserType } from '../auth/decorators/current-user.decorator';

@Controller('analytics')
@UseGuards(JwtAuthGuard)
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  /**
   * Get weekly energy report
   */
  @Get('weekly')
  async getWeeklyReport(
    @CurrentUser() user: CurrentUserType,
    @Query('weeksAgo') weeksAgo?: string,
  ) {
    const weeks = weeksAgo ? parseInt(weeksAgo, 10) : 0;
    return this.analyticsService.getWeeklyReport(user.userId, weeks);
  }

  /**
   * Get monthly energy report
   */
  @Get('monthly')
  async getMonthlyReport(
    @CurrentUser() user: CurrentUserType,
    @Query('monthsAgo') monthsAgo?: string,
  ) {
    const months = monthsAgo ? parseInt(monthsAgo, 10) : 0;
    return this.analyticsService.getMonthlyReport(user.userId, months);
  }

  /**
   * Get meal statistics
   */
  @Get('meals')
  async getMealStats(
    @CurrentUser() user: CurrentUserType,
    @Query('days') days?: string,
  ) {
    const numDays = days ? parseInt(days, 10) : 7;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - numDays);
    return this.analyticsService.getMealStats(user.userId, startDate, new Date());
  }

  /**
   * Get activity statistics
   */
  @Get('activities')
  async getActivityStats(
    @CurrentUser() user: CurrentUserType,
    @Query('days') days?: string,
  ) {
    const numDays = days ? parseInt(days, 10) : 7;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - numDays);
    return this.analyticsService.getActivityStats(user.userId, startDate, new Date());
  }

  /**
   * Get goal progress
   */
  @Get('goal-progress')
  async getGoalProgress(
    @CurrentUser() user: CurrentUserType,
    @Query('days') days?: string,
  ) {
    const numDays = days ? parseInt(days, 10) : 7;
    return this.analyticsService.getGoalProgress(user.userId, numDays);
  }

  /**
   * Export all user data as JSON
   */
  @Get('export/json')
  async exportJSON(@CurrentUser() user: CurrentUserType) {
    return this.analyticsService.exportUserData(user.userId);
  }

  /**
   * Export meals as CSV
   */
  @Get('export/meals/csv')
  async exportMealsCSV(
    @CurrentUser() user: CurrentUserType,
    @Res() res: Response,
  ) {
    const data = await this.analyticsService.exportMealsCSV(user.userId);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=fuelflow-meals.csv');
    res.send(data.csv);
  }

  /**
   * Export activities as CSV
   */
  @Get('export/activities/csv')
  async exportActivitiesCSV(
    @CurrentUser() user: CurrentUserType,
    @Res() res: Response,
  ) {
    const data = await this.analyticsService.exportActivitiesCSV(user.userId);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=fuelflow-activities.csv');
    res.send(data.csv);
  }
}
