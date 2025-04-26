import { Module } from '@nestjs/common';
import { SatisticsServiceController } from './satistics-service.controller';
import { SatisticsServiceService } from './satistics-service.service';

@Module({
  imports: [],
  controllers: [SatisticsServiceController],
  providers: [SatisticsServiceService],
})
export class SatisticsServiceModule {}
