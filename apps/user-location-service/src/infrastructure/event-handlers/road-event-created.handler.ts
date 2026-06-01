import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LocationRepository } from '../repositories/location.repository';
import { RoadEventCreatedEvent } from '../../domain/events/road-event-created.event';
import { LocationDataProvidedEvent } from '../../domain/events/location-data-provided.event';
import { SqsProducerService } from '../messaging/sqs-producer.service';

// Bounding box for Poland – used as a fallback mock when the client
// did not provide GPS coordinates (e.g. during local testing).
const POLAND_LAT = { min: 49.0, max: 54.8 };
const POLAND_LON = { min: 14.1, max: 24.1 };

function randomInRange(min: number, max: number): number {
  return Math.round((min + Math.random() * (max - min)) * 1e6) / 1e6;
}

@Injectable()
export class RoadEventCreatedHandler {
  private readonly logger = new Logger(RoadEventCreatedHandler.name);

  constructor(
    private readonly locRepository: LocationRepository,
    private readonly sqsProducer: SqsProducerService,
    private readonly config: ConfigService,
  ) {}

  async handle(evt: RoadEventCreatedEvent): Promise<void> {
    this.logger.log('Received road.event.created', JSON.stringify(evt));

    // Use coordinates sent by the client device (GPS).
    // Fall back to random Polish coordinates for local/test environments.
    const latitude =
      evt.latitude ?? randomInRange(POLAND_LAT.min, POLAND_LAT.max);
    const longitude =
      evt.longitude ?? randomInRange(POLAND_LON.min, POLAND_LON.max);

    const saved = await this.locRepository.save({
      eventId: evt.id,
      userId: evt.userId,
      latitude,
      longitude,
    });

    this.logger.log('Saved location for event', saved.eventId);

    const event = new LocationDataProvidedEvent(
      evt.id,
      saved.latitude,
      saved.longitude,
    );

    this.logger.log(
      'Publishing user.location.provided back to road-event-queue',
    );
    await this.sqsProducer.send(
      this.config.get<string>('SQS_ROAD_EVENT_QUEUE_URL')!,
      'user.location.provided',
      event,
    );
  }
}
