import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/repositories/analysis_repository.dart';

class AnalysisProvider extends ChangeNotifier {
  final AnalysisRepository _analysisRepository;

  Map<String, dynamic>? _analysisResult;
  bool _isLoading = false;
  String? _errorMessage;

  AnalysisProvider(this._analysisRepository);

  Map<String, dynamic>? get analysisResult => _analysisResult;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> analyzeData(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    _analysisResult = null;
    try {
      final response = await _analysisRepository.analyzeHealthData(data);
      _analysisResult = response.data;
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _setError(e.response?.data?['detail'] ?? 'Analysis failed');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  void clearResult() {
    _analysisResult = null;
    notifyListeners();
  }
}
