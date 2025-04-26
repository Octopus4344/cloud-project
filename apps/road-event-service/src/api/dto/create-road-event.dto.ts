import { IsEnum, IsNumber, IsNotEmpty, IsOptional } from 'class-validator';
import { RoadEventType } from '../../domain/enums/road-event-type.enum';

export class CreateRoadEventDto {
  @IsNotEmpty()
  @IsNumber()
  userId: number;

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
