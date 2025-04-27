import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';

import { UserRepository } from './repositories/user.repository';
import { UserEntity } from '../domain/entities/user.entity';
import { RoadEventCreatedHandler } from './event-handlers/road-event-created.handler';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    CqrsModule,
    TypeOrmModule.forFeature([UserEntity]),
    ClientsModule.registerAsync([
      {
        name: 'RMQ_USERS_BUS',
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
  providers: [UserRepository, RoadEventCreatedHandler],
  exports: [UserRepository, RoadEventCreatedHandler],
})
export class InfrastructureModule {}
