import {
  IsEnum,
  IsNumber,
  IsNotEmpty,
  IsOptional,
  IsString,
} from 'class-validator';
import { RoadEventType } from '../../domain/enums/road-event-type.enum';

export class CreateRoadEventDto {
  @IsNotEmpty()
  @IsString()
  userId: string;

  @IsNotEmpty()
  @IsEnum(RoadEventType)
  eventType: RoadEventType;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;
}
