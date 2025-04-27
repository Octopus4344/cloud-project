import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';

import { RoadEventEntity } from '../domain/entities/road-event.entity';
import { RoadEventRepository } from './repositories/road-event.repository';
import { PublishRoadEventHandler } from './command-handlers/publish-road-event.handler';
import { EventStatusEntity } from '../domain/entities/event-status.entity';
import { StatusRepository } from './repositories/status.repository';
import { AggregateService } from './services/aggregate.service';
import { UserDataProvidedHandler } from './event-handlers/user-data-provided.handler';

@Module({
  imports: [
    CqrsModule,
    TypeOrmModule.forFeature([RoadEventEntity, EventStatusEntity]),
    ClientsModule.register([
      {
        name: 'RMQ_EVENTS_BUS',
        transport: Transport.RMQ,
        options: {
          urls: [process.env.RABBITMQ_URL!],
          queue: 'road-event-queue',
          queueOptions: {
            durable: true,
          },
        },
      },
    ]),
  ],
  providers: [RoadEventRepository, StatusRepository, AggregateService, PublishRoadEventHandler, UserDataProvidedHandler, UserDataProvidedHandler],
  exports: [PublishRoadEventHandler],
})
export class InfrastructureModule {}
