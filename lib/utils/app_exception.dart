class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class AuthException extends AppException {
  AuthException(super.message, {super.code, super.originalError});
}

class FirestoreException extends AppException {
  FirestoreException(super.message, {super.code, super.originalError});
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.code, super.originalError});
} 