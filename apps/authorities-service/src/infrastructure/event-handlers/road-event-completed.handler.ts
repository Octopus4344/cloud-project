import { Injectable, Logger } from '@nestjs/common';
import { IncidentRepository } from '../repositories/incident.repository';
import { RoadEventCompletedEvent } from '../../domain/events/road-event-completed.event';
import { NotifierService } from '../services/notifier.service';

@Injectable()
export class RoadEventCompletedHandler {
  private readonly logger = new Logger(RoadEventCompletedHandler.name);

  constructor(
    private readonly incidentRepository: IncidentRepository,
    private readonly notifier: NotifierService,
  ) {}

  async handle(evt: RoadEventCompletedEvent): Promise<void> {
    this.logger.log('Received road.event.completed', JSON.stringify(evt));

    const referenceNo = await this.notifier.notify(
      evt.eventType,
      evt.latitude,
      evt.longitude,
    );

    const saved = await this.incidentRepository.save({
      userId: evt.userId,
      authoritiesType: evt.eventType,
      eventId: evt.eventId,
      reportNumber: referenceNo,
    });

    this.logger.log('Saved incident', saved.incidentId);
  }
}
