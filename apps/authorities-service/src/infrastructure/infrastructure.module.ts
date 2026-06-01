import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { ConfigModule } from '@nestjs/config';

import { IncidentRepository } from './repositories/incident.repository';
import { RoadEventCompletedHandler } from './event-handlers/road-event-completed.handler';
import { GetStatisticsHandler } from './query-handlers/get-statistics.handler';
import { NotifierService } from './services/notifier.service';
import { SqsConsumerService } from './messaging/sqs-consumer.service';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), CqrsModule],
  providers: [
    IncidentRepository,
    RoadEventCompletedHandler,
    GetStatisticsHandler,
    NotifierService,
    SqsConsumerService,
  ],
  exports: [IncidentRepository, RoadEventCompletedHandler],
})
export class InfrastructureModule {}
