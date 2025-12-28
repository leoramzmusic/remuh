/// Excepción base de la aplicación
class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Excepción de audio
class AudioException extends AppException {
  AudioException(super.message, {super.code});

  @override
  String toString() =>
      'AudioException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Excepción de archivo no encontrado
class FileNotFoundException extends AppException {
  final String filePath;

  FileNotFoundException(this.filePath)
    : super('File not found: $filePath', code: 'FILE_NOT_FOUND');
}

/// Excepción de permisos
class PermissionDeniedException extends AppException {
  PermissionDeniedException(String permission)
    : super('Permission denied: $permission', code: 'PERMISSION_DENIED');
}
