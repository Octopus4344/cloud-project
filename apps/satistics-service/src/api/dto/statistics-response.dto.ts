import { IsEnum, IsNumber, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { RoadEventType } from '../../domain/enums/road-event-type.enum';

export class StatisticsResponseDto {
  @IsNotEmpty()
  @IsString()
  type: RoadEventType;

  @IsNotEmpty()
  @IsNumber()
  count: number;

}
