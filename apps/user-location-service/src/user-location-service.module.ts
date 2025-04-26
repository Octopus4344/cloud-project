import { Module } from '@nestjs/common';
import { UserLocationServiceController } from './user-location-service.controller';
import { UserLocationServiceService } from './user-location-service.service';

@Module({
  imports: [],
  controllers: [UserLocationServiceController],
  providers: [UserLocationServiceService],
})
export class UserLocationServiceModule {}
