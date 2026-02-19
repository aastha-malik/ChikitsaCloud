import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

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
      // 1. Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      // 2. Get ID Token
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _setError('Failed to get Google ID token');
        _setLoading(false);
        return false;
      }

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
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      String errorMessage = 'Google login failed';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['detail'] ?? errorMessage;
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      print("[ERROR] Google sign in error: $e");
      _setError('Google sign in failed');
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
