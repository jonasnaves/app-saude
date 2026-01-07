export interface PatientAddress {
  street: string;
  number: string;
  complement?: string;
  neighborhood: string;
  city: string;
  state: string;
  zipCode: string;
}

export interface EmergencyContact {
  name: string;
  phone: string;
  relationship: string; // Ex: "Pai", "Mãe", "Cônjuge", etc.
}

export interface PatientDocument {
  id: string;
  name: string;
  type: string; // Ex: "PDF", "DOC", "IMAGE"
  url: string;
  uploadedAt: string;
  size?: number; // Tamanho em bytes
}

export interface Patient {
  id: string;
  // Dados pessoais
  name: string;
  cpf?: string;
  rg?: string;
  birthDate?: string; // ISO date string
  gender?: 'M' | 'F' | 'O' | 'N'; // Masculino, Feminino, Outro, Não informado
  phone?: string;
  email?: string;
  
  // Endereço
  address?: PatientAddress;
  
  // Informações de saúde
  allergies?: string[]; // Lista de alergias
  medicalHistory?: string; // Histórico médico em texto livre
  currentMedications?: string[]; // Medicamentos em uso
  chronicConditions?: string[]; // Condições crônicas
  
  // Contatos de emergência
  emergencyContacts?: EmergencyContact[];
  
  // Arquivos
  photos: string[]; // Array de URLs das fotos
  documents: PatientDocument[]; // Array de documentos
  
  // Metadados
  createdAt: string; // ISO date string
  updatedAt: string; // ISO date string
  createdBy?: string; // ID do usuário que criou (futuro)
}


