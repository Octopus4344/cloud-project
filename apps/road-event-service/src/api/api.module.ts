import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { RoadEventController } from './controllers/road-event.controller';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';

@Module({
  imports: [CqrsModule, InfrastructureModule],
  controllers: [RoadEventController],
})
export class ApiModule {}
