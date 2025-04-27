import { Controller, Injectable, Logger } from '@nestjs/common';
import { AggregateService } from '../services/aggregate.service';
import { EventPattern } from '@nestjs/microservices';
import { LocationDataProvidedEvent } from '../../domain/events/location-data-provided.event';

@Controller()
export class UserLocationProvidedHandler {
  constructor(private agg: AggregateService) {}

  @EventPattern('user.location.provided')
  async handleUserLocationProvided(event: LocationDataProvidedEvent) {
    Logger.log('Received event:', event);
    await this.agg.onLocation(event);
  }
}
