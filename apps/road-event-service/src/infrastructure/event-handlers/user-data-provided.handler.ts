import { EventPattern } from '@nestjs/microservices';
import { Controller, Injectable, Logger } from '@nestjs/common';
import { AggregateService } from '../services/aggregate.service';
import { UserDataProvidedEvent } from '../../domain/events/user-data-provided.event';

@Controller()
export class UserDataProvidedHandler {
  constructor(private agg: AggregateService) {}

  @EventPattern('user.data.provided')
  async handleUserDataProvided(event: UserDataProvidedEvent) {
    Logger.log('Received event:', event);
    await this.agg.onUserData(event);
  }
}