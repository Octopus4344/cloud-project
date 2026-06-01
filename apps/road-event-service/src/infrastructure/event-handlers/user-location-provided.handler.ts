import { Injectable, Logger } from '@nestjs/common';
import { AggregateService } from '../services/aggregate.service';
import { LocationDataProvidedEvent } from '../../domain/events/location-data-provided.event';

@Injectable()
export class UserLocationProvidedHandler {
  private readonly logger = new Logger(UserLocationProvidedHandler.name);

  constructor(private agg: AggregateService) {}

  async handle(event: LocationDataProvidedEvent): Promise<void> {
    this.logger.log('Received user.location.provided', JSON.stringify(event));
    await this.agg.onLocation(event);
  }
}
