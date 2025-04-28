import {
  Entity,
  Column, PrimaryGeneratedColumn, CreateDateColumn,
} from 'typeorm';
import { RoadEventType } from '../enums/road-event-type.enum';


@Entity('AuthoritiesCalls')
export class IncidentEntity {
  @PrimaryGeneratedColumn('increment', { type: 'bigint' })
  id: number;

  @CreateDateColumn({
    type: 'timestamptz',
    name: 'created_at',
    default: () => 'CURRENT_TIMESTAMP',
  })
  created_at: Date;

  @Column('bigint', { name: 'userId' })
  userId: number;

  @Column('bigint', { name: 'eventId' })
  eventId: number;

  @Column()
  authoritiesType: string

  @Column()
  reportNumber: number
}
