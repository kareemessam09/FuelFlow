import { Test, TestingModule } from '@nestjs/testing';
import { JobsService } from './jobs.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { MedicationsService } from '../medications/medications.service';

describe('JobsService', () => {
  let service: JobsService;
  let prismaMock: {
    notification: {
      findMany: jest.Mock;
      update: jest.Mock;
      findFirst: jest.Mock;
    };
    medicationSchedule: {
      findMany: jest.Mock;
    };
  };
  let notificationsMock: {
    sendToToken: jest.Mock;
    sendMedicationReminder: jest.Mock;
  };

  beforeEach(async () => {
    prismaMock = {
      notification: {
        findMany: jest.fn(),
        update: jest.fn(),
        findFirst: jest.fn(),
      },
      medicationSchedule: {
        findMany: jest.fn(),
      },
    };

    notificationsMock = {
      sendToToken: jest.fn(),
      sendMedicationReminder: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        JobsService,
        {
          provide: PrismaService,
          useValue: prismaMock,
        },
        {
          provide: NotificationsService,
          useValue: notificationsMock,
        },
        {
          provide: MedicationsService,
          useValue: {},
        },
      ],
    }).compile();

    service = module.get<JobsService>(JobsService);
  });

  describe('processScheduledNotifications', () => {
    it('calls sendToToken with userId first and token second', async () => {
      prismaMock.notification.findMany.mockResolvedValue([
        {
          id: 77,
          userId: 'user-1',
          title: 'Scheduled',
          body: 'Body',
          data: { action: 'log_medication' },
          type: 'medication_reminder',
          user: { fcmToken: 'token-abc' },
        },
      ]);
      notificationsMock.sendToToken.mockResolvedValue(true);
      prismaMock.notification.update.mockResolvedValue({});

      await service.processScheduledNotifications();

      expect(notificationsMock.sendToToken).toHaveBeenCalledTimes(1);
      expect(notificationsMock.sendToToken).toHaveBeenCalledWith(
        'user-1',
        'token-abc',
        expect.objectContaining({
          title: 'Scheduled',
          body: 'Body',
        }),
        'medication_reminder',
      );
    });
  });

  describe('processMedicationReminders', () => {
    it('matches top-of-hour schedule times with zero-padded quarter-hour', async () => {
      jest.useFakeTimers();
      jest.setSystemTime(new Date('2026-04-06T08:00:00.000Z')); // Monday 08:00 UTC

      prismaMock.medicationSchedule.findMany.mockResolvedValue([
        {
          userId: 'user-1',
          medicationId: 11,
          daysOfWeek: '1,3,5',
          time: '08:00',
          medication: { id: 11, name: 'Metformin', timing: 'before' },
          user: { timezone: 'UTC' },
        },
      ]);
      prismaMock.notification.findFirst.mockResolvedValue(null);
      notificationsMock.sendMedicationReminder.mockResolvedValue(true);

      await service.processMedicationReminders();

      expect(notificationsMock.sendMedicationReminder).toHaveBeenCalledTimes(1);
      expect(notificationsMock.sendMedicationReminder).toHaveBeenCalledWith(
        'user-1',
        expect.objectContaining({ id: 11 }),
      );

      jest.useRealTimers();
    });
  });
});
