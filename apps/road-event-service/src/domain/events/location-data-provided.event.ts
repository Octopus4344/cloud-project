export class LocationDataProvidedEvent {
  constructor(
    public readonly eventId: number,
    public readonly latitude: number,
    public readonly longitude: number,
  ) {}
}