import { Controller, Post, Body } from '@nestjs/common';
import { CommandBus } from '@nestjs/cqrs';
import { PublishRoadEventCommand } from '../../domain/commands/publish-road-event.command';
import { CreateRoadEventDto } from '../dto/create-road-event.dto';

@Controller('road-events')
export class RoadEventController {
  constructor(private readonly commandBus: CommandBus) {}

  @Post()
  async create(@Body() createRoadEventDto: CreateRoadEventDto) {
    const id: number = await this.commandBus.execute(
      new PublishRoadEventCommand(
        createRoadEventDto.userId,
        createRoadEventDto.eventType,
        createRoadEventDto.latitude,
        createRoadEventDto.longitude,
      ),
    );
    return { eventId: id };
  }
}
