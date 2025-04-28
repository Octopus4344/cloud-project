import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserEntity } from '../../domain/entities/user.entity';

@Injectable()
export class UserRepository {
  constructor(
    @InjectRepository(UserEntity)
    private roadEventRepository: Repository<UserEntity>,
  ) {}

  findById(id: number) {
    return this.roadEventRepository.findOneBy({ id });
  }

  create(data: Partial<UserEntity>) {
    const user = this.roadEventRepository.create(data)
    return this.roadEventRepository.save(user)
  }
}
