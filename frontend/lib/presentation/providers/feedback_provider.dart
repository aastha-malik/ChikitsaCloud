import 'package:flutter/material.dart';
import '../../data/repositories/feedback_repository.dart';
import 'package:dio/dio.dart';

class FeedbackProvider with ChangeNotifier {
  final FeedbackRepository _repository;

  FeedbackProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> submitFeedback({required int rating, String? message}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.submitFeedback(rating: rating, message: message);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = e.response?.data['detail'] ?? 'Failed to submit feedback';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }
}
