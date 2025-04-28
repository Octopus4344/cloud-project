import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { UserController } from './controllers/user.controller';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';

@Module({
  imports: [CqrsModule, InfrastructureModule],
  controllers: [UserController],
})
export class ApiModule {}

