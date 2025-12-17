import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import { User } from './User';
import { MedicalRecord } from './MedicalRecord';

@Entity('consultations')
export class Consultation {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, user => user.consultations)
  user: User;

  @Column()
  userId: string;

  @Column({ nullable: true })
  patientName: string;

  @Column({ type: 'text', nullable: true })
  transcript: string;

  @Column({ type: 'timestamp' })
  startedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  endedAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @OneToOne(() => MedicalRecord, medicalRecord => medicalRecord.consultation, { cascade: true })
  @JoinColumn()
  medicalRecord: MedicalRecord;
}

