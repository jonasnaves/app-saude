import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class SupportDataSource {
  final ApiService apiService;

  SupportDataSource(this.apiService);

  Future<String> chatWithAI({
    required String mode,
    required String message,
    required List<Map<String, String>> chatHistory,
    Map<String, dynamic>? context,
  }) async {
    final response = await apiService.post(
      ApiConstants.supportChat,
      data: {
        'mode': mode,
        'message': message,
        'chatHistory': chatHistory,
        if (context != null) 'context': context,
      },
    );

    return response.data['response'] as String;
  }
}
