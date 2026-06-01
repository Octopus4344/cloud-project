import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { PublishRoadEventCommand } from '../../domain/commands/publish-road-event.command';
import { RoadEventRepository } from '../repositories/road-event.repository';
import { StatusRepository } from '../repositories/status.repository';
import { RoadEventCreatedEvent } from '../../domain/events/road-event-created.event';
import { SqsProducerService } from '../messaging/sqs-producer.service';

@CommandHandler(PublishRoadEventCommand)
export class PublishRoadEventHandler
  implements ICommandHandler<PublishRoadEventCommand>
{
  private readonly logger = new Logger(PublishRoadEventHandler.name);

  constructor(
    private readonly roadEventRepository: RoadEventRepository,
    private readonly statusRepository: StatusRepository,
    private readonly sqsProducer: SqsProducerService,
    private readonly config: ConfigService,
  ) {}

  async execute(command: PublishRoadEventCommand): Promise<string> {
    const entity = await this.roadEventRepository.save({
      userId: command.userId,
      latitude: command.latitude ?? null,
      longitude: command.longitude ?? null,
      eventType: command.eventType,
    });

    await this.statusRepository.create(entity.eventId);

    const created = new RoadEventCreatedEvent(
      entity.eventId,
      entity.userId,
      entity.eventType,
      entity.latitude ?? undefined,
      entity.longitude ?? undefined,
    );

    this.logger.log(
      'Publishing road.event.created to user-data and user-location queues',
    );

    await Promise.all([
      this.sqsProducer.send(
        this.config.get<string>('SQS_USER_DATA_QUEUE_URL')!,
        'road.event.created',
        created,
      ),
      this.sqsProducer.send(
        this.config.get<string>('SQS_USER_LOCATION_QUEUE_URL')!,
        'road.event.created',
        created,
      ),
    ]);

    return entity.eventId;
  }
}
