import { Controller, Get } from '@nestjs/common';
import { QueryBus } from '@nestjs/cqrs';
import { StatisticsResponseDto } from '../dto/statistics-response.dto';
import { GetStatisticsQuery } from '../../domain/queries/get-statistics.query';

@Controller('stats')
export class StatisticsController {
  constructor(private readonly queryBus: QueryBus) {}

  @Get()
  async getStats(): Promise<StatisticsResponseDto[]> {
    const raw = await this.queryBus.execute(new GetStatisticsQuery())
    return raw.map(r => ({ type: r.type, count: parseInt(r.count, 10)}))
  }
}