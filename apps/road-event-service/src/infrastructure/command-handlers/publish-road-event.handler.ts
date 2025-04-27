import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { PublishRoadEventCommand } from '../../domain/commands/publish-road-event.command';
import { RoadEventRepository } from '../repositories/road-event.repository';
import { Inject, Logger } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { RoadEventCreatedEvent } from '../../domain/events/road-event-created.event';
import { StatusRepository } from '../repositories/status.repository';

@CommandHandler(PublishRoadEventCommand)
export class PublishRoadEventHandler
  implements ICommandHandler<PublishRoadEventCommand>
{
  constructor(
    private readonly roadEventRepository: RoadEventRepository,
    private readonly statusRepository: StatusRepository,
    @Inject('RMQ_EVENTS_BUS') private readonly rmq: ClientProxy,
  ) {}

  async execute(command: PublishRoadEventCommand) {
    const entity = await this.roadEventRepository.save({
      userId: command.userId,
      latitude: command.latitude,
      longitude: command.longitude,
      eventType: command.eventType,
    });
    await this.statusRepository.create(entity.id);
    const created = new RoadEventCreatedEvent(
      entity.id,
      entity.userId,
      entity.eventType,
      entity.latitude,
      entity.longitude,
    );
    Logger.log('Publishing event:', created);
    const result = this.rmq.emit('road.event.created', created);
    result.subscribe({
      next: (response) => Logger.log('Event published successfully:', response),
      error: (error) =>
        Logger.error(
          'Error publishing event:',
          error.stack ?? JSON.stringify(error),
        ),
    });
    return entity.id;
  }
}
