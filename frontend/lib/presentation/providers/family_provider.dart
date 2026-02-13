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

  bool _isFetching = false;

  Future<void> fetchQRData() async {
    if (_isFetching) return;
    _isFetching = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.dio.post('/family-access/generate-invite');
      _qrData = response.data['invite_token'];
    } catch (e) {
      _errorMessage = "Failed to load QR: $e";
    } finally {
      _isFetching = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRequests() async {
    if (_isFetching) return;
    _isFetching = true;
    _isLoading = true;
    notifyListeners();
    try {
      final responses = await Future.wait([
        _apiClient.dio.get('/family-access/pending-requests'),
        _apiClient.dio.get('/family-access/active-access'),
        _apiClient.dio.get('/family-access/shared-with-me'),
      ]);
      
      _pendingRequests = responses[0].data;
      _activeAccess = responses[1].data;
      _sharedWithMe = responses[2].data;
    } catch (e) {
      _errorMessage = "Failed to fetch requests: $e";
    } finally {
      _isFetching = false;
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

  bool _isRedeeming = false;

  Future<bool> redeemInvite(String token) async {
    if (_isRedeeming) return false;
    _isRedeeming = true;
    _isLoading = true;
    _errorMessage = null;
    _lastRedeemResult = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio.post('/family-access/redeem-invite', data: {'invite_token': token});
      _lastRedeemResult = response.data;
      // Use internal fetch to avoid lock conflicts
      await _internalFetchRequests();
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      _errorMessage = data is Map ? data['detail'] : data?.toString() ?? 'Redeem failed';
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      return false;
    } finally {
      _isRedeeming = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _internalFetchRequests() async {
    try {
      final responses = await Future.wait([
        _apiClient.dio.get('/family-access/pending-requests'),
        _apiClient.dio.get('/family-access/active-access'),
        _apiClient.dio.get('/family-access/shared-with-me'),
      ]);
      _pendingRequests = responses[0].data;
      _activeAccess = responses[1].data;
      _sharedWithMe = responses[2].data;
    } catch (_) {}
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
