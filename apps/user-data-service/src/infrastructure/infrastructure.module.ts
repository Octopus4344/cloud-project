import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { ConfigModule } from '@nestjs/config';

import { UserRepository } from './repositories/user.repository';
import { RoadEventCreatedHandler } from './event-handlers/road-event-created.handler';
import { SqsProducerService } from './messaging/sqs-producer.service';
import { SqsConsumerService } from './messaging/sqs-consumer.service';
import { CognitoService } from './services/cognito.service';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), CqrsModule],
  providers: [
    UserRepository,
    RoadEventCreatedHandler,
    SqsProducerService,
    SqsConsumerService,
    CognitoService,
  ],
  exports: [UserRepository, RoadEventCreatedHandler, CognitoService],
})
export class InfrastructureModule {}
