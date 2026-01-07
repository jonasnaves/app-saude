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

    // Verificar se a resposta foi bem-sucedida
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao fazer login: ${response.statusMessage ?? 'Erro desconhecido'}');
    }

    // Verificar se response.data não é null
    if (response.data == null) {
      throw Exception('Resposta do servidor está vazia');
    }

    // Verificar se response.data é um Map
    if (response.data is! Map<String, dynamic>) {
      throw Exception('Resposta do servidor em formato inválido: ${response.data.runtimeType}');
    }

    final data = response.data as Map<String, dynamic>;

    // Verificar se 'user' existe na resposta
    if (data['user'] == null) {
      throw Exception('Resposta do servidor não contém dados do usuário');
    }

    // Cookies são gerenciados automaticamente pelo navegador
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    return {
      'user': user,
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

    // Cookies são gerenciados automaticamente pelo navegador
    final user = UserModel.fromJson(response.data['user']);

    return {
      'user': user,
    };
  }

  Future<void> logout() async {
    await apiService.post(ApiConstants.logout);
    // Cookie será limpo pelo backend
  }

  Future<UserModel> getCurrentUser() async {
    final response = await apiService.get(ApiConstants.me);

    // Verificar se a resposta foi bem-sucedida
    if (response.statusCode != 200) {
      throw Exception('Erro ao obter usuário atual: ${response.statusMessage ?? 'Erro desconhecido'}');
    }

    // Verificar se response.data não é null
    if (response.data == null) {
      throw Exception('Resposta do servidor está vazia');
    }

    // Verificar se response.data é um Map
    if (response.data is! Map<String, dynamic>) {
      throw Exception('Resposta do servidor em formato inválido: ${response.data.runtimeType}');
    }

    final data = response.data as Map<String, dynamic>;

    // Verificar se 'user' existe na resposta
    if (data['user'] == null) {
      throw Exception('Resposta do servidor não contém dados do usuário');
    }

    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }
}

