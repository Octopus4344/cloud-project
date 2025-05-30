import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { RoadEventController } from './controllers/road-event.controller';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';
import { HealthController } from './controllers/health.controller'; // Added import

@Module({
  imports: [CqrsModule, InfrastructureModule],
  controllers: [RoadEventController, HealthController], // Added HealthController
})
export class ApiModule {}
