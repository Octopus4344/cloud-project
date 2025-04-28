import { ClientProxy, EventPattern } from '@nestjs/microservices';
import { Controller, Inject, Injectable, Logger } from '@nestjs/common';
import { IncidentRepository } from '../repositories/incident.repository';
import { RoadEventCompletedEvent } from '../../domain/events/road-event-completed.event';
import { Column, CreateDateColumn, PrimaryGeneratedColumn } from 'typeorm';
import { RoadEventType } from '../../domain/enums/road-event-type.enum';
import { NotifierService } from '../services/notifier.service';


@Controller()
export class RoadEventCompletedHandler {
  constructor(
    private readonly incidentRepository: IncidentRepository,
    private readonly notifier: NotifierService,
  ) {}

  @EventPattern('road.event.completed')
  async handle(evt: RoadEventCompletedEvent) {
    Logger.log('Received event:', evt);

    const referenceNo = await this.notifier.notify(
      evt.eventType,
      evt.latitude,
      evt.longitude
    )

    const saved = await this.incidentRepository.save({
      userId: evt.userId,
      authoritiesType: evt.eventType,
      eventId: evt.eventId,
      reportNumber: referenceNo
    })
    Logger.log('Saved incident', evt.eventId, saved.id)
  }
}