import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { ConfigModule } from '@nestjs/config';

import { LocationRepository } from './repositories/location.repository';
import { RoadEventCreatedHandler } from './event-handlers/road-event-created.handler';
import { SqsProducerService } from './messaging/sqs-producer.service';
import { SqsConsumerService } from './messaging/sqs-consumer.service';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), CqrsModule],
  providers: [
    LocationRepository,
    RoadEventCreatedHandler,
    SqsProducerService,
    SqsConsumerService,
  ],
  exports: [LocationRepository, RoadEventCreatedHandler],
})
export class InfrastructureModule {}
