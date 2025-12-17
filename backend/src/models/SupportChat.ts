import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne } from 'typeorm';
import { User } from './User';

export enum SupportMode {
  MEDICAL = 'medical',
  LEGAL = 'legal',
  MARKETING = 'marketing',
}

@Entity('support_chats')
export class SupportChat {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, user => user.supportChats)
  user: User;

  @Column()
  userId: string;

  @Column({
    type: 'enum',
    enum: SupportMode,
  })
  mode: SupportMode;

  @Column('jsonb')
  messages: Array<{ role: 'user' | 'bot'; text: string; timestamp: Date }>;

  @CreateDateColumn()
  createdAt: Date;
}

