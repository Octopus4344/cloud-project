import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';

import { StatsEntity } from '../domain/entities/stats.entity';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { StatisticsRepository } from './repositories/statistics.repository';
import { RoadEventCompletedEvent } from '../domain/events/road-event-completed.event';
import { RoadEventCompletedHandler } from './event-handlers/road-event-completed.handler';
import { GetStatisticsHandler } from './query-handlers/get-statistics.handler';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    CqrsModule,
    TypeOrmModule.forFeature([StatsEntity]),
    ClientsModule.registerAsync([
      {
        name: 'RMQ_LOCATION_BUS',
        imports: [ConfigModule],
        inject: [ConfigService],
        useFactory: (config: ConfigService) => ({
          transport: Transport.RMQ,
          options: {
            urls: [config.get<string>('RABBITMQ_URL')!],
            queueOptions: { durable: true },
            queue: 'road-event-queue',
          },
        }),
      },
    ]),
  ],
  controllers: [RoadEventCompletedHandler],
  providers: [StatisticsRepository, RoadEventCompletedHandler, GetStatisticsHandler],
  exports: [StatisticsRepository, RoadEventCompletedHandler],
})
export class InfrastructureModule {}
