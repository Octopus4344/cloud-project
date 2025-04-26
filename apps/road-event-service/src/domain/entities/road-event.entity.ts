import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';
import { RoadEventType } from '../enums/road-event-type.enum';

@Entity('RoadEvents')
export class RoadEventEntity {
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

  @Column('double precision' , { nullable: true })
  latitude?: number;

  @Column('double precision', { nullable: true })
  longitude?: number;

  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  @Column({ type: 'enum', enum: RoadEventType, enumName: 'road_event_type' })
  eventType: RoadEventType;
}
