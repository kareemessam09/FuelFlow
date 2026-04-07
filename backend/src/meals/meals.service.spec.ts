import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { MealsService } from './meals.service';
import { PrismaService } from '../prisma/prisma.service';
import { GeminiService } from '../gemini/gemini.service';
import { EnergyService } from '../energy/energy.service';
import { MedicationsService } from '../medications/medications.service';

describe('MealsService', () => {
  let service: MealsService;
  let prismaMock: any;
  let medicationsMock: { getRequiredBeforeMeal: jest.Mock };

  beforeEach(async () => {
    prismaMock = {
      user: {
        findUnique: jest.fn(),
      },
      mealLog: {
        create: jest.fn(),
        findMany: jest.fn(),
      },
      activityLog: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
      },
      notification: {
        create: jest.fn(),
      },
    };

    medicationsMock = {
      getRequiredBeforeMeal: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MealsService,
        {
          provide: PrismaService,
          useValue: prismaMock,
        },
        {
          provide: GeminiService,
          useValue: {
            analyzeFoodImage: jest.fn(),
          },
        },
        {
          provide: EnergyService,
          useValue: {
            addMealToVolume: jest.fn().mockReturnValue(80),
            calculateEnergyState: jest.fn().mockReturnValue({
              volumeRemaining: 80,
              status: 'optimal',
              etcMinutes: 120,
              etcZeroMinutes: 320,
            }),
            calculateRemainingVolume: jest.fn().mockReturnValue(50),
          },
        },
        {
          provide: MedicationsService,
          useValue: {
            ...medicationsMock,
            getRequiredAfterMeal: jest.fn().mockResolvedValue([]),
          },
        },
      ],
    }).compile();

    service = module.get<MealsService>(MealsService);
  });

  describe('createManual', () => {
    it('throws NotFoundException when user does not exist', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);

      await expect(
        service.createManual({
          userId: 'missing',
          foodName: 'Oats',
          fullnessVolume: 40,
          absorptionRate: 45,
          estimatedSatiety: 180,
          category: 'breakfast',
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('blocks meal creation when before-meal medications are required', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: 'user-1',
        timezone: 'UTC',
      });
      medicationsMock.getRequiredBeforeMeal.mockResolvedValue([
        { name: 'Metformin' },
      ]);

      await expect(
        service.createManual({
          userId: 'user-1',
          foodName: 'Lunch Bowl',
          fullnessVolume: 55,
          absorptionRate: 60,
          estimatedSatiety: 140,
          category: 'lunch',
        }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prismaMock.mealLog.create).not.toHaveBeenCalled();
    });
  });
});
