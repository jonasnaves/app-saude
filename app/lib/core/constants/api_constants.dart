class ApiConstants {
  // Base URL - ajustar conforme ambiente
  // Para desenvolvimento local com Docker: localhost:3000
  // Para produção: alterar para URL do servidor
  static const String baseUrl = 'http://localhost:3000/api';
  static const String wsUrl = 'ws://localhost:3000/api/clinical/ws';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  
  // Clinical endpoints
  static const String startRecording = '/clinical/start-recording';
  static const String processChunk = '/clinical/process-chunk';
  static const String transcribe = '/clinical/transcribe';
  static const String analyzeIncremental = '/clinical/analyze-incremental';
  static const String generateSummary = '/clinical/generate-summary';
  static const String consultations = '/clinical/consultations';
  
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

