import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  late Dio _dio;
  String? _token;
  String? _refreshToken;
  bool _isRefreshing = false;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && _refreshToken != null && !_isRefreshing) {
          _isRefreshing = true;

          try {
            final newTokens = await _refreshAccessToken();
            if (newTokens != null) {
              // Retry da requisição original
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer ${newTokens['token']}';
              final response = await _dio.fetch(opts);
              handler.resolve(response);
              return;
            }
          } catch (e) {
            // Refresh falhou, limpar tokens
            await clearToken();
          } finally {
            _isRefreshing = false;
          }
        }
        return handler.next(error);
      },
    ));

    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> setTokens(String token, String refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> clearToken() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  Future<Map<String, String>?> _refreshAccessToken() async {
    if (_refreshToken == null) return null;

    try {
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': _refreshToken},
      );

      final newToken = response.data['token'] as String;
      final newRefreshToken = response.data['refreshToken'] as String;

      await setTokens(newToken, newRefreshToken);

      return {'token': newToken, 'refreshToken': newRefreshToken};
    } catch (e) {
      print('Error refreshing token: $e');
      return null;
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}

