enum ErrorCode {
  validationError,
  authenticationError,
  authorizationError,
  notFound,
  conflict,
  internalError,
  externalServiceError,
  networkError,
  timeoutError,
}

class AppError implements Exception {
  final ErrorCode code;
  final String message;
  final Map<String, dynamic>? details;

  AppError({
    required this.code,
    required this.message,
    this.details,
  });

  factory AppError.fromJson(Map<String, dynamic> json) {
    return AppError(
      code: _parseErrorCode(json['code']),
      message: json['message'] ?? 'Erro desconhecido',
      details: json['details'],
    );
  }

  static ErrorCode _parseErrorCode(String? code) {
    switch (code) {
      case 'VALIDATION_ERROR':
        return ErrorCode.validationError;
      case 'AUTHENTICATION_ERROR':
        return ErrorCode.authenticationError;
      case 'AUTHORIZATION_ERROR':
        return ErrorCode.authorizationError;
      case 'NOT_FOUND':
        return ErrorCode.notFound;
      case 'CONFLICT':
        return ErrorCode.conflict;
      case 'EXTERNAL_SERVICE_ERROR':
        return ErrorCode.externalServiceError;
      default:
        return ErrorCode.internalError;
    }
  }

  @override
  String toString() => message;
}

