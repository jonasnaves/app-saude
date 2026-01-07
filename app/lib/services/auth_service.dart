import '../data/datasources/auth_datasource.dart';
import '../services/api_service.dart';
import '../data/models/user_model.dart';

class AuthService {
  final AuthDataSource _authDataSource = AuthDataSource(ApiService());
  UserModel? _currentUser;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> checkAuth() async {
    try {
      _currentUser = await _authDataSource.getCurrentUser();
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _currentUser = null;
      _isAuthenticated = false;
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    final result = await _authDataSource.login(email, password);
    _currentUser = result['user'] as UserModel;
    _isAuthenticated = true;
  }

  Future<void> register(String name, String email, String password) async {
    final result = await _authDataSource.register(name, email, password);
    _currentUser = result['user'] as UserModel;
    _isAuthenticated = true;
  }

  Future<void> logout() async {
    await _authDataSource.logout();
    _currentUser = null;
    _isAuthenticated = false;
  }
}


