import { Test, TestingModule } from '@nestjs/testing';
import { EnergyService } from './energy.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  ActivityMode,
  ACTIVITY_MULTIPLIERS,
  ENERGY_CONSTANTS,
  EnergyStatus,
} from './energy.constants';

describe('EnergyService', () => {
  let service: EnergyService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EnergyService,
        {
          provide: PrismaService,
          useValue: {
            energySnapshot: {
              findFirst: jest.fn(),
              create: jest.fn(),
            },
          },
        },
      ],
    }).compile();

    service = module.get<EnergyService>(EnergyService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('calculateRemainingVolume', () => {
    it('should calculate correct remaining volume with standard inputs', () => {
      // Start at 100%, GI of 50, Resting (1.0x), 60 minutes
      // Drain = 0.5 * 0.5 * 1.0 * 60 = 15%
      const result = service.calculateRemainingVolume({
        startVolume: 100,
        glycemicIndex: 50,
        activityMultiplier: 1.0,
        elapsedMinutes: 60,
      });

      expect(result).toBe(85);
    });

    it('should apply activity multiplier correctly', () => {
      // Start at 100%, GI of 50, Gym Cardio (5.0x), 20 minutes
      // Drain = 0.5 * 0.5 * 5.0 * 20 = 25%
      const result = service.calculateRemainingVolume({
        startVolume: 100,
        glycemicIndex: 50,
        activityMultiplier: 5.0,
        elapsedMinutes: 20,
      });

      expect(result).toBe(75);
    });

    it('should not go below 0', () => {
      const result = service.calculateRemainingVolume({
        startVolume: 10,
        glycemicIndex: 100,
        activityMultiplier: 5.0,
        elapsedMinutes: 100,
      });

      expect(result).toBe(0);
    });

    it('should not exceed 100', () => {
      // Even if somehow we pass a negative drain (shouldn't happen)
      const result = service.calculateRemainingVolume({
        startVolume: 100,
        glycemicIndex: 0,
        activityMultiplier: 1.0,
        elapsedMinutes: 60,
      });

      expect(result).toBeLessThanOrEqual(100);
    });

    it('should drain faster with higher glycemic index', () => {
      const lowGI = service.calculateRemainingVolume({
        startVolume: 100,
        glycemicIndex: 20,
        activityMultiplier: 1.0,
        elapsedMinutes: 60,
      });

      const highGI = service.calculateRemainingVolume({
        startVolume: 100,
        glycemicIndex: 80,
        activityMultiplier: 1.0,
        elapsedMinutes: 60,
      });

      expect(lowGI).toBeGreaterThan(highGI);
    });
  });

  describe('calculateEnergyState', () => {
    it('should return OPTIMAL status when above 60%', () => {
      const state = service.calculateEnergyState(75, 50, 1.0);
      expect(state.status).toBe(EnergyStatus.OPTIMAL);
    });

    it('should return WARNING status when between 30-60%', () => {
      const state = service.calculateEnergyState(45, 50, 1.0);
      expect(state.status).toBe(EnergyStatus.WARNING);
    });

    it('should return CRITICAL status when below 30%', () => {
      const state = service.calculateEnergyState(20, 50, 1.0);
      expect(state.status).toBe(EnergyStatus.CRITICAL);
    });

    it('should calculate ETC correctly', () => {
      // At 60%, need to drop 30% to reach critical (30%)
      // Drain rate = 0.5 * 0.5 * 1.0 = 0.25% per minute
      // ETC = 30 / 0.25 = 120 minutes
      const state = service.calculateEnergyState(60, 50, 1.0);
      expect(state.etcMinutes).toBe(120);
    });

    it('should return null ETC when already below threshold', () => {
      const state = service.calculateEnergyState(25, 50, 1.0);
      expect(state.etcMinutes).toBeNull();
    });

    it('should calculate ETC to zero', () => {
      // At 50%, drain rate = 0.5 * 0.5 * 1.0 = 0.25% per minute
      // ETC to zero = 50 / 0.25 = 200 minutes
      const state = service.calculateEnergyState(50, 50, 1.0);
      expect(state.etcZeroMinutes).toBe(200);
    });
  });

  describe('getEnergyStatus', () => {
    it('should return OPTIMAL for values above 60', () => {
      expect(service.getEnergyStatus(61)).toBe(EnergyStatus.OPTIMAL);
      expect(service.getEnergyStatus(100)).toBe(EnergyStatus.OPTIMAL);
    });

    it('should return WARNING for values between 30 and 60', () => {
      expect(service.getEnergyStatus(31)).toBe(EnergyStatus.WARNING);
      expect(service.getEnergyStatus(60)).toBe(EnergyStatus.WARNING);
    });

    it('should return CRITICAL for values at or below 30', () => {
      expect(service.getEnergyStatus(30)).toBe(EnergyStatus.CRITICAL);
      expect(service.getEnergyStatus(0)).toBe(EnergyStatus.CRITICAL);
    });
  });

  describe('addMealToVolume', () => {
    it('should add meal volume to current volume', () => {
      const result = service.addMealToVolume(40, {
        fullnessVolume: 30,
        glycemicIndex: 50,
        absorptionProfile: 'Balanced' as any,
        estimatedSatiety: 120,
      });

      expect(result).toBe(70);
    });

    it('should cap at 100%', () => {
      const result = service.addMealToVolume(80, {
        fullnessVolume: 50,
        glycemicIndex: 50,
        absorptionProfile: 'Balanced' as any,
        estimatedSatiety: 120,
      });

      expect(result).toBe(100);
    });
  });

  describe('calculateEffectiveGlycemicIndex', () => {
    it('should return 50 for empty array', () => {
      expect(service.calculateEffectiveGlycemicIndex([])).toBe(50);
    });

    it('should return weighted average', () => {
      const meals = [
        { glycemicIndex: 80, remainingVolume: 50 }, // 4000
        { glycemicIndex: 20, remainingVolume: 50 }, // 1000
      ];
      // Total = 5000, Volume = 100, Average = 50
      expect(service.calculateEffectiveGlycemicIndex(meals)).toBe(50);
    });

    it('should weight by remaining volume', () => {
      const meals = [
        { glycemicIndex: 80, remainingVolume: 75 }, // 6000
        { glycemicIndex: 20, remainingVolume: 25 }, // 500
      ];
      // Total = 6500, Volume = 100, Average = 65
      expect(service.calculateEffectiveGlycemicIndex(meals)).toBe(65);
    });
  });

  describe('getActivityMultiplier', () => {
    it('should return correct multipliers for all modes', () => {
      expect(service.getActivityMultiplier(ActivityMode.RESTING)).toBe(1.0);
      expect(service.getActivityMultiplier(ActivityMode.CODING)).toBe(1.3);
      expect(service.getActivityMultiplier(ActivityMode.STUDYING)).toBe(1.6);
      expect(service.getActivityMultiplier(ActivityMode.GYM_STRENGTH)).toBe(
        3.5,
      );
      expect(service.getActivityMultiplier(ActivityMode.GYM_CARDIO)).toBe(5.0);
    });

    it('should return Resting multiplier for unknown modes', () => {
      expect(service.getActivityMultiplier('Unknown')).toBe(1.0);
    });
  });

  describe('simulateEnergyDrain', () => {
    it('should simulate multiple activity segments', () => {
      // Start at 100%, GI 50
      // Segment 1: Resting for 60 min = drain 15%
      // Segment 2: Coding for 60 min = drain 0.5 * 0.5 * 1.3 * 60 = 19.5%
      // Total drain = 34.5%, remaining = 65.5%
      const result = service.simulateEnergyDrain(100, 50, [
        { mode: ActivityMode.RESTING, durationMinutes: 60 },
        { mode: ActivityMode.CODING, durationMinutes: 60 },
      ]);

      expect(result).toBeCloseTo(65.5, 1);
    });

    it('should stop at 0', () => {
      const result = service.simulateEnergyDrain(20, 100, [
        { mode: ActivityMode.GYM_CARDIO, durationMinutes: 100 },
      ]);

      expect(result).toBe(0);
    });
  });

  describe('calculateAlertTime', () => {
    it('should return null if already below threshold', () => {
      const result = service.calculateAlertTime(25, 50, 1.0);
      expect(result).toBeNull();
    });

    it('should return a future date when above threshold', () => {
      const now = new Date();
      const result = service.calculateAlertTime(60, 50, 1.0);

      expect(result).not.toBeNull();
      expect(result!.getTime()).toBeGreaterThan(now.getTime());
    });
  });
});
