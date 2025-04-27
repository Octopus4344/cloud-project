import { ClientProxy, EventPattern } from '@nestjs/microservices';
import { Controller, Inject, Injectable, Logger } from '@nestjs/common';
import { StatisticsRepository } from '../repositories/statistics.repository';
import { RoadEventCompletedEvent } from '../../domain/events/road-event-completed.event';
import { Column, CreateDateColumn, PrimaryGeneratedColumn } from 'typeorm';
import { RoadEventType } from '../../domain/enums/road-event-type.enum';


@Controller()
export class RoadEventCompletedHandler {
  constructor(
    private readonly statRepository: StatisticsRepository,
  ) {}

  @EventPattern('road.event.completed')
  async handle(evt: RoadEventCompletedEvent) {
    Logger.log('Received event:', evt);

    const saved = await this.statRepository.save({
      userId: evt.userId,
      eventType: evt.eventType as RoadEventType,
      latitude: evt.latitude,
      longitude: evt.longitude,
      userName: evt.name,
      userLastName: evt.lastName,
      birthDate: evt.birthDate,
    })

    Logger.log('Saved event stat', evt.eventId, saved.id)
  }
}