import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://chikitsacloud-pn0c.onrender.com';
  
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )),
        _storage = storage ?? const FlutterSecureStorage() {
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
      onError: (DioException e, handler) {
        debugPrint('--- API ERROR ---');
        debugPrint('Status Code: ${e.response?.statusCode}');
        debugPrint('Error Message: ${e.message}');
        debugPrint('Error Data: ${e.response?.data}');
        if (e.response?.statusCode == 401) {
          // Handle unauthorized
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
