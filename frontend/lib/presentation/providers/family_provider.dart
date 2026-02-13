import 'package:flutter/material.dart';
import '../../data/api_client.dart';
import 'package:dio/dio.dart';

class FamilyProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  String? _qrData;
  String? get qrData => _qrData;
  
  List<dynamic> _pendingRequests = [];
  List<dynamic> get pendingRequests => _pendingRequests;
  
  List<dynamic> _activeAccess = [];
  List<dynamic> get activeAccess => _activeAccess;

  List<dynamic> _sharedWithMe = [];
  List<dynamic> get sharedWithMe => _sharedWithMe;

  Future<void> fetchQRData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.dio.post('/family-access/generate-invite');
      _qrData = response.data['invite_token'];
    } catch (e) {
      _errorMessage = "Failed to load QR: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final pending = await _apiClient.dio.get('/family-access/pending-requests');
      _pendingRequests = pending.data;
      
      final active = await _apiClient.dio.get('/family-access/active-access');
      _activeAccess = active.data;

      final shared = await _apiClient.dio.get('/family-access/shared-with-me');
      _sharedWithMe = shared.data;
    } catch (e) {
      _errorMessage = "Failed to fetch requests: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestAccessByEmail(String email) async {
    try {
      final userResponse = await _apiClient.dio.get('/users/search', queryParameters: {'email': email});
      final ownerId = userResponse.data['user_id'];
      
      await _apiClient.dio.post('/family-access/request', data: {'owner_user_id': ownerId});
      await fetchRequests();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> respondToRequest(String requestId, bool accept) async {
    try {
      await _apiClient.dio.post('/family-access/respond/$requestId', data: {'accept': accept});
      await fetchRequests();
      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic>? _lastRedeemResult;
  Map<String, dynamic>? get lastRedeemResult => _lastRedeemResult;

  Future<bool> redeemInvite(String token) async {
    if (_isLoading) return false; // Safety lock: ignore second call if first is still running
    
    _isLoading = true;
    _errorMessage = null;
    _lastRedeemResult = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio.post('/family-access/redeem-invite', data: {'invite_token': token});
      _lastRedeemResult = response.data;
      await fetchRequests();
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      _errorMessage = data is Map ? data['detail'] : data?.toString() ?? 'Redeem failed';
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> revokeAccess(String viewerId) async {
    try {
      await _apiClient.dio.delete('/family-access/revoke/$viewerId');
      await fetchRequests();
      return true;
    } catch (e) {
      return false;
    }
  }
}
