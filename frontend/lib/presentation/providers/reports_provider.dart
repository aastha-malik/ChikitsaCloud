import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
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

  Future<void> fetchRecords({String? ownerId}) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _reportsRepository.listRecords(ownerId: ownerId);
      _records = response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      _setError(data is Map ? data['detail'] : data?.toString() ?? 'Failed to fetch records');
    } catch (e) {
      _setError('An unexpected error occurred');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadRecord({
    required String title,
    required String recordType,
    required String filePath,
    required String fileName,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _reportsRepository.uploadRecord(
        title: title,
        recordType: recordType,
        filePath: filePath,
        fileName: fileName,
      );
      await fetchRecords(); // Refresh personal list
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      _setError(data is Map ? data['detail'] : data?.toString() ?? 'Upload failed');
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteRecord(String recordId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _reportsRepository.deleteRecord(recordId);
      await fetchRecords(); // Refresh personal list
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      _setError(data is Map ? data['detail'] : data?.toString() ?? 'Delete failed');
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> viewRecord(String recordId, String fileName) async {
    _setLoading(true);
    _setError(null);
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = "${tempDir.path}/$fileName";
      
      await _reportsRepository.downloadRecord(recordId, filePath);
      await OpenFilex.open(filePath);
    } catch (e) {
      _setError('Failed to open file');
    } finally {
      _setLoading(false);
    }
  }
}
