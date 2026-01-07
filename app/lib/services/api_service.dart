import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

// Importação condicional para BrowserHttpClientAdapter apenas em web
import 'package:dio/browser.dart' if (dart.library.io) 'package:dio/io.dart' as browser;

class ApiService {
  late Dio _dio;
  String? _sessionToken;
  bool _tokenLoaded = false;
  late final Future<void> _tokenLoadFuture;

  ApiService() {
    _tokenLoadFuture = _loadSessionToken();
    
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
      // Configurar para enviar cookies em requisições cross-origin
      followRedirects: true,
      validateStatus: (status) => status! < 500,
    ));

    // Configurar para enviar cookies em Flutter Web
    if (kIsWeb) {
      try {
        _dio.httpClientAdapter = browser.BrowserHttpClientAdapter()..withCredentials = true;
        print('[ApiService] BrowserHttpClientAdapter configurado com withCredentials=true');
      } catch (e) {
        print('[ApiService] Erro ao configurar BrowserHttpClientAdapter: $e');
      }
    }

    // Interceptor para adicionar token de autenticação
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Garantir que o token seja carregado antes da requisição
        if (!_tokenLoaded) {
          await _tokenLoadFuture;
        }
        
        options.headers['Content-Type'] = 'application/json';
        
        // Adicionar token de autenticação se disponível
        if (_sessionToken != null) {
          options.headers['Authorization'] = 'Bearer $_sessionToken';
          print('[ApiService] Token enviado no header Authorization: ${_sessionToken!.substring(0, 10)}...');
        } else {
          print('[ApiService] Nenhum token disponível para enviar');
        }
        
        handler.next(options);
      },
    ));
  }

  Future<void> _loadSessionToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      _tokenLoaded = true;
      if (_sessionToken != null) {
        print('[ApiService] Token carregado do SharedPreferences: ${_sessionToken!.substring(0, 10)}...');
      } else {
        print('[ApiService] Nenhum token encontrado no SharedPreferences');
      }
    } catch (e) {
      print('[ApiService] Erro ao carregar session token: $e');
      _tokenLoaded = true; // Marcar como carregado mesmo em caso de erro
    }
  }

  Future<void> setSessionToken(String? token) async {
    _sessionToken = token;
    _tokenLoaded = true; // Marcar como carregado após definir o token
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString('session_token', token);
        print('[ApiService] Token salvo no SharedPreferences: ${token.substring(0, 10)}...');
      } else {
        await prefs.remove('session_token');
        print('[ApiService] Token removido do SharedPreferences');
      }
    } catch (e) {
      print('[ApiService] Erro ao salvar session token: $e');
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data, Options? options}) {
    return _dio.post(path, data: data, options: options);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  String get baseUrl => ApiConstants.baseUrl;
}
