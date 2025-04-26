import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { PublishRoadEventCommand } from '../../domain/commands/publish-road-event.command';
import { RoadEventRepository } from '../repositories/road-event.repository';
import { Inject } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';

@CommandHandler(PublishRoadEventCommand)
export class PublishRoadEventHandler
  implements ICommandHandler<PublishRoadEventCommand>
{
  constructor(
    private readonly roadEventRepository: RoadEventRepository,
    @Inject('RMQ_EVENTS_BUS') private readonly rmq: ClientProxy,
  ) {}

  async execute(command: PublishRoadEventCommand) {
    const entity = await this.roadEventRepository.save({
      userId: command.userId,
      latitude: command.latitude,
      longitude: command.longitude,
      eventType: command.eventType,
    });
    this.rmq.emit('road.event.created', {
      eventId: entity.id,
      userId: entity.userId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      eventType: entity.eventType,
    });
    return entity.id;
  }
}
