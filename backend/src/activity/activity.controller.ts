import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { ActivityService } from './activity.service';
import { ToggleActivityDto } from './dto/create-activity.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { CurrentUserType } from '../auth/decorators/current-user.decorator';

@Controller('activity')
@UseGuards(JwtAuthGuard)
export class ActivityController {
  constructor(private readonly activityService: ActivityService) {}

  /**
   * POST /api/activity/toggle
   * Toggle activity mode (e.g., Resting -> Studying)
   * Closes the previous activity and starts a new one
   * userId is extracted from JWT token
   */
  @Post('toggle')
  @HttpCode(HttpStatus.OK)
  toggle(
    @CurrentUser() user: CurrentUserType,
    @Body() toggleDto: Omit<ToggleActivityDto, 'userId'>,
  ) {
    return this.activityService.toggle({
      ...toggleDto,
      userId: user.userId,
    });
  }

  /**
   * GET /api/activity/status
   * Get current activity status and energy state for authenticated user
   */
  @Get('status')
  getCurrentStatus(@CurrentUser() user: CurrentUserType) {
    return this.activityService.getCurrentStatus(user.userId);
  }

  /**
   * GET /api/activity/history
   * Get activity history for authenticated user
   */
  @Get('history')
  getHistory(
    @CurrentUser() user: CurrentUserType,
    @Query('limit') limit?: string,
  ) {
    return this.activityService.getHistory(user.userId, limit ? parseInt(limit) : 20);
  }

  /**
   * GET /api/activity/summary
   * Get today's activity summary for authenticated user
   */
  @Get('summary')
  getTodaySummary(@CurrentUser() user: CurrentUserType) {
    return this.activityService.getTodaySummary(user.userId);
  }

  /**
   * POST /api/activity/end
   * End current activity and return to Resting mode
   */
  @Post('end')
  @HttpCode(HttpStatus.OK)
  endCurrentActivity(@CurrentUser() user: CurrentUserType) {
    return this.activityService.endCurrentActivity(user.userId);
  }
}
