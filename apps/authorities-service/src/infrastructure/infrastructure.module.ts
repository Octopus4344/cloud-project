import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';

import { IncidentEntity } from '../domain/entities/incident.entity';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { IncidentRepository } from './repositories/incident.repository';
import { RoadEventCompletedHandler } from './event-handlers/road-event-completed.handler';
import { NotifierService } from './services/notifier.service';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    CqrsModule,
    TypeOrmModule.forFeature([IncidentEntity]),
    ClientsModule.registerAsync([
      {
        name: 'RMQ_AUTHORITIES_BUS',
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
  providers: [IncidentRepository, RoadEventCompletedHandler, NotifierService],
  exports: [IncidentRepository, RoadEventCompletedHandler],
})
export class InfrastructureModule {}
