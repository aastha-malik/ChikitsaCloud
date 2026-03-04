import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/repositories/auth_repository.dart';
import '../../config/secrets.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;
  String? _userId;
  String? _userEmail;
  bool _isNewGoogleUser = false;

  // ─── Google OAuth2 Native (using google_sign_in + google-services.json) ────
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'profile',
      'openid',
    ],
    // serverClientId is REQUIRED to get an idToken for the backend
    serverClientId: GoogleSecrets.clientId,
  );

  AuthProvider(this._authRepository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isCheckingAuth => _isCheckingAuth;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  bool get isNewGoogleUser => _isNewGoogleUser;

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
      debugPrint('[DEBUG] Starting Google Sign-In via Native SDK...');

      // 1. Sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[DEBUG] Google Sign-In cancelled by user');
        _setLoading(false);
        return false;
      }

      // 2. Get tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint('[ERROR] Could not get ID Token from Google Sign-In');
        _setError('Failed to get security token from Google.');
        _setLoading(false);
        return false;
      }

      debugPrint('[DEBUG] Got ID Token, sending to backend...');

      // 3. Send to backend
      final response = await _authRepository.googleLogin(idToken);
      final token = response.data['access_token'];
      final userId = response.data['user_id'];
      final email = googleUser.email;

      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_id', value: userId);
      await _storage.write(key: 'user_email', value: email);

      _userId = userId;
      _userEmail = email;
      _isAuthenticated = true;
      _isNewGoogleUser = response.data['is_new_user'] == true;
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
      try {
        // Validate token against server
        await _authRepository.validateToken();
        _userId = userId;
        _userEmail = userEmail;
        _isAuthenticated = true;
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          // Token expired or invalid — clear credentials
          debugPrint('[AUTH] Token invalid (401), clearing session');
          await _storage.delete(key: 'auth_token');
          await _storage.delete(key: 'user_id');
          await _storage.delete(key: 'user_email');
        } else {
          // Network error (offline) — trust local token, show dashboard
          debugPrint('[AUTH] Network error during token check, assuming valid: $e');
          _userId = userId;
          _userEmail = userEmail;
          _isAuthenticated = true;
        }
      } catch (e) {
        // Unexpected error — trust local token
        debugPrint('[AUTH] Unexpected error during token check: $e');
        _userId = userId;
        _userEmail = userEmail;
        _isAuthenticated = true;
      }
    }

    _isCheckingAuth = false;
    notifyListeners();
  }
}
