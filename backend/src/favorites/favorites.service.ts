import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateFavoriteDto, CreateTemplateDto, CreateCustomFoodDto } from './dto/create-favorite.dto';
import { UpdateFavoriteDto, UpdateTemplateDto, UpdateCustomFoodDto } from './dto/update-favorite.dto';

@Injectable()
export class FavoritesService {
  private readonly logger = new Logger(FavoritesService.name);

  constructor(private prisma: PrismaService) {}

  // ============================================
  // MEAL FAVORITES
  // ============================================

  async createFavorite(userId: string, dto: CreateFavoriteDto) {
    return this.prisma.mealFavorite.create({
      data: {
        userId,
        ...dto,
      },
    });
  }

  async getFavorites(userId: string) {
    return this.prisma.mealFavorite.findMany({
      where: { userId },
      orderBy: { usageCount: 'desc' },
    });
  }

  async getFavorite(userId: string, id: number) {
    const favorite = await this.prisma.mealFavorite.findFirst({
      where: { id, userId },
    });
    if (!favorite) {
      throw new NotFoundException('Favorite not found');
    }
    return favorite;
  }

  async updateFavorite(userId: string, id: number, dto: UpdateFavoriteDto) {
    await this.getFavorite(userId, id); // Check ownership
    return this.prisma.mealFavorite.update({
      where: { id },
      data: dto,
    });
  }

  async deleteFavorite(userId: string, id: number) {
    await this.getFavorite(userId, id); // Check ownership
    return this.prisma.mealFavorite.delete({
      where: { id },
    });
  }

  async incrementFavoriteUsage(userId: string, id: number) {
    return this.prisma.mealFavorite.update({
      where: { id },
      data: { usageCount: { increment: 1 } },
    });
  }

  async createMealFromFavorite(userId: string, favoriteId: number) {
    const favorite = await this.getFavorite(userId, favoriteId);
    
    // Increment usage count
    await this.incrementFavoriteUsage(userId, favoriteId);

    // Create meal log from favorite
    return this.prisma.mealLog.create({
      data: {
        userId,
        foodName: favorite.foodName,
        fullnessVolume: favorite.fullnessVolume,
        absorptionRate: favorite.absorptionRate,
        absorptionProfile: favorite.absorptionProfile,
        estimatedSatiety: favorite.estimatedSatiety,
        category: favorite.category,
        calories: favorite.calories,
        protein: favorite.protein,
        carbs: favorite.carbs,
        fat: favorite.fat,
        imageUrl: favorite.imageUrl,
      },
    });
  }

  // ============================================
  // MEAL TEMPLATES
  // ============================================

  async createTemplate(userId: string, dto: CreateTemplateDto) {
    return this.prisma.mealTemplate.create({
      data: {
        userId,
        ...dto,
      },
    });
  }

  async getTemplates(userId: string) {
    return this.prisma.mealTemplate.findMany({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async getTemplate(userId: string, id: number) {
    const template = await this.prisma.mealTemplate.findFirst({
      where: { id, userId },
    });
    if (!template) {
      throw new NotFoundException('Template not found');
    }
    return template;
  }

  async updateTemplate(userId: string, id: number, dto: UpdateTemplateDto) {
    await this.getTemplate(userId, id); // Check ownership
    return this.prisma.mealTemplate.update({
      where: { id },
      data: dto,
    });
  }

  async deleteTemplate(userId: string, id: number) {
    await this.getTemplate(userId, id); // Check ownership
    return this.prisma.mealTemplate.delete({
      where: { id },
    });
  }

  async createMealFromTemplate(userId: string, templateId: number) {
    const template = await this.getTemplate(userId, templateId);

    return this.prisma.mealLog.create({
      data: {
        userId,
        foodName: template.foodName,
        fullnessVolume: template.fullnessVolume,
        absorptionRate: template.absorptionRate,
        absorptionProfile: template.absorptionProfile,
        estimatedSatiety: template.estimatedSatiety,
        category: template.category,
        calories: template.calories,
        protein: template.protein,
        carbs: template.carbs,
        fat: template.fat,
      },
    });
  }

  // ============================================
  // CUSTOM FOODS
  // ============================================

  async createCustomFood(userId: string, dto: CreateCustomFoodDto) {
    return this.prisma.customFood.create({
      data: {
        userId,
        ...dto,
      },
    });
  }

  async getCustomFoods(userId: string) {
    return this.prisma.customFood.findMany({
      where: { userId },
      orderBy: { foodName: 'asc' },
    });
  }

  async searchCustomFoods(userId: string, query: string) {
    return this.prisma.customFood.findMany({
      where: {
        userId,
        foodName: { contains: query, mode: 'insensitive' },
      },
      take: 20,
    });
  }

  async getCustomFood(userId: string, id: number) {
    const food = await this.prisma.customFood.findFirst({
      where: { id, userId },
    });
    if (!food) {
      throw new NotFoundException('Custom food not found');
    }
    return food;
  }

  async updateCustomFood(userId: string, id: number, dto: UpdateCustomFoodDto) {
    await this.getCustomFood(userId, id); // Check ownership
    return this.prisma.customFood.update({
      where: { id },
      data: dto,
    });
  }

  async deleteCustomFood(userId: string, id: number) {
    await this.getCustomFood(userId, id); // Check ownership
    return this.prisma.customFood.delete({
      where: { id },
    });
  }

  async createMealFromCustomFood(userId: string, foodId: number, servings: number = 1) {
    const food = await this.getCustomFood(userId, foodId);

    return this.prisma.mealLog.create({
      data: {
        userId,
        foodName: food.foodName,
        fullnessVolume: food.fullnessVolume * servings,
        absorptionRate: food.absorptionRate,
        absorptionProfile: food.absorptionProfile,
        estimatedSatiety: food.estimatedSatiety * servings,
        calories: food.calories ? food.calories * servings : null,
        protein: food.protein ? food.protein * servings : null,
        carbs: food.carbs ? food.carbs * servings : null,
        fat: food.fat ? food.fat * servings : null,
      },
    });
  }

  // ============================================
  // FOOD HISTORY (Recent foods from meals)
  // ============================================

  async getRecentFoods(userId: string, limit: number = 10) {
    const recentMeals = await this.prisma.mealLog.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit * 2, // Get more to filter duplicates
      select: {
        foodName: true,
        fullnessVolume: true,
        absorptionRate: true,
        absorptionProfile: true,
        estimatedSatiety: true,
        category: true,
        createdAt: true,
      },
    });

    // Remove duplicates by food name
    const seen = new Set<string>();
    const unique = recentMeals.filter((meal) => {
      if (seen.has(meal.foodName)) return false;
      seen.add(meal.foodName);
      return true;
    });

    return unique.slice(0, limit);
  }
}
