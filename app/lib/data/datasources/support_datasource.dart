import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class SupportDataSource {
  final ApiService apiService;

  SupportDataSource(this.apiService);

  Future<String> sendMessage(String message, String mode) async {
    final response = await apiService.post(
      ApiConstants.supportChat,
      data: {
        'message': message,
        'mode': mode,
      },
    );
    return response.data['response'];
  }

  Future<List<dynamic>> getChatHistory({String? mode}) async {
    final response = await apiService.get(
      ApiConstants.supportHistory,
      queryParameters: mode != null ? {'mode': mode} : null,
    );
    return response.data;
  }
}

