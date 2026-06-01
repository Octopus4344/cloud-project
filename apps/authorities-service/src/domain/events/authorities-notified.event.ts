export class AuthoritiesNotifiedEvent {
  constructor(
    public readonly eventId: string,
    public readonly created_at: Date,
    public readonly userId: string,
    public readonly authoritiesType: string,
    public readonly reportNumber: number,
  ) {}
}
