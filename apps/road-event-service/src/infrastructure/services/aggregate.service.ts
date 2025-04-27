import { Inject, Injectable } from '@nestjs/common';
import { UserDataProvidedEvent } from '../../domain/events/user-data-provided.event';
import { LocationDataProvidedEvent } from '../../domain/events/location-data-provided.event';
import { StatusRepository } from '../repositories/status.repository';
import { RoadEventRepository } from '../repositories/road-event.repository';
import { ClientProxy } from '@nestjs/microservices';
import { RoadEventCompletedEvent } from '../../domain/events/road-event-completed.event';


@Injectable()
export class AggregateService {
  private readonly buffer = new Map<
    string,
    { data?: UserDataProvidedEvent; loc?: LocationDataProvidedEvent }>();

  constructor(
    private readonly statusRepository: StatusRepository,
    private readonly eventRepository: RoadEventRepository,
    @Inject('RMQ_EVENTS_BUS') private readonly rmq: ClientProxy,
  ) {
  }

  async onUserData(e: UserDataProvidedEvent) {
    this.buffer.set(e.eventId.toString(), { ...(this.buffer.get(e.eventId.toString()) || {}), data: e });
    await this.statusRepository.markUser(e.eventId.toString());
    await this.tryComplete(e.eventId);
  }

  async onLocation(e: LocationDataProvidedEvent) {
    this.buffer.set(e.eventId.toString(), { ...(this.buffer.get(e.eventId.toString()) || {}), loc: e });
    await this.statusRepository.markLoc(e.eventId.toString());
    await this.tryComplete(e.eventId);
  }

  private async tryComplete(eventId: number) {
    if (!(await this.statusRepository.isComplete(eventId))) return;
    const evt = await this.eventRepository.findOne(eventId);
    const { data, loc } = this.buffer.get(eventId.toString())!;
    const completed = new RoadEventCompletedEvent(
      eventId,
      evt!.userId,
      evt!.eventType,
      loc!.latitude,
      loc!.longitude,
      evt!.created_at,
      data!.name,
      data!.lastName,
      data!.birthDate,
      data!.phoneNumber,
    )
    this.rmq.emit('road-event.completed', completed);
    this.buffer.delete(eventId.toString());


  }
}