import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { PrismaService } from '../prisma/prisma.service';

export interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

@Injectable()
export class NotificationsService implements OnModuleInit {
  private readonly logger = new Logger(NotificationsService.name);
  private firebaseInitialized = false;

  constructor(private prisma: PrismaService) {}

  onModuleInit() {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
    
    if (!serviceAccount) {
      this.logger.warn('FIREBASE_SERVICE_ACCOUNT not configured. Push notifications disabled.');
      return;
    }

    try {
      const credentials = JSON.parse(serviceAccount);
      admin.initializeApp({
        credential: admin.credential.cert(credentials),
      });
      this.firebaseInitialized = true;
      this.logger.log('Firebase Admin SDK initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize Firebase Admin SDK', error);
    }
  }

  isReady(): boolean {
    return this.firebaseInitialized;
  }

  /**
   * Send push notification to a specific user
   */
  async sendToUser(
    userId: string,
    payload: NotificationPayload,
    type: string = 'general',
  ): Promise<boolean> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true, notifyOnLowEnergy: true, notifyMealReminders: true },
    });

    if (!user?.fcmToken) {
      this.logger.debug(`User ${userId} has no FCM token`);
      return false;
    }

    // Check notification preferences
    if (type === 'energy_alert' && !user.notifyOnLowEnergy) {
      return false;
    }
    if (type === 'meal_reminder' && !user.notifyMealReminders) {
      return false;
    }

    return this.sendToToken(userId, user.fcmToken, payload, type);
  }

  /**
   * Send push notification to a specific FCM token
   */
  async sendToToken(
    userId: string,
    token: string,
    payload: NotificationPayload,
    type: string = 'general',
  ): Promise<boolean> {
    if (!this.firebaseInitialized) {
      this.logger.warn('Firebase not initialized, cannot send notification');
      return false;
    }

    try {
      const message: admin.messaging.Message = {
        token,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data || {},
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'fuelflow_alerts',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      await admin.messaging().send(message);
      
      // Save to notification history
      await this.prisma.notification.create({
        data: {
          userId,
          type,
          title: payload.title,
          body: payload.body,
          data: payload.data,
        },
      });

      this.logger.log(`Notification sent to user ${userId}: ${payload.title}`);
      return true;
    } catch (error: any) {
      this.logger.error(`Failed to send notification: ${error.message}`);
      
      // If token is invalid, clear it
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        await this.prisma.user.update({
          where: { id: userId },
          data: { fcmToken: null },
        });
        this.logger.warn(`Cleared invalid FCM token for user ${userId}`);
      }
      
      return false;
    }
  }

  /**
   * Send energy alert notification
   */
  async sendEnergyAlert(
    userId: string,
    currentEnergy: number,
    etcMinutes: number | null,
  ): Promise<boolean> {
    const payload: NotificationPayload = {
      title: '⚡ Low Energy Alert',
      body: etcMinutes
        ? `Your energy is at ${currentEnergy.toFixed(0)}%. You'll hit critical in ~${etcMinutes} minutes.`
        : `Your energy is at ${currentEnergy.toFixed(0)}%. Time to refuel!`,
      data: {
        type: 'energy_alert',
        energy: currentEnergy.toString(),
        etcMinutes: etcMinutes?.toString() || '',
      },
    };

    const sent = await this.sendToUser(userId, payload, 'energy_alert');
    
    if (sent) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { lastAlertAt: new Date() },
      });
    }

    return sent;
  }

  /**
   * Send meal reminder notification
   */
  async sendMealReminder(userId: string): Promise<boolean> {
    const payload: NotificationPayload = {
      title: '🍽️ Meal Reminder',
      body: "Haven't logged a meal in a while. Keep your energy log up to date!",
      data: {
        type: 'meal_reminder',
        action: 'log_meal',
      },
    };

    return this.sendToUser(userId, payload, 'meal_reminder');
  }

  /**
   * Get notification history for a user
   */
  async getHistory(userId: string, limit: number = 50) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { sentAt: 'desc' },
      take: limit,
    });
  }

  /**
   * Mark notification as read
   */
  async markAsRead(userId: string, notificationId: number) {
    return this.prisma.notification.updateMany({
      where: { id: notificationId, userId },
      data: { read: true },
    });
  }

  /**
   * Mark all notifications as read
   */
  async markAllAsRead(userId: string) {
    return this.prisma.notification.updateMany({
      where: { userId, read: false },
      data: { read: true },
    });
  }

  /**
   * Get unread count
   */
  async getUnreadCount(userId: string): Promise<number> {
    return this.prisma.notification.count({
      where: { userId, read: false },
    });
  }

  /**
   * Update user notification preferences
   */
  async updatePreferences(
    userId: string,
    preferences: {
      notifyOnLowEnergy?: boolean;
      notifyMealReminders?: boolean;
      mealReminderInterval?: number;
    },
  ) {
    return this.prisma.user.update({
      where: { id: userId },
      data: preferences,
      select: {
        notifyOnLowEnergy: true,
        notifyMealReminders: true,
        mealReminderInterval: true,
      },
    });
  }

  /**
   * Get user notification preferences
   */
  async getPreferences(userId: string) {
    return this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        notifyOnLowEnergy: true,
        notifyMealReminders: true,
        mealReminderInterval: true,
      },
    });
  }
}
