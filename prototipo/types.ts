
export enum AppPillar {
  DASHBOARD = 'dashboard',
  CLINICAL = 'clinical',
  SUPPORT = 'support',
  BUSINESS = 'business'
}

export enum SupportMode {
  MEDICAL = 'medical',
  LEGAL = 'legal',
  MARKETING = 'marketing'
}

export interface PatientRecord {
  id: string;
  name: string;
  lastVisit: string;
  nextAppointment: string;
}

export interface Prescription {
  drugName: string;
  dosage: string;
  instructions: string;
}

export interface TranscriptionSummary {
  anamnesis: string;
  physicalExam: string;
  diagnosisSuggestions: string[];
  conduct: string;
}
