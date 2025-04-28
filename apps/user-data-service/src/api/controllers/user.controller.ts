import { Controller, Post, Body, BadRequestException } from '@nestjs/common';
import { CommandBus } from '@nestjs/cqrs';
import { PublishRoadEventCommand } from '../../domain/commands/publish-road-event.command';
import { CreateUserDto } from '../dto/create-user.dto';
import { UserRepository } from '../../infrastructure/repositories/user.repository';

@Controller('users')
export class UserController {
  constructor(private readonly userRepo: UserRepository) {}

  @Post()
  async create(@Body() createUserDto: CreateUserDto) {
    try {
      const user = await this.userRepo.create(createUserDto)
      return { id: user.id }
    } catch (e) {
      throw new BadRequestException('User hadn\'t been created')
    }
  }
}
