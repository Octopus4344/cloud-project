import { Injectable, Logger } from '@nestjs/common';
import { StatisticsRepository } from '../repositories/statistics.repository';
import { RoadEventCompletedEvent } from '../../domain/events/road-event-completed.event';
import { RoadEventType } from '../../domain/enums/road-event-type.enum';

@Injectable()
export class RoadEventCompletedHandler {
  private readonly logger = new Logger(RoadEventCompletedHandler.name);

  constructor(private readonly statRepository: StatisticsRepository) {}

  async handle(evt: RoadEventCompletedEvent): Promise<void> {
    this.logger.log('Received road.event.completed', JSON.stringify(evt));

    const saved = await this.statRepository.save({
      userId: evt.userId,
      eventType: evt.eventType as RoadEventType,
      latitude: evt.latitude,
      longitude: evt.longitude,
      userName: evt.name,
      userLastName: evt.lastName,
      birthDate: evt.birthDate as any,
    });

    this.logger.log('Saved statistics record', saved.statId);
  }
}
