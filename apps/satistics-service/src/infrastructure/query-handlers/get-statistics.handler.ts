import { IQueryHandler, QueryHandler } from '@nestjs/cqrs';
import { GetStatisticsQuery } from '../../domain/queries/get-statistics.query';
import { StatisticsRepository } from '../repositories/statistics.repository';

@QueryHandler(GetStatisticsQuery)
export class GetStatisticsHandler implements IQueryHandler<GetStatisticsQuery> {
  constructor(private readonly repo: StatisticsRepository) {}

  async execute() {
    return this.repo.countByType()

  }
}