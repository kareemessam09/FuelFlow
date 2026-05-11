import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  ParseIntPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { CustomActivitiesService } from './custom-activities.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { CurrentUserType } from '../auth/decorators/current-user.decorator';
import {
  CreateCustomActivityDto,
  CreateActivityGoalDto,
} from './dto/create-custom-activity.dto';
import {
  UpdateCustomActivityDto,
  UpdateActivityGoalDto,
} from './dto/update-custom-activity.dto';

@Controller('custom-activities')
@UseGuards(JwtAuthGuard)
export class CustomActivitiesController {
  constructor(
    private readonly customActivitiesService: CustomActivitiesService,
  ) {}

  // ============================================
  // CUSTOM ACTIVITIES
  // ============================================

  /**
   * Get all activities (built-in + custom)
   */
  @Get('all')
  getAllActivities(@CurrentUser() user: CurrentUserType) {
    return this.customActivitiesService.getAllActivities(user.userId);
  }

  @Post()
  createCustomActivity(
    @CurrentUser() user: CurrentUserType,
    @Body() dto: CreateCustomActivityDto,
  ) {
    return this.customActivitiesService.createCustomActivity(user.userId, dto);
  }

  @Get()
  getCustomActivities(@CurrentUser() user: CurrentUserType) {
    return this.customActivitiesService.getCustomActivities(user.userId);
  }

  @Get(':id')
  getCustomActivity(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.customActivitiesService.getCustomActivity(user.userId, id);
  }

  @Patch(':id')
  updateCustomActivity(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateCustomActivityDto,
  ) {
    return this.customActivitiesService.updateCustomActivity(
      user.userId,
      id,
      dto,
    );
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteCustomActivity(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.customActivitiesService.deleteCustomActivity(user.userId, id);
  }

  // ============================================
  // ACTIVITY GOALS
  // ============================================

  @Post('goals')
  createActivityGoal(
    @CurrentUser() user: CurrentUserType,
    @Body() dto: CreateActivityGoalDto,
  ) {
    return this.customActivitiesService.createActivityGoal(user.userId, dto);
  }

  @Get('goals')
  getActivityGoals(@CurrentUser() user: CurrentUserType) {
    return this.customActivitiesService.getActivityGoals(user.userId);
  }

  @Get('goals/progress')
  getGoalProgress(@CurrentUser() user: CurrentUserType) {
    return this.customActivitiesService.getGoalProgress(user.userId);
  }

  @Get('goals/:id')
  getActivityGoal(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.customActivitiesService.getActivityGoal(user.userId, id);
  }

  @Patch('goals/:id')
  updateActivityGoal(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateActivityGoalDto,
  ) {
    return this.customActivitiesService.updateActivityGoal(
      user.userId,
      id,
      dto,
    );
  }

  @Delete('goals/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteActivityGoal(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.customActivitiesService.deleteActivityGoal(user.userId, id);
  }
}
