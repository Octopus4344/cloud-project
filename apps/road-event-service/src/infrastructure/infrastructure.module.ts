import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { ConfigModule } from '@nestjs/config';
import { PassportModule } from '@nestjs/passport';

import { RoadEventRepository } from './repositories/road-event.repository';
import { StatusRepository } from './repositories/status.repository';
import { PublishRoadEventHandler } from './command-handlers/publish-road-event.handler';
import { AggregateService } from './services/aggregate.service';
import { UserDataProvidedHandler } from './event-handlers/user-data-provided.handler';
import { UserLocationProvidedHandler } from './event-handlers/user-location-provided.handler';
import { SqsProducerService } from './messaging/sqs-producer.service';
import { SqsConsumerService } from './messaging/sqs-consumer.service';
import { SnsProducerService } from './messaging/sns-producer.service';
import { CognitoJwtStrategy } from './auth/cognito-jwt.strategy';
import { JwtAuthGuard } from './auth/jwt-auth.guard';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    CqrsModule,
    PassportModule.register({ defaultStrategy: 'cognito-jwt' }),
  ],
  providers: [
    RoadEventRepository,
    StatusRepository,
    AggregateService,
    PublishRoadEventHandler,
    UserDataProvidedHandler,
    UserLocationProvidedHandler,
    SqsProducerService,
    SqsConsumerService,
    SnsProducerService,
    CognitoJwtStrategy,
    JwtAuthGuard,
  ],
  exports: [PublishRoadEventHandler, JwtAuthGuard],
})
export class InfrastructureModule {}
