import 'package:dio/dio.dart';
import '../api_client.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<Response> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/users/profile');
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/users/profile', data: data);
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> addEmergencyContact(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/users/emergency-contacts', data: data);
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> updateEmergencyContact(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/users/emergency-contacts/$id', data: data);
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> deleteEmergencyContact(String contactId) async {
    try {
      final response = await _apiClient.dio.delete('/users/emergency-contacts/$contactId');
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }
}
