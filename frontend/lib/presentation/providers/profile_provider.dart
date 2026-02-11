import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;

  Map<String, dynamic>? _profileData;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileProvider(this._repository);

  Map<String, dynamic>? get profileData => _profileData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String _extractError(DioException e) {
    if (e.response?.data != null) {
      if (e.response!.data is Map) {
        return e.response!.data['detail']?.toString() ?? 'Failed to perform operation';
      } else if (e.response!.data is String) {
        return e.response!.data;
      }
    }
    return e.message ?? 'An unexpected error occurred';
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getProfile();
      _profileData = response.data;
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.updateProfile(data);
      _profileData = response.data;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addEmergencyContact(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.addEmergencyContact(data);
      await fetchProfile(); // Refresh profile to get updated contacts
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmergencyContact(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateEmergencyContact(id, data);
      await fetchProfile();
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEmergencyContact(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteEmergencyContact(id);
      await fetchProfile();
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
