import { Controller, Get } from '@nestjs/common';
import { SatisticsServiceService } from './satistics-service.service';

@Controller()
export class SatisticsServiceController {
  constructor(private readonly satisticsServiceService: SatisticsServiceService) {}

  @Get()
  getHello(): string {
    return this.satisticsServiceService.getHello();
  }
}
