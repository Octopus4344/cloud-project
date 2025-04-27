import { ClientProxy, EventPattern } from '@nestjs/microservices';
import { Controller, Inject, Injectable, Logger } from '@nestjs/common';
import { LocationRepository } from '../repositories/location.repository';
import { RoadEventCreatedEvent } from '../../domain/events/road-event-created.event';
import { LocationDataProvidedEvent } from '../../domain/events/location-data-provided.event';


@Controller()
export class RoadEventCreatedHandler {
  constructor(
    private readonly locRepository: LocationRepository,
    @Inject('RMQ_LOCATION_BUS') private readonly rmq: ClientProxy,
  ) {}

  @EventPattern('road.event.created')
  async handle(evt: RoadEventCreatedEvent) {
    Logger.log('Received event:', evt);
    const lat = (Math.random() - 0.5) * 0.01
    const long = (Math.random() - 0.5) * 0.01

    const saved = await this.locRepository.save({
      userId: evt.userId,
      latitude: lat,
      longitude: long,
    })
    Logger.log('Saved location:', JSON.stringify(saved));

    const event = new LocationDataProvidedEvent(
      evt.id,
      saved.latitude,
      saved.longitude,
    );

    Logger.log('Publishing event:', event);
    const result = this.rmq.emit('user.location.provided', event);
    result.subscribe({
      next: (response) => Logger.log('Event published successfully:', response),
      error: (error) =>
        Logger.error(
          'Error publishing event:',
          error.stack ?? JSON.stringify(error),
        ),
    });
  }
}