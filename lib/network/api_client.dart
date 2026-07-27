import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'api_exception.dart';

/// Resolves the backend base URL for the environment the app is running on.
String resolveBaseUrl() {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;

  if (kIsWeb) return 'http://localhost:8080';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}

/// Thin wrapper around a configured [Dio] instance. Every request
/// automatically attaches the current Firebase ID token so the Spring Boot
/// backend can verify it via the Firebase Admin SDK, matching the
/// "custom Dio interceptor" approach described in the proposal.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: resolveBaseUrl(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  Dio get dio => _dio;

  /// Unwraps the backend's `{success, data, message}` envelope and throws
  /// an [ApiException] if `success` is false or the request itself failed.
  Future<T> unwrap<T>(
    Future<Response> Function(Dio dio) request,
    T Function(dynamic data) fromData,
  ) async {
    try {
      final response = await request(_dio);
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final success = body['success'] as bool? ?? true;
        if (!success) {
          throw ApiException(
            body['message'] as String? ?? 'Request failed',
            statusCode: response.statusCode,
          );
        }
        return fromData(body['data']);
      }
      return fromData(body);
    } on DioException catch (e) {
      final serverMessage = _extractServerMessage(e);
      throw ApiException(
        serverMessage ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  String? _extractServerMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }
}
