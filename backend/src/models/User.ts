import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, OneToMany } from 'typeorm';
import { Consultation } from './Consultation';
import { SupportChat } from './SupportChat';
import { Transaction } from './Transaction';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ unique: true })
  email: string;

  @Column()
  passwordHash: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  credits: number;

  @CreateDateColumn()
  createdAt: Date;

  @OneToMany(() => Consultation, consultation => consultation.user)
  consultations: Consultation[];

  @OneToMany(() => SupportChat, chat => chat.user)
  supportChats: SupportChat[];

  @OneToMany(() => Transaction, transaction => transaction.user)
  transactions: Transaction[];
}

