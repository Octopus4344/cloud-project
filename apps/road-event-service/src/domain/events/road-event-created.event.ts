export class RoadEventCreatedEvent {
  constructor(
    public readonly id: string,
    public readonly userId: string,
    public readonly eventType: string,
    public readonly latitude?: number,
    public readonly longitude?: number,
  ) {}
}
