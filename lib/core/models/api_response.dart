/// { "success": bool, "data": T, "message": string, "timestamp": string }
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? timestamp;

  ApiResponse({required this.success, this.data, this.message, this.timestamp});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromData,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] == null ? null : fromData(json['data']),
      message: json['message'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }
}
