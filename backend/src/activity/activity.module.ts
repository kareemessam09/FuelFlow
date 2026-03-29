import { Module } from '@nestjs/common';
import { ActivityService } from './activity.service';
import { ActivityController } from './activity.controller';
import { EnergyModule } from '../energy/energy.module';
import { MealsModule } from '../meals/meals.module';

@Module({
  imports: [EnergyModule, MealsModule],
  controllers: [ActivityController],
  providers: [ActivityService],
  exports: [ActivityService],
})
export class ActivityModule {}
