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

    print('[AuthDataSource] Status code: ${response.statusCode}');
    print('[AuthDataSource] Response data type: ${response.data.runtimeType}');
    print('[AuthDataSource] Response data: $response.data');

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

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    
    // Armazenar sessionToken se fornecido
    print('[AuthDataSource] Resposta do login: ${data.keys.toList()}');
    if (data['sessionToken'] != null) {
      print('[AuthDataSource] Token recebido do backend: ${(data['sessionToken'] as String).substring(0, 10)}...');
      await apiService.setSessionToken(data['sessionToken'] as String);
      print('[AuthDataSource] Token salvo no ApiService');
    } else {
      print('[AuthDataSource] ERRO: sessionToken não encontrado na resposta do login!');
      print('[AuthDataSource] Dados recebidos: $data');
    }

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

    final user = UserModel.fromJson(response.data['user']);
    
    // Armazenar sessionToken se fornecido
    if (response.data['sessionToken'] != null) {
      await apiService.setSessionToken(response.data['sessionToken'] as String);
    }

    return {
      'user': user,
    };
  }

  Future<void> logout() async {
    await apiService.post(ApiConstants.logout);
    // Limpar token local
    await apiService.setSessionToken(null);
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

