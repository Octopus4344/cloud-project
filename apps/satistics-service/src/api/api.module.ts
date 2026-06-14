import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';
import { StatisticsController } from './controllers/statistics.controller';
import { HealthController } from './controllers/health.controller';
import { ReportsController } from './controllers/reports.controller';

@Module({
  imports: [CqrsModule, InfrastructureModule],
  controllers: [StatisticsController, ReportsController, HealthController],
})
export class ApiModule {}
