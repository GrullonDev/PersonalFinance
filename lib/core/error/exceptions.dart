class ApiException implements Exception {
  ApiException({required this.message, required this.statusCode, this.data});

  final String message;
  final int statusCode;
  final dynamic data;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}
