import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  ParseIntPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FavoritesService } from './favorites.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { CurrentUserType } from '../auth/decorators/current-user.decorator';
import {
  CreateFavoriteDto,
  CreateTemplateDto,
  CreateCustomFoodDto,
} from './dto/create-favorite.dto';
import {
  UpdateFavoriteDto,
  UpdateTemplateDto,
  UpdateCustomFoodDto,
} from './dto/update-favorite.dto';

@Controller('favorites')
@UseGuards(JwtAuthGuard)
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  // ============================================
  // MEAL FAVORITES
  // ============================================

  @Post('meals')
  createFavorite(
    @CurrentUser() user: CurrentUserType,
    @Body() dto: CreateFavoriteDto,
  ) {
    return this.favoritesService.createFavorite(user.userId, dto);
  }

  @Get('meals')
  getFavorites(@CurrentUser() user: CurrentUserType) {
    return this.favoritesService.getFavorites(user.userId);
  }

  @Get('meals/:id')
  getFavorite(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.favoritesService.getFavorite(user.userId, id);
  }

  @Patch('meals/:id')
  updateFavorite(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateFavoriteDto,
  ) {
    return this.favoritesService.updateFavorite(user.userId, id, dto);
  }

  @Delete('meals/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteFavorite(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.favoritesService.deleteFavorite(user.userId, id);
  }

  @Post('meals/:id/log')
  createMealFromFavorite(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.favoritesService.createMealFromFavorite(user.userId, id);
  }

  // ============================================
  // MEAL TEMPLATES
  // ============================================

  @Post('templates')
  createTemplate(
    @CurrentUser() user: CurrentUserType,
    @Body() dto: CreateTemplateDto,
  ) {
    return this.favoritesService.createTemplate(user.userId, dto);
  }

  @Get('templates')
  getTemplates(@CurrentUser() user: CurrentUserType) {
    return this.favoritesService.getTemplates(user.userId);
  }

  @Get('templates/:id')
  getTemplate(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.favoritesService.getTemplate(user.userId, id);
  }

  @Patch('templates/:id')
  updateTemplate(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateTemplateDto,
  ) {
    return this.favoritesService.updateTemplate(user.userId, id, dto);
  }

  @Delete('templates/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteTemplate(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.favoritesService.deleteTemplate(user.userId, id);
  }

  @Post('templates/:id/log')
  createMealFromTemplate(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.favoritesService.createMealFromTemplate(user.userId, id);
  }

  // ============================================
  // CUSTOM FOODS
  // ============================================

  @Post('foods')
  createCustomFood(
    @CurrentUser() user: CurrentUserType,
    @Body() dto: CreateCustomFoodDto,
  ) {
    return this.favoritesService.createCustomFood(user.userId, dto);
  }

  @Get('foods')
  getCustomFoods(@CurrentUser() user: CurrentUserType) {
    return this.favoritesService.getCustomFoods(user.userId);
  }

  @Get('foods/search')
  searchCustomFoods(
    @CurrentUser() user: CurrentUserType,
    @Query('q') query: string,
  ) {
    return this.favoritesService.searchCustomFoods(user.userId, query || '');
  }

  @Get('foods/:id')
  getCustomFood(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.favoritesService.getCustomFood(user.userId, id);
  }

  @Patch('foods/:id')
  updateCustomFood(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateCustomFoodDto,
  ) {
    return this.favoritesService.updateCustomFood(user.userId, id, dto);
  }

  @Delete('foods/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteCustomFood(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.favoritesService.deleteCustomFood(user.userId, id);
  }

  @Post('foods/:id/log')
  createMealFromCustomFood(
    @CurrentUser() user: CurrentUserType,
    @Param('id', ParseIntPipe) id: number,
    @Query('servings') servings?: string,
  ) {
    const servingCount = servings ? parseFloat(servings) : 1;
    return this.favoritesService.createMealFromCustomFood(
      user.userId,
      id,
      servingCount,
    );
  }

  // ============================================
  // FOOD HISTORY
  // ============================================

  @Get('recent')
  getRecentFoods(
    @CurrentUser() user: CurrentUserType,
    @Query('limit') limit?: string,
  ) {
    const limitNum = limit ? parseInt(limit, 10) : 10;
    return this.favoritesService.getRecentFoods(user.userId, limitNum);
  }
}
