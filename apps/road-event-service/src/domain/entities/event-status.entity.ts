import {
  Entity,
  PrimaryColumn,
  Column,
} from 'typeorm';

@Entity('EventStatuses')
export class EventStatusEntity {
  @PrimaryColumn({ type: 'bigint' })
  eventId: number;

  @Column({ default: false })
  userReceived: boolean;

  @Column({ default: false })
  locReceived: boolean;
}
