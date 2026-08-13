class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final StackTrace? stackTrace;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('ApiException: $message')
      ..write(statusCode != null ? ' (Status Code: $statusCode)' : '');

    if (data != null) {
      buffer.write('\nResponse data: $data');
    }

    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }

    return buffer.toString();
  }
}
