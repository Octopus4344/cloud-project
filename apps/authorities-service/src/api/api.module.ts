import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';
import { StatisticsController } from './controllers/statistics.controller';

@Module({
  imports: [CqrsModule, InfrastructureModule],
  controllers: [StatisticsController]
})
export class ApiModule {}