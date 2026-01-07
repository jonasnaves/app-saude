export interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  createdAt: string;
  updatedAt: string;
  // password_hash nunca é retornado
}

export interface UserWithPassword extends User {
  passwordHash: string; // Apenas para uso interno
}


