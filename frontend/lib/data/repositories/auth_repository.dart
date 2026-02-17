import 'package:dio/dio.dart';
import '../api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Response> signup(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/signup',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> verifyEmail(String email, String code) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/verify-email',
        data: {
          'email': email,
          'verification_code': code,
        },
      );
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> resendVerification(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/resend-verification',
        data: {
          'email': email,
        },
      );
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _apiClient.dio.delete('/auth/account');
    } on DioException catch (e) {
      rethrow;
    }
  }
}
