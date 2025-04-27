import { EventPattern } from '@nestjs/microservices';
import { Injectable } from '@nestjs/common';
import { AggregateService } from '../services/aggregate.service';
import { UserDataProvidedEvent } from '../../domain/events/user-data-provided.event';

@Injectable()
export class UserDataProvidedHandler {
  constructor(private agg: AggregateService) {}

  @EventPattern('user.data.provided')
  async handleUserDataProvided(event: UserDataProvidedEvent) {
    await this.agg.onUserData(event);
  }
}