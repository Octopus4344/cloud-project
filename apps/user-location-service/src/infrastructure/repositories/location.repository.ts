import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { LocationEntity } from '../../domain/entities/location.entity';
import { Repository } from 'typeorm';

@Injectable()
export class LocationRepository {
  constructor(
    @InjectRepository(LocationEntity)
    private locationRepository: Repository<LocationEntity>,
  ) {}

  async findById(id: number): Promise<LocationEntity | null> {
    return this.locationRepository.findOneBy({ id });
  }

  async save(partial: { latitude: number; userId: number; longitude: number }) {
    return this.locationRepository.save(
      this.locationRepository.create(partial),
    );
  }
}