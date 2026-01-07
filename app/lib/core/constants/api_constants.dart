class ApiConstants {
  // Base URL - ajustar conforme ambiente
  // Para desenvolvimento local com Docker: localhost:3000
  // Para produção: alterar para URL do servidor
  static const String baseUrl = 'http://195.35.16.183:3003/api';
  static const String wsUrl = 'ws://195.35.16.183:3003/api/clinical/ws';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  
  // Clinical endpoints
  static const String startRecording = '/clinical/start-recording';
  static const String processChunk = '/clinical/process-chunk';
  static const String transcribe = '/clinical/transcribe';
  static const String transcribeChunk = '/clinical/transcribe-chunk';
  static const String analyzeIncremental = '/clinical/analyze-incremental';
  static const String generateSummary = '/clinical/generate-summary';
  static const String processCascade = '/clinical/process-cascade';
  static const String chat = '/clinical/chat';
  static const String consultations = '/clinical/consultations';
  static const String saveMedicalRecord = '/clinical/save-medical-record';
  static const String finishConsultation = '/clinical/finish-consultation';
  static const String resumeConsultation = '/clinical/resume-consultation';
  
  // Patient endpoints
  static const String patients = '/patients';
  static String patientById(String id) => '/patients/$id';
  static String patientPhotos(String id) => '/patients/$id/photos';
  static String patientPhoto(String id, String photoId) => '/patients/$id/photos/$photoId';
  static String patientDocuments(String id) => '/patients/$id/documents';
  static String patientDocument(String id, String docId) => '/patients/$id/documents/$docId';
  
  // Support endpoints
  static const String supportChat = '/support/chat';
  static const String supportHistory = '/support/history';
  
  // Business endpoints
  static const String credits = '/business/credits';
  static const String drugs = '/business/drugs';
  static const String checkout = '/business/checkout';
  static const String transactions = '/business/transactions';
  
  // Dashboard endpoints
  static const String dashboardStats = '/dashboard/stats';
  static const String schedule = '/dashboard/schedule';
  
  // Analytics endpoints
  static const String analyticsTrack = '/analytics/track';
  static const String analyticsEvents = '/analytics/events';
  static const String analyticsStats = '/analytics/stats';
  
  // Performance endpoints
  static const String performanceMetrics = '/performance/metrics';
  static const String performanceStats = '/performance/stats';
  
  // Notifications endpoints
  static const String notificationsRegister = '/notifications/register';
}

