import 'package:dio/dio.dart';
import '../api_client.dart';

class ReportsRepository {
  final ApiClient _apiClient;

  ReportsRepository(this._apiClient);

  Future<Response> listRecords({String? ownerId}) async {
    return await _apiClient.dio.get(
      '/records',
      queryParameters: ownerId != null ? {'owner_id': ownerId} : null,
    );
  }

  Future<Response> uploadRecord({
    required String title,
    required String recordType,
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'record_type': recordType,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    return await _apiClient.dio.post('/records', data: formData);
  }

  Future<Response> deleteRecord(String recordId) async {
    return await _apiClient.dio.delete('/records/$recordId');
  }

  Future<void> downloadRecord(String recordId, String savePath) async {
    await _apiClient.dio.download('/records/$recordId/file', savePath);
  }
}
