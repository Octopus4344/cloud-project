import { Injectable, Logger } from '@nestjs/common';
import { AggregateService } from '../services/aggregate.service';
import { UserDataProvidedEvent } from '../../domain/events/user-data-provided.event';

@Injectable()
export class UserDataProvidedHandler {
  private readonly logger = new Logger(UserDataProvidedHandler.name);

  constructor(private agg: AggregateService) {}

  async handle(event: UserDataProvidedEvent): Promise<void> {
    this.logger.log('Received user.data.provided', JSON.stringify(event));
    await this.agg.onUserData(event);
  }
}
