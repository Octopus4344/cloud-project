import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RoadEventEntity } from '../../domain/entities/road-event.entity';

@Injectable()
export class RoadEventRepository {
  constructor(
    @InjectRepository(RoadEventEntity)
    private readonly roadEventRepository: Repository<RoadEventEntity>,
  ) {}

  save(partial: Omit<RoadEventEntity, 'id' | 'created_at'>) {
    return this.roadEventRepository.save(
      this.roadEventRepository.create(partial),
    );
  }
}
