import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';
import { StatisticsController } from './controllers/statistics.controller';
import { HealthController } from './controllers/health.controller';

@Module({
  imports: [CqrsModule, InfrastructureModule],
  controllers: [StatisticsController, HealthController]
})
export class ApiModule {}