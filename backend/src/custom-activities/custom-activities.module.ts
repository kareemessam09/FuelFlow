import { Module } from '@nestjs/common';
import { CustomActivitiesService } from './custom-activities.service';
import { CustomActivitiesController } from './custom-activities.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [CustomActivitiesController],
  providers: [CustomActivitiesService],
  exports: [CustomActivitiesService],
})
export class CustomActivitiesModule {}
