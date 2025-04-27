export class UserDataProvidedEvent {
  constructor(
    public readonly eventId: number,
    public readonly name: string,
    public readonly lastName: string,
    public readonly birthDate: Date,
    public readonly phoneNumber: string,
  ) {}
}