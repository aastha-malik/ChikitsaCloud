import 'package:dio/dio.dart';
import '../api_client.dart';

class ReportsRepository {
  final ApiClient _apiClient;

  ReportsRepository(this._apiClient);

  Future<Response> listRecords(String userId) async {
    try {
      final response = await _apiClient.dio.get(
        '/medical-records/',
        queryParameters: {
          'requester_id': userId,
          'owner_id': userId,
        },
      );
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> uploadRecord({
    required String userId,
    required String category,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_id': userId,
        'record_category': category,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _apiClient.dio.post(
        '/medical-records/upload',
        data: formData,
      );
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<Response> deleteRecord(String recordId, String userId) async {
    try {
      final response = await _apiClient.dio.delete(
        '/medical-records/$recordId',
        queryParameters: {
          'requester_id': userId,
        },
      );
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }
}
