import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, OneToOne, JoinColumn } from 'typeorm';
import { Consultation } from './Consultation';

@Entity('medical_records')
export class MedicalRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @OneToOne(() => Consultation, consultation => consultation.medicalRecord)
  @JoinColumn()
  consultation: Consultation;

  @Column()
  consultationId: string;

  @Column({ type: 'text' })
  anamnesis: string;

  @Column({ type: 'text' })
  physicalExam: string;

  @Column('simple-array')
  diagnosisSuggestions: string[];

  @Column({ type: 'text' })
  conduct: string;

  @CreateDateColumn()
  createdAt: Date;
}

