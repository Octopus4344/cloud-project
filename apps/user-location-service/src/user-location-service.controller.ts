import { Controller, Get } from '@nestjs/common';
import { UserLocationServiceService } from './user-location-service.service';

@Controller()
export class UserLocationServiceController {
  constructor(private readonly userLocationServiceService: UserLocationServiceService) {}

  @Get()
  getHello(): string {
    return this.userLocationServiceService.getHello();
  }
}
