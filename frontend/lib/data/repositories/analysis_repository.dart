import 'package:dio/dio.dart';
import '../api_client.dart';

class AnalysisRepository {
  final ApiClient _apiClient;

  AnalysisRepository(this._apiClient);

  Future<Response> analyzeHealthData(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        '/medical/analyze',
        data: data,
      );
      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }
}
