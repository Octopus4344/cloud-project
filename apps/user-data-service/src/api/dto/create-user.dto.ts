import { IsEnum, IsNumber, IsNotEmpty, IsOptional, IsDate } from 'class-validator';
import { RoadEventType } from '../../domain/enums/road-event-type.enum';
import { Column, PrimaryGeneratedColumn } from 'typeorm';

export class CreateUserDto {

  @IsNotEmpty()
  @IsNumber()
  id: number;

  @IsNotEmpty()
  name: string;

  @IsNotEmpty()
  lastName: string;

  @IsNotEmpty()
  @IsDate()
  birthDate: Date;

  @IsNotEmpty()
  phoneNumber: string;

}
