import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { ConfigModule } from '@nestjs/config';

import { StatisticsRepository } from './repositories/statistics.repository';
import { RoadEventCompletedHandler } from './event-handlers/road-event-completed.handler';
import { GetStatisticsHandler } from './query-handlers/get-statistics.handler';
import { SqsConsumerService } from './messaging/sqs-consumer.service';
import { ReportService } from './services/report.service';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), CqrsModule],
  providers: [
    StatisticsRepository,
    RoadEventCompletedHandler,
    GetStatisticsHandler,
    ReportService,
    SqsConsumerService,
  ],
  exports: [StatisticsRepository, RoadEventCompletedHandler, ReportService],
})
export class InfrastructureModule {}
