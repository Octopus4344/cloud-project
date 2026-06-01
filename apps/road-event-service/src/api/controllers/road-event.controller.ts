import { Controller, Post, Body, UseGuards, Request } from '@nestjs/common';
import { CommandBus } from '@nestjs/cqrs';
import { PublishRoadEventCommand } from '../../domain/commands/publish-road-event.command';
import { CreateRoadEventDto } from '../dto/create-road-event.dto';
import { JwtAuthGuard } from '../../infrastructure/auth/jwt-auth.guard';

@Controller('events')
export class RoadEventController {
  constructor(private readonly commandBus: CommandBus) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  async create(
    @Request() req: any,
    @Body() createRoadEventDto: CreateRoadEventDto,
  ) {
    const userId: string = req.user.userId;
    const id: string = await this.commandBus.execute(
      new PublishRoadEventCommand(
        userId,
        createRoadEventDto.eventType,
        createRoadEventDto.latitude,
        createRoadEventDto.longitude,
      ),
    );
    return { eventId: id };
  }
}
