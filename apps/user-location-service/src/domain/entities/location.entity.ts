import {
  Entity,
  PrimaryColumn,
  Column, PrimaryGeneratedColumn, CreateDateColumn,
} from 'typeorm';

@Entity('UserLocations')
export class LocationEntity {
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
  latitude: number;

  @Column('double precision', { nullable: true })
  longitude: number;
}
