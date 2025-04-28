import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IncidentEntity } from '../../domain/entities/incident.entity';
import { Repository } from 'typeorm';

@Injectable()
export class IncidentRepository {
  constructor(
    @InjectRepository(IncidentEntity)
    private incidentEntityRepository: Repository<IncidentEntity>,
  ) {}

  async save(partial: Omit<IncidentEntity, 'id' | 'created_at'>) {
    return this.incidentEntityRepository.save(this.incidentEntityRepository.create(partial))
  }
}