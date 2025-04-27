import {
  Entity,
  Column, PrimaryGeneratedColumn, CreateDateColumn,
} from 'typeorm';
import { RoadEventType } from '../enums/road-event-type.enum';


@Entity('Statistics')
export class StatsEntity {
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


  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  @Column({ type: 'enum', enum: RoadEventType, enumName: 'road_event_type' })
  eventType: RoadEventType;

  @Column('double precision')
  latitude: number;

  @Column('double precision')
  longitude: number;

  @Column()
  userName: string;

  @Column()
  userLastName: string;

  @Column()
  birthDate: Date;
}
