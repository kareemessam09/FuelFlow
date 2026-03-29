import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getAppInfo() {
    return {
      name: 'FuelFlow API',
      version: '1.0.0',
      description: 'Proactive Energy & Metabolism Manager',
    };
  }
}
