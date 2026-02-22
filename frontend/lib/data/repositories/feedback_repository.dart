import 'package:dio/dio.dart';
import '../api_client.dart';

class FeedbackRepository {
  final ApiClient _apiClient;

  FeedbackRepository(this._apiClient);

  Future<void> submitFeedback({required int rating, String? message}) async {
    try {
      await _apiClient.dio.post(
        '/feedback',
        data: {
          'rating': rating,
          'message': message,
        },
      );
    } on DioException catch (e) {
      rethrow;
    }
  }
}
