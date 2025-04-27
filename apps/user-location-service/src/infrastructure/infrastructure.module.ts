import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';

import { LocationEntity } from '../domain/entities/location.entity';
import { RoadEventCreatedHandler } from './event-handlers/road-event-created.handler';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { LocationRepository } from './repositories/location.repository';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    CqrsModule,
    TypeOrmModule.forFeature([LocationEntity]),
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
  controllers: [RoadEventCreatedHandler],
  providers: [LocationRepository, RoadEventCreatedHandler],
  exports: [LocationRepository, RoadEventCreatedHandler],
})
export class InfrastructureModule {}
