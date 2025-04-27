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
import { UserLocationProvidedHandler } from './event-handlers/user-location-provided.handler';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    CqrsModule,
    TypeOrmModule.forFeature([RoadEventEntity, EventStatusEntity]),
    ClientsModule.registerAsync([
      {
        name: 'RMQ_EVENTS_BUS',
        imports: [ConfigModule],
        inject: [ConfigService],
        useFactory: (config: ConfigService) => ({
          transport: Transport.RMQ,
          options: {
            urls: [config.get<string>('RABBITMQ_URL')!],
            queue: 'user-data-queue',
            queueOptions: { durable: true },
          },
        }),
      },
      {
        name: 'RMQ_LOC_BUS',
        imports: [ConfigModule],
        inject: [ConfigService],
        useFactory: (config: ConfigService) => ({
          transport: Transport.RMQ,
          options: {
            urls: [config.get<string>('RABBITMQ_URL')!],
            queue: 'user-loc-queue',
            queueOptions: { durable: true },
          },
        }),
      },
    ]),
  ],
  providers: [
    RoadEventRepository,
    StatusRepository,
    AggregateService,
    PublishRoadEventHandler,
    UserDataProvidedHandler,
    UserLocationProvidedHandler,
  ],
  exports: [PublishRoadEventHandler],
  controllers: [UserDataProvidedHandler, UserLocationProvidedHandler]
})
export class InfrastructureModule {}
