import 'dart:async';
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

/// Robust thin wrapper around a configured [Dio] instance.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: resolveBaseUrl(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
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
        onError: (DioException error, handler) async {
          // Automatic Firebase Token Refresh on 401 Unauthorized
          if (error.response?.statusCode == 401 &&
              !(error.requestOptions.extra['isTokenRetry'] as bool? ?? false)) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              try {
                // Force-refresh token from Firebase
                final newToken = await user.getIdToken(true);
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                opts.extra['isTokenRetry'] = true;

                // Re-execute failed request with updated token
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {
                // Token refresh failed, pass through original error
              }
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  Dio get dio => _dio;

  /// Unwraps backend `{success, data, message}` response envelopes,
  /// with automatic exponential backoff retries on transient network failures.
  Future<T> unwrap<T>(
    Future<Response> Function(Dio dio) request,
    T Function(dynamic data) fromData, {
    int maxRetries = 3,
    Duration initialRetryDelay = const Duration(milliseconds: 500),
  }) async {
    int attempt = 0;

    while (true) {
      attempt++;
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
        final isLastAttempt = attempt >= maxRetries;
        final isRetryable = _isTransientError(e);

        if (!isLastAttempt && isRetryable) {
          // Exponential backoff calculation: delay * (2 ^ (attempt - 1))
          final delay = initialRetryDelay * (1 << (attempt - 1));
          await Future.delayed(delay);
          continue;
        }

        // Final failure after retries
        final serverMessage = _extractServerMessage(e);
        final statusCode = e.response?.statusCode;

        if (serverMessage != null) {
          throw ApiException(serverMessage, statusCode: statusCode);
        }

        throw _mapDioExceptionToApiException(e);
      }
    }
  }

  /// Determines if an error is transient and safe to retry automatically.
  bool _isTransientError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }

    final statusCode = e.response?.statusCode;
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return true;
    }

    return false;
  }

  ApiException _mapDioExceptionToApiException(DioException e) {
    final statusCode = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException.networkError(
          'Connection timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
        return ApiException.networkError(
          'Unable to connect to the server. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        return ApiException(
          'Server responded with error',
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return ApiException('Request was cancelled', statusCode: statusCode);
      default:
        return ApiException(
          e.message ?? 'An unexpected network error occurred.',
          statusCode: statusCode,
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
