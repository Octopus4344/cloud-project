import { RoadEventType } from '../enums/road-event-type.enum';

export class StatsEntity {
  id: number;
  created_at: Date;
  userId: string;
  eventType: RoadEventType;
  latitude: number;
  longitude: number;
  userName: string;
  userLastName: string;
  birthDate: Date;
}
