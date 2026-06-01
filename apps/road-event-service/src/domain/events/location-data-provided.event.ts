export class LocationDataProvidedEvent {
  constructor(
    public readonly eventId: string,
    public readonly latitude: number,
    public readonly longitude: number,
  ) {}
}
