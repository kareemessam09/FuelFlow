import { Module } from '@nestjs/common';
import { MealsService } from './meals.service';
import { MealsController } from './meals.controller';
import { GeminiModule } from '../gemini/gemini.module';
import { EnergyModule } from '../energy/energy.module';

@Module({
  imports: [GeminiModule, EnergyModule],
  controllers: [MealsController],
  providers: [MealsService],
  exports: [MealsService],
})
export class MealsModule {}
