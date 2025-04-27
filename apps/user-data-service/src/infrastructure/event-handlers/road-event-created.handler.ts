import { ClientProxy, EventPattern } from '@nestjs/microservices';
import { Controller, Inject, Injectable, Logger } from '@nestjs/common';
import { UserDataProvidedEvent } from '../../domain/events/user-data-provided.event';
import { UserRepository } from '../repositories/user.repository';

@Controller()
export class RoadEventCreatedHandler {
  constructor(
    private readonly userRepository: UserRepository,
    @Inject('RMQ_USERS_BUS') private readonly rmq: ClientProxy,
  ) {}

  @EventPattern('road.event.created')
  async handle(msg: {id: number, userId: number, eventType: string, latitude: number | null, longitude: number | null}) {
    Logger.log('Received event:', msg);
    const user = await this.userRepository.findById(msg.userId);
    if (!user) {
      throw new Error(`User with id ${msg.userId} not found`);
    }
    const event = new UserDataProvidedEvent(
      msg.id,
      user.name,
      user.lastName,
      user.birthDate,
      user.phoneNumber,
    );

    Logger.log('Publishing event:', event);
    const result = this.rmq.emit('user.data.provided', event);
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