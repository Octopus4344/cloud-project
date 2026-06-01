import { IQueryHandler, QueryHandler } from '@nestjs/cqrs';
import { GetStatisticsQuery } from '../../domain/queries/get-statistics.query';
import { IncidentRepository } from '../repositories/incident.repository';

@QueryHandler(GetStatisticsQuery)
export class GetStatisticsHandler implements IQueryHandler<GetStatisticsQuery> {
  constructor(private readonly repo: IncidentRepository) {}

  async execute() {
    return this.repo.countByType();
  }
}
