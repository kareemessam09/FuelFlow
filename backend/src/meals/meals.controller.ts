import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Delete,
  HttpCode,
  HttpStatus,
  UseInterceptors,
  UploadedFile,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
  Query,
  BadRequestException,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { MealsService } from './meals.service';
import {
  CreateMealDto,
  CreateMealManualDto,
  UpdateMealDto,
} from './dto/create-meal.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { CurrentUserType } from '../auth/decorators/current-user.decorator';

@Controller('meals')
@UseGuards(JwtAuthGuard)
export class MealsController {
  constructor(private readonly mealsService: MealsService) {}

  /**
   * POST /api/meals/snap
   * Upload a food image for AI analysis and create a meal log
   * This is the main "Snap & Fuel" feature
   * userId is extracted from JWT token
   */
  @Post('snap')
  @HttpCode(HttpStatus.CREATED)
  @UseInterceptors(FileInterceptor('image'))
  async snapAndFuel(
    @CurrentUser() user: CurrentUserType,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 10 * 1024 * 1024 }), // 10MB max
          new FileTypeValidator({ fileType: /(jpeg|jpg|png|webp|gif)$/i }),
        ],
      }),
    )
    file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('Image file is required');
    }

    return this.mealsService.createFromImage(
      user.userId,
      file.buffer,
      file.mimetype,
    );
  }

  /**
   * POST /api/meals/manual
   * Create a meal manually without AI analysis
   * userId is extracted from JWT token
   */
  @Post('manual')
  @HttpCode(HttpStatus.CREATED)
  createManual(
    @CurrentUser() user: CurrentUserType,
    @Body() createMealDto: Omit<CreateMealManualDto, 'userId'>,
  ) {
    return this.mealsService.createManual({
      ...createMealDto,
      userId: user.userId,
    });
  }

  /**
   * GET /api/meals/my
   * Get all meals for the authenticated user
   */
  @Get('my')
  findMyMeals(@CurrentUser() user: CurrentUserType) {
    return this.mealsService.findAllByUser(user.userId);
  }

  /**
   * GET /api/meals/my/today
   * Get today's meals for the authenticated user
   */
  @Get('my/today')
  findMyTodaysMeals(@CurrentUser() user: CurrentUserType) {
    return this.mealsService.findTodaysMeals(user.userId);
  }

  /**
   * GET /api/meals/:id
   * Get a single meal by ID
   */
  @Get(':id')
  async findOne(@Param('id') id: string, @CurrentUser() user: CurrentUserType) {
    const meal = await this.mealsService.findOne(+id);
    if (meal.userId !== user.userId) {
      throw new ForbiddenException('You can only access your own meals');
    }
    return meal;
  }

  /**
   * PATCH /api/meals/:id
   * Update a meal (adjust portion size, etc.)
   */
  @Patch(':id')
  async update(
    @Param('id') id: string,
    @CurrentUser() user: CurrentUserType,
    @Body() updateMealDto: UpdateMealDto,
  ) {
    const meal = await this.mealsService.findOne(+id);
    if (meal.userId !== user.userId) {
      throw new ForbiddenException('You can only update your own meals');
    }
    return this.mealsService.update(+id, updateMealDto);
  }

  /**
   * DELETE /api/meals/:id
   * Delete a meal
   */
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param('id') id: string, @CurrentUser() user: CurrentUserType) {
    const meal = await this.mealsService.findOne(+id);
    if (meal.userId !== user.userId) {
      throw new ForbiddenException('You can only delete your own meals');
    }
    return this.mealsService.remove(+id);
  }
}
