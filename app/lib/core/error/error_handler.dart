import 'package:dio/dio.dart';
import 'app_error.dart';

class ErrorHandler {
  static AppError handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          code: ErrorCode.timeoutError,
          message: 'Tempo de conexão esgotado. Verifique sua internet.',
        );
      case DioExceptionType.badResponse:
        if (error.response != null) {
          try {
            return AppError.fromJson(error.response!.data['error'] ?? {});
          } catch (e) {
            return AppError(
              code: ErrorCode.internalError,
              message: 'Erro ao processar resposta do servidor',
            );
          }
        }
        return AppError(
          code: ErrorCode.internalError,
          message: 'Erro de comunicação com o servidor',
        );
      case DioExceptionType.cancel:
        return AppError(
          code: ErrorCode.internalError,
          message: 'Requisição cancelada',
        );
      case DioExceptionType.unknown:
      default:
        if (error.error.toString().contains('SocketException')) {
          return AppError(
            code: ErrorCode.networkError,
            message: 'Sem conexão com a internet',
          );
        }
        return AppError(
          code: ErrorCode.internalError,
          message: 'Erro desconhecido: ${error.message}',
        );
    }
  }

  static AppError handleError(dynamic error) {
    if (error is DioException) {
      return handleDioError(error);
    }
    if (error is AppError) {
      return error;
    }
    return AppError(
      code: ErrorCode.internalError,
      message: error.toString(),
    );
  }
}

