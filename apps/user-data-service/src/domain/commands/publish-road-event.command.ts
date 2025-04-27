import { RoadEventType } from '../enums/road-event-type.enum';
export class PublishRoadEventCommand {
  constructor(
    public readonly userId: number,
    public readonly eventType: RoadEventType,
    public readonly latitude?: number,
    public readonly longitude?: number,
  ) {}
}
