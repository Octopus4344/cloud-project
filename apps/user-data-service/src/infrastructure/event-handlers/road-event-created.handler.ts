import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UserDataProvidedEvent } from '../../domain/events/user-data-provided.event';
import { UserRepository } from '../repositories/user.repository';
import { SqsProducerService } from '../messaging/sqs-producer.service';

@Injectable()
export class RoadEventCreatedHandler {
  private readonly logger = new Logger(RoadEventCreatedHandler.name);

  constructor(
    private readonly userRepository: UserRepository,
    private readonly sqsProducer: SqsProducerService,
    private readonly config: ConfigService,
  ) {}

  async handle(msg: {
    id: string;
    userId: string;
    eventType: string;
    latitude?: number;
    longitude?: number;
  }): Promise<void> {
    this.logger.log('Received road.event.created', JSON.stringify(msg));

    const user = await this.userRepository.findById(String(msg.userId));
    if (!user) {
      throw new Error(`User with id ${msg.userId} not found`);
    }

    const event = new UserDataProvidedEvent(
      msg.id,
      user.name,
      user.lastName,
      user.birthDate as any,
      user.phoneNumber,
    );

    this.logger.log('Publishing user.data.provided back to road-event-queue');
    await this.sqsProducer.send(
      this.config.get<string>('SQS_ROAD_EVENT_QUEUE_URL')!,
      'user.data.provided',
      event,
    );
  }
}
