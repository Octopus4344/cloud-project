import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { UserController } from './controllers/user.controller';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';
import { HealthController } from './controllers/health.controller';

@Module({
  imports: [CqrsModule, InfrastructureModule],
  controllers: [UserController, HealthController],
})
export class ApiModule {}

