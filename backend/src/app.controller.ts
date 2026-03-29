import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  /**
   * GET /api
   * Root endpoint - API info
   */
  @Get()
  getInfo() {
    return {
      name: 'FuelFlow API',
      version: '1.0.0',
      description: 'Proactive Energy & Metabolism Manager',
      endpoints: {
        users: '/api/users',
        meals: '/api/meals',
        activity: '/api/activity',
        energy: '/api/energy',
        health: '/api/health',
      },
    };
  }

  /**
   * GET /api/health
   * Health check endpoint
   */
  @Get('health')
  getHealth() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV ?? 'development',
    };
  }
}
