import { RoadEventType } from '../enums/road-event-type.enum';

export class RoadEventEntity {
  id: number;
  created_at: Date;
  userId: string;
  latitude?: number;
  longitude?: number;
  eventType: RoadEventType;
}
