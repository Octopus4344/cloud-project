import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { StatsEntity } from '../../domain/entities/stats.entity';
import { Repository } from 'typeorm';

@Injectable()
export class StatisticsRepository {
  constructor(
    @InjectRepository(StatsEntity)
    private statsRepository: Repository<StatsEntity>,
  ) {}

  async save(partial: Partial<StatsEntity>) {
    return this.statsRepository.save(this.statsRepository.create(partial))
  }

  countByType() {
    return this.statsRepository
      .createQueryBuilder('s')
      .select('s."eventType"', 'type')
      .addSelect('COUNT(*)', 'count')
      .groupBy('s."eventType"')
      .getRawMany<{ type: string; count: string }>()
  }
}