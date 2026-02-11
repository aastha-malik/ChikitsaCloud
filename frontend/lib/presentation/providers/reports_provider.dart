import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/repositories/reports_repository.dart';

class ReportsProvider extends ChangeNotifier {
  final ReportsRepository _reportsRepository;

  List<dynamic> _records = [];
  bool _isLoading = false;
  String? _errorMessage;

  ReportsProvider(this._reportsRepository);

  List<dynamic> get records => _records;
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

  Future<void> fetchRecords(String userId) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _reportsRepository.listRecords(userId);
      _records = response.data;
      _setLoading(false);
    } on DioException catch (e) {
      _setError(e.response?.data?['detail'] ?? 'Failed to fetch records');
      _setLoading(false);
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
    }
  }

  Future<bool> uploadRecord({
    required String userId,
    required String category,
    required String filePath,
    required String fileName,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _reportsRepository.uploadRecord(
        userId: userId,
        category: category,
        filePath: filePath,
        fileName: fileName,
      );
      await fetchRecords(userId); // Refresh list
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _setError(e.response?.data?['detail'] ?? 'Upload failed');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteRecord(String recordId, String userId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _reportsRepository.deleteRecord(recordId, userId);
      await fetchRecords(userId); // Refresh list
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _setError(e.response?.data?['detail'] ?? 'Delete failed');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }
}
