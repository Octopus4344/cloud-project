import {
  Entity,
  Column, PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('Users')
export class UserEntity {
  @PrimaryGeneratedColumn('increment', { type: 'bigint' })
  id: number;

  @Column()
  name: string;

  @Column()
  lastName: string;

  @Column({ type: 'date', nullable: true })
  birthDate?: Date;

  @Column()
  phoneNumber: string;
}
