import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { EnergyModule } from './energy/energy.module';
import { GeminiModule } from './gemini/gemini.module';
import { UsersModule } from './users/users.module';
import { MealsModule } from './meals/meals.module';
import { ActivityModule } from './activity/activity.module';
import { AuthModule } from './auth/auth.module';
import { ConfigModule } from '@nestjs/config';
import { NotificationsModule } from './notifications/notifications.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { FavoritesModule } from './favorites/favorites.module';
import { CustomActivitiesModule } from './custom-activities/custom-activities.module';
import { JobsModule } from './jobs/jobs.module';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([
      {
        ttl: 60_000,
        limit: 120,
      },
    ]),
    PrismaModule,
    EnergyModule,
    GeminiModule,
    UsersModule,
    MealsModule,
    ActivityModule,
    AuthModule,
    NotificationsModule,
    AnalyticsModule,
    FavoritesModule,
    CustomActivitiesModule,
    JobsModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
