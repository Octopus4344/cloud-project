export class RoadEventCompletedEvent {
  constructor(
    public readonly eventId: number,
    public readonly userId: number,
    public readonly eventType: string,
    public readonly latitude: number,
    public readonly longitude: number,
    public readonly created_at: Date,
    public readonly name: string,
    public readonly lastName: string,
    public readonly birthDate: Date,
    public readonly phoneNumber: string,
  ) {}
}