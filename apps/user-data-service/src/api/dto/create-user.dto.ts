import { IsNumber, IsNotEmpty, IsDate } from 'class-validator';


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
