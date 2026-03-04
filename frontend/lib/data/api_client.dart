import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS/Desktop
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://chikitsacloud-pn0c.onrender.com';
    }
    if (kIsWeb) return 'http://localhost:8000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final GlobalKey<NavigatorState>? _navigatorKey;

  /// Called when a 401 is received at runtime (e.g. token expired mid-session).
  /// AuthProvider registers its logout() method here so state is properly reset.
  VoidCallback? onUnauthorized;

  ApiClient({Dio? dio, FlutterSecureStorage? storage, GlobalKey<NavigatorState>? navigatorKey})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )),
        _storage = storage ?? const FlutterSecureStorage(),
        _navigatorKey = navigatorKey {
    debugPrint('[DEBUG] ApiClient initialized with baseUrl: ${baseUrl}');
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final fullUrl = '${options.baseUrl}${options.path}';
        debugPrint('--- API REQUEST ---');
        debugPrint('URL: $fullUrl');
        debugPrint('Method: ${options.method}');
        debugPrint('Headers: ${options.headers}');
        debugPrint('Body: ${options.data}');

        try {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          debugPrint('Error reading from secure storage: $e');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('--- API RESPONSE ---');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        debugPrint('--- API ERROR ---');
        debugPrint('Status Code: ${e.response?.statusCode}');
        debugPrint('Error Message: ${e.message}');
        debugPrint('Error Data: ${e.response?.data}');
        if (e.response?.statusCode == 401) {
          debugPrint('[AUTH] 401 received at runtime, clearing session and redirecting to login');
          await _storage.delete(key: 'auth_token');
          await _storage.delete(key: 'user_id');
          await _storage.delete(key: 'user_email');
          // Notify AuthProvider so _isAuthenticated is reset and AuthGate rebuilds
          onUnauthorized?.call();
          // Clear all routes and show login
          _navigatorKey?.currentState?.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
