import { ClientProxy, EventPattern } from '@nestjs/microservices';
import { Inject, Injectable, Logger } from '@nestjs/common';
import { UserDataProvidedEvent } from '../../domain/events/user-data-provided.event';
import { UserRepository } from '../repositories/user.repository';

@Injectable()
export class RoadEventCreatedHandler {
  constructor(
    private readonly userRepository: UserRepository,
    @Inject('RMQ_EVENTS_BUS') private readonly rmq: ClientProxy,
  ) {}

  @EventPattern('road.event.created')
  async handle(msg: {id: number, userId: number}) {
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
    this.rmq.emit('user.data.provided', event);
  }
}