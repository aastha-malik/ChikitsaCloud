import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../config/secrets.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;

  // ─── Google OAuth2 Web Client ─────────────────────────────────────────────
  // Credentials live in lib/config/secrets.dart (gitignored — never committed)
  static const _googleClientId = GoogleSecrets.clientId;
  static const _googleClientSecret = GoogleSecrets.clientSecret;
  static const _redirectUri = 'com.example.chikitsa_cloud:/oauth2redirect';
  // ─────────────────────────────────────────────────────────────────────────
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  AuthProvider(this._authRepository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> signup(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authRepository.signup(email, password);
      // We don't log in automatically anymore because email needs verification
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      debugPrint("[ERROR] Signup failed: ${e.response?.data}");
      String errorMessage = 'Signup failed';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['detail'] ?? errorMessage;
      } else if (e.response?.data is String) {
        errorMessage = e.response?.data;
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint("[ERROR] Signup unexpected error: $e");
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _authRepository.verifyEmail(email, code);
      final token = response.data['access_token'];
      final userId = response.data['user_id'];

      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_id', value: userId);
      await _storage.write(key: 'user_email', value: email);

      _userId = userId;
      _userEmail = email;
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      String errorMessage = 'Verification failed';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['detail'] ?? errorMessage;
      } else if (e.response?.data is String) {
        errorMessage = e.response?.data;
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _authRepository.login(email, password);
      final token = response.data['access_token'];
      final userId = response.data['user_id'];
      
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_id', value: userId);
      await _storage.write(key: 'user_email', value: email);
      
      _userId = userId;
      _userEmail = email;
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      debugPrint("[ERROR] Login failed: ${e.response?.data}");
      String errorMessage = 'Login failed';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['detail'] ?? errorMessage;
      } else if (e.response?.data is String) {
        errorMessage = e.response?.data;
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint("[ERROR] Login unexpected error: $e");
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resendVerification(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authRepository.resendVerification(email);
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      String errorMessage = 'Failed to resend code';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['detail'] ?? errorMessage;
      } else if (e.response?.data is String) {
        errorMessage = e.response?.data;
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    _setError(null);
    try {
      await _authRepository.deleteAccount();
      await logout();
      return true;
    } on DioException catch (e) {
      String errorMessage = 'Failed to delete account';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['detail'] ?? errorMessage;
      } else if (e.response?.data is String) {
        errorMessage = e.response?.data;
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authRepository.forgotPassword(email);
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      String errorMessage = 'Failed to send reset code';
      if (e.response?.data is Map) {
         errorMessage = e.response?.data['detail'] ?? errorMessage;
      } else if (e.response?.data is String) {
         errorMessage = e.response?.data;
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String email, String code, String newPassword) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authRepository.resetPassword(email, code, newPassword);
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      String errorMessage = 'Password reset failed';
      if (e.response?.data is Map) {
         errorMessage = e.response?.data['detail'] ?? errorMessage;
      } else if (e.response?.data is String) {
         errorMessage = e.response?.data;
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
    _userId = null;
    _userEmail = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> googleLogin() async {
    _setLoading(true);
    _setError(null);
    try {
      debugPrint('[DEBUG] Starting Google OAuth2 flow via AppAuth...');

      final AuthorizationTokenResponse? result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _googleClientId,
          _redirectUri,
          clientSecret: _googleClientSecret,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint:
                'https://accounts.google.com/o/oauth2/v2/auth',
            tokenEndpoint: 'https://oauth2.googleapis.com/token',
          ),
          scopes: ['openid', 'email', 'profile'],
        ),
      );

      if (result == null || result.idToken == null) {
        debugPrint('[ERROR] AppAuth returned null or no ID token');
        _setError('Google sign in was cancelled or failed.');
        _setLoading(false);
        return false;
      }

      final idToken = result.idToken!;
      debugPrint('[DEBUG] Got ID Token, sending to backend...');

      // Decode email from the ID token JWT payload (no library needed)
      String email = '';
      try {
        final parts = idToken.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          // Base64 padding fix
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final claims = json.decode(decoded) as Map<String, dynamic>;
          email = claims['email'] ?? '';
          debugPrint('[DEBUG] Extracted email from ID token: $email');
        }
      } catch (e) {
        debugPrint('[WARN] Could not decode email from ID token: $e');
      }

      // Send ID token to our FastAPI backend for verification
      final response = await _authRepository.googleLogin(idToken);
      final token = response.data['access_token'];
      final userId = response.data['user_id'];

      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_id', value: userId);
      await _storage.write(key: 'user_email', value: email);

      _userId = userId;
      _userEmail = email;
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      debugPrint('[ERROR] Backend Google login failed: ${e.response?.data}');
      String errorMessage = 'Google login failed';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['detail'] ?? errorMessage;
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('[ERROR] Google sign in error: $e');
      _setError('Google sign in failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    final userId = await _storage.read(key: 'user_id');
    final userEmail = await _storage.read(key: 'user_email');
    if (token != null && userId != null) {
      _userId = userId;
      _userEmail = userEmail;
      _isAuthenticated = true;
      notifyListeners();
    }
  }
}
