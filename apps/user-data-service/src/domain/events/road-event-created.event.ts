export class RoadEventCreatedEvent {
  constructor(
    public readonly id: number,
    public readonly userId: number,
    public readonly eventType: string,
    public readonly latitude?: number,
    public readonly longitude?: number,
  ) {}
}