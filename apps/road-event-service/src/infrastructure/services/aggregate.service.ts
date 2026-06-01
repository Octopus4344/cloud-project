import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { UserDataProvidedEvent } from '../../domain/events/user-data-provided.event';
import { LocationDataProvidedEvent } from '../../domain/events/location-data-provided.event';
import { StatusRepository } from '../repositories/status.repository';
import { RoadEventRepository } from '../repositories/road-event.repository';
import { RoadEventCompletedEvent } from '../../domain/events/road-event-completed.event';
import { SnsProducerService } from '../messaging/sns-producer.service';

@Injectable()
export class AggregateService {
  private readonly logger = new Logger(AggregateService.name);
  private readonly buffer = new Map<
    string,
    { data?: UserDataProvidedEvent; loc?: LocationDataProvidedEvent }
  >();

  constructor(
    private readonly statusRepository: StatusRepository,
    private readonly eventRepository: RoadEventRepository,
    private readonly snsProducer: SnsProducerService,
    private readonly config: ConfigService,
  ) {}

  async onUserData(e: UserDataProvidedEvent): Promise<void> {
    const key = String(e.eventId);
    this.buffer.set(key, { ...(this.buffer.get(key) ?? {}), data: e });
    await this.statusRepository.markUser(key);
    await this.tryComplete(key);
  }

  async onLocation(e: LocationDataProvidedEvent): Promise<void> {
    const key = String(e.eventId);
    this.buffer.set(key, { ...(this.buffer.get(key) ?? {}), loc: e });
    await this.statusRepository.markLoc(key);
    await this.tryComplete(key);
  }

  private async tryComplete(eventId: string): Promise<void> {
    this.logger.log(`Checking completion for event ${eventId}`);
    if (!(await this.statusRepository.isComplete(eventId))) return;

    this.logger.log(`Event ${eventId} is complete – publishing to SNS`);
    const evt = await this.eventRepository.findOne(eventId);
    const { data, loc } = this.buffer.get(eventId)!;

    const completed = new RoadEventCompletedEvent(
      eventId,
      evt!.userId,
      evt!.eventType,
      loc!.latitude,
      loc!.longitude,
      new Date(evt!.created_at),
      data!.name,
      data!.lastName,
      data!.birthDate,
      data!.phoneNumber,
    );

    await this.snsProducer.publish(
      this.config.get<string>('SNS_ROAD_EVENTS_COMPLETED_ARN')!,
      'road.event.completed',
      completed,
    );

    this.buffer.delete(eventId);
  }
}
