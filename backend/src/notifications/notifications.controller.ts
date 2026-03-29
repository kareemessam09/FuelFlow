import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { CurrentUserType } from '../auth/decorators/current-user.decorator';
import { UpdateNotificationPreferencesDto } from './dto/update-preferences.dto';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  /**
   * Get notification history
   */
  @Get()
  async getHistory(
    @CurrentUser() user: CurrentUserType,
    @Query('limit') limit?: string,
  ) {
    const limitNum = limit ? parseInt(limit, 10) : 50;
    return this.notificationsService.getHistory(user.userId, limitNum);
  }

  /**
   * Get unread notification count
   */
  @Get('unread-count')
  async getUnreadCount(@CurrentUser() user: CurrentUserType) {
    const count = await this.notificationsService.getUnreadCount(user.userId);
    return { count };
  }

  /**
   * Get notification preferences
   */
  @Get('preferences')
  async getPreferences(@CurrentUser() user: CurrentUserType) {
    return this.notificationsService.getPreferences(user.userId);
  }

  /**
   * Update notification preferences
   */
  @Patch('preferences')
  async updatePreferences(
    @CurrentUser() user: CurrentUserType,
    @Body() dto: UpdateNotificationPreferencesDto,
  ) {
    return this.notificationsService.updatePreferences(user.userId, dto);
  }

  /**
   * Mark a notification as read
   */
  @Patch(':id/read')
  async markAsRead(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    await this.notificationsService.markAsRead(user.userId, id);
    return { message: 'Notification marked as read' };
  }

  /**
   * Mark all notifications as read
   */
  @Post('mark-all-read')
  async markAllAsRead(@CurrentUser() user: CurrentUserType) {
    await this.notificationsService.markAllAsRead(user.userId);
    return { message: 'All notifications marked as read' };
  }
}
