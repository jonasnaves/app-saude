import '../core/constants/api_constants.dart';
import 'api_service.dart';

class AnalyticsService {
  final ApiService _apiService = ApiService();

  Future<void> trackEvent({
    required String event,
    required String category,
    Map<String, dynamic>? properties,
  }) async {
    try {
      await _apiService.post(
        '/analytics/track',
        data: {
          'event': event,
          'category': category,
          'properties': properties ?? {},
        },
      );
    } catch (e) {
      // Falha silenciosa - analytics não deve quebrar o app
      print('Error tracking event: $e');
    }
  }

  // Eventos pré-definidos
  Future<void> trackConsultationStarted() async {
    await trackEvent(
      event: 'consultation_started',
      category: 'clinical',
    );
  }

  Future<void> trackConsultationCompleted(String consultationId) async {
    await trackEvent(
      event: 'consultation_completed',
      category: 'clinical',
      properties: {'consultationId': consultationId},
    );
  }

  Future<void> trackDrugSearched(String searchTerm) async {
    await trackEvent(
      event: 'drug_searched',
      category: 'business',
      properties: {'searchTerm': searchTerm},
    );
  }

  Future<void> trackSupportChatUsed(String mode) async {
    await trackEvent(
      event: 'support_chat_used',
      category: 'support',
      properties: {'mode': mode},
    );
  }

  Future<void> trackScreenView(String screenName) async {
    await trackEvent(
      event: 'screen_view',
      category: 'navigation',
      properties: {'screen': screenName},
    );
  }
}

