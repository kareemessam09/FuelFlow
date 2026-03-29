import { Module } from '@nestjs/common';
import { EnergyService } from './energy.service';
import { EnergyController } from './energy.controller';

@Module({
  providers: [EnergyService],
  exports: [EnergyService],
  controllers: [EnergyController],
})
export class EnergyModule {}
