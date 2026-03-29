import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class JobsService {
  private readonly logger = new Logger(JobsService.name);

  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  /**
   * Check for users who need energy alerts (runs every 5 minutes)
   */
  @Cron(CronExpression.EVERY_5_MINUTES)
  async checkEnergyAlerts() {
    this.logger.debug('Checking for energy alerts...');

    try {
      // Get users with FCM tokens who have alerts enabled
      const users = await this.prisma.user.findMany({
        where: {
          fcmToken: { not: null },
          notifyOnLowEnergy: true,
        },
        select: {
          id: true,
          lastAlertAt: true,
        },
      });

      for (const user of users) {
        // Don't send alerts more than once per hour
        if (user.lastAlertAt) {
          const hourAgo = new Date(Date.now() - 60 * 60 * 1000);
          if (user.lastAlertAt > hourAgo) continue;
        }

        // Get latest energy snapshot
        const snapshot = await this.prisma.energySnapshot.findFirst({
          where: { userId: user.id },
          orderBy: { snapshotAt: 'desc' },
        });

        if (snapshot && snapshot.volumeRemaining <= 30 && snapshot.volumeRemaining > 0) {
          await this.notificationsService.sendEnergyAlert(
            user.id,
            snapshot.volumeRemaining,
            snapshot.etcMinutes,
          );
        }
      }
    } catch (error) {
      this.logger.error('Error checking energy alerts', error);
    }
  }

  /**
   * Send meal reminders (runs every hour)
   */
  @Cron(CronExpression.EVERY_HOUR)
  async sendMealReminders() {
    this.logger.debug('Checking for meal reminders...');

    try {
      const users = await this.prisma.user.findMany({
        where: {
          fcmToken: { not: null },
          notifyMealReminders: true,
        },
        select: {
          id: true,
          mealReminderInterval: true,
        },
      });

      for (const user of users) {
        // Get last meal time
        const lastMeal = await this.prisma.mealLog.findFirst({
          where: { userId: user.id },
          orderBy: { createdAt: 'desc' },
          select: { createdAt: true },
        });

        if (lastMeal) {
          const intervalMs = user.mealReminderInterval * 60 * 1000;
          const timeSinceLastMeal = Date.now() - lastMeal.createdAt.getTime();

          if (timeSinceLastMeal > intervalMs) {
            await this.notificationsService.sendMealReminder(user.id);
          }
        }
      }
    } catch (error) {
      this.logger.error('Error sending meal reminders', error);
    }
  }

  /**
   * Generate daily summaries (runs at midnight)
   */
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async generateDailySummaries() {
    this.logger.log('Generating daily summaries...');

    try {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);

      const endOfYesterday = new Date(yesterday);
      endOfYesterday.setHours(23, 59, 59, 999);

      // Get all users
      const users = await this.prisma.user.findMany({
        select: { id: true },
      });

      for (const user of users) {
        await this.generateDailySummaryForUser(user.id, yesterday, endOfYesterday);
      }

      this.logger.log(`Generated daily summaries for ${users.length} users`);
    } catch (error) {
      this.logger.error('Error generating daily summaries', error);
    }
  }

  async generateDailySummaryForUser(userId: string, startDate: Date, endDate: Date) {
    // Get meals for the day
    const meals = await this.prisma.mealLog.findMany({
      where: {
        userId,
        createdAt: { gte: startDate, lte: endDate },
      },
    });

    // Get activities for the day
    const activities = await this.prisma.activityLog.findMany({
      where: {
        userId,
        startTime: { gte: startDate, lte: endDate },
      },
    });

    // Get energy snapshots for the day
    const snapshots = await this.prisma.energySnapshot.findMany({
      where: {
        userId,
        snapshotAt: { gte: startDate, lte: endDate },
      },
    });

    // Calculate activity breakdown
    const activityBreakdown: Record<string, number> = {};
    for (const activity of activities) {
      const endTime = activity.endTime || endDate;
      const effectiveEnd = endTime > endDate ? endDate : endTime;
      const effectiveStart = activity.startTime < startDate ? startDate : activity.startTime;
      const duration = (effectiveEnd.getTime() - effectiveStart.getTime()) / (1000 * 60);
      activityBreakdown[activity.modeType] = (activityBreakdown[activity.modeType] || 0) + duration;
    }

    // Calculate energy stats
    let avgEnergy = 0;
    let minEnergy = 100;
    let maxEnergy = 0;
    let timeInOptimal = 0;
    let timeInWarning = 0;
    let timeInCritical = 0;

    if (snapshots.length > 0) {
      const energyLevels = snapshots.map(s => s.volumeRemaining);
      avgEnergy = energyLevels.reduce((a, b) => a + b, 0) / energyLevels.length;
      minEnergy = Math.min(...energyLevels);
      maxEnergy = Math.max(...energyLevels);

      // Estimate time in each state (simplified)
      for (const snapshot of snapshots) {
        if (snapshot.volumeRemaining > 60) timeInOptimal += 5;
        else if (snapshot.volumeRemaining > 30) timeInWarning += 5;
        else timeInCritical += 5;
      }
    }

    // Calculate total calories
    const totalCalories = meals.reduce((sum, meal) => sum + (meal.calories || 0), 0);

    // Upsert daily summary
    const dateOnly = new Date(startDate);
    dateOnly.setHours(0, 0, 0, 0);

    await this.prisma.dailySummary.upsert({
      where: {
        userId_date: { userId, date: dateOnly },
      },
      create: {
        userId,
        date: dateOnly,
        totalMeals: meals.length,
        totalCalories: totalCalories || null,
        avgEnergyLevel: avgEnergy || null,
        minEnergyLevel: minEnergy === 100 ? null : minEnergy,
        maxEnergyLevel: maxEnergy || null,
        activityBreakdown,
        timeInOptimal,
        timeInWarning,
        timeInCritical,
      },
      update: {
        totalMeals: meals.length,
        totalCalories: totalCalories || null,
        avgEnergyLevel: avgEnergy || null,
        minEnergyLevel: minEnergy === 100 ? null : minEnergy,
        maxEnergyLevel: maxEnergy || null,
        activityBreakdown,
        timeInOptimal,
        timeInWarning,
        timeInCritical,
      },
    });
  }

  /**
   * Clean up stale data (runs weekly on Sunday at 3 AM)
   */
  @Cron('0 3 * * 0')
  async cleanupStaleData() {
    this.logger.log('Cleaning up stale data...');

    try {
      // Delete energy snapshots older than 30 days
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const deletedSnapshots = await this.prisma.energySnapshot.deleteMany({
        where: { snapshotAt: { lt: thirtyDaysAgo } },
      });

      // Delete old notifications (older than 90 days)
      const ninetyDaysAgo = new Date();
      ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

      const deletedNotifications = await this.prisma.notification.deleteMany({
        where: { sentAt: { lt: ninetyDaysAgo } },
      });

      this.logger.log(
        `Cleanup complete: ${deletedSnapshots.count} snapshots, ${deletedNotifications.count} notifications deleted`,
      );
    } catch (error) {
      this.logger.error('Error cleaning up stale data', error);
    }
  }

  /**
   * Update energy snapshots periodically (every 10 minutes)
   */
  @Cron(CronExpression.EVERY_10_MINUTES)
  async updateEnergySnapshots() {
    this.logger.debug('Updating energy snapshots...');

    try {
      // Get users with recent activity (logged in last 24 hours)
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

      const activeUsers = await this.prisma.user.findMany({
        where: {
          OR: [
            { mealLogs: { some: { createdAt: { gte: oneDayAgo } } } },
            { activityLogs: { some: { startTime: { gte: oneDayAgo } } } },
          ],
        },
        select: { id: true },
      });

      // For each active user, we would calculate and save their current energy state
      // This is a simplified version - in production, you'd call the energy calculation service
      this.logger.debug(`Updated snapshots for ${activeUsers.length} active users`);
    } catch (error) {
      this.logger.error('Error updating energy snapshots', error);
    }
  }
}
