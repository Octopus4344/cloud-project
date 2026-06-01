import { Controller, Post, Body, BadRequestException } from '@nestjs/common';
import { CreateUserDto } from '../dto/create-user.dto';
import { UserRepository } from '../../infrastructure/repositories/user.repository';
import { CognitoService } from '../../infrastructure/services/cognito.service';

@Controller('users')
export class UserController {
  constructor(
    private readonly userRepo: UserRepository,
    private readonly cognitoService: CognitoService,
  ) {}

  @Post()
  async create(@Body() createUserDto: CreateUserDto) {
    try {
      const cognitoSub = await this.cognitoService.registerUser(
        createUserDto.email,
        createUserDto.password,
      );
      const user = await this.userRepo.create(
        createUserDto,
        cognitoSub ?? undefined,
      );
      return { id: user.userId };
    } catch (e) {
      throw new BadRequestException('User had not been created');
    }
  }
}
