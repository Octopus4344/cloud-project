import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';

import { UserRepository } from './repositories/user.repository';
import { UserEntity } from '../domain/entities/user.entity';
import { RoadEventCreatedHandler } from './event-handlers/road-event-created.handler';

@Module({
  imports: [
    CqrsModule,
    TypeOrmModule.forFeature([UserEntity]),
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
  providers: [UserRepository, RoadEventCreatedHandler],
})
export class InfrastructureModule {}
