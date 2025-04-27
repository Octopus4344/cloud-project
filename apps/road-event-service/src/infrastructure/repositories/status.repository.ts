import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { EventStatusEntity } from '../../domain/entities/event-status.entity';

@Injectable()
export class StatusRepository {
  constructor(
    @InjectRepository(EventStatusEntity)
    private readonly statusRepository: Repository<EventStatusEntity>,
    private readonly dataSource: DataSource,
  ) {}

  create(eventId: number) {
    return this.statusRepository.save({ eventId });
  }

  markUser(eventId: string) {
    return this.dataSource
      .createQueryBuilder()
      .update(EventStatusEntity)
      .set({ userReceived: true })
      .where('eventId = :eventId', { eventId })
      .execute();
  }

  markLoc(eventId: string) {
    return this.dataSource
      .createQueryBuilder()
      .update(EventStatusEntity)
      .set({ locReceived: true })
      .where('eventId = :eventId', { eventId })
      .execute();
  }

  async isComplete(eventId: number) {
    const status = await this.statusRepository.findOneBy({ eventId });
    return status?.userReceived && status.locReceived;
  }
}
