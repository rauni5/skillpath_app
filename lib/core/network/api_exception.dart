/// Custom exception representing an API error response or client-side HTTP error.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  /// Factory constructor for network connection timeouts or dropped connections.
  factory ApiException.networkError([String? message]) {
    return ApiException(
      message ??
          'Network connection error. Please check your internet connection.',
      statusCode: null,
    );
  }

  /// Factory constructor for server-side errors (5xx).
  factory ApiException.serverError([String? message, int? statusCode]) {
    return ApiException(
      message ?? 'Server error occurred. Please try again later.',
      statusCode: statusCode ?? 500,
    );
  }

  /// Convenience helper to check if the error is an authorization failure.
  bool get isUnauthorized => statusCode == 401;

  /// Convenience helper to check if the resource was not found.
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
