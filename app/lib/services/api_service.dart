import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';

// Importação condicional para BrowserHttpClientAdapter apenas em web
import 'package:dio/browser.dart' if (dart.library.io) 'package:dio/io.dart' as browser;

class ApiService {
  late Dio _dio;

  ApiService() {
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

    // Interceptor para garantir que cookies sejam enviados
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Em Flutter Web, os cookies são enviados automaticamente pelo navegador
        // mas precisamos garantir que a requisição seja feita com credentials
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
    ));
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

