import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthDataSource {
  final ApiService apiService;

  AuthDataSource(this.apiService);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await apiService.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final user = UserModel.fromJson(response.data['user']);
    final token = response.data['token'];
    final refreshToken = response.data['refreshToken'];

    await apiService.setTokens(token, refreshToken);

    return {
      'user': user,
      'token': token,
      'refreshToken': refreshToken,
    };
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await apiService.post(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    final user = UserModel.fromJson(response.data['user']);
    final token = response.data['token'];
    final refreshToken = response.data['refreshToken'];

    await apiService.setTokens(token, refreshToken);

    return {
      'user': user,
      'token': token,
      'refreshToken': refreshToken,
    };
  }

  Future<void> logout() async {
    await apiService.clearToken();
  }
}

