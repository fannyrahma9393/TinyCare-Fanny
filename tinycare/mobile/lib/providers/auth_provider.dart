import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  String get errorMessage => _error ?? '';
  String get userRole => _user?['role'] ?? '';
  bool get isAdmin => userRole == 'admin' || userRole == 'admin_master';
  bool get isAdminMaster => userRole == 'admin_master';
  bool get isParent => userRole == 'parent';

  /// Initialize: check for stored token and validate with backend
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _api.getToken();
      if (token != null) {
        try {
          final meResponse = await _api.getMe();
          if (meResponse['success'] == true) {
            final userData = meResponse['data'];
            _user = {
              'id': userData['id'],
              'name': userData['name'],
              'email': userData['email'],
              'role': userData['role'],
              'status': userData['status'],
            };
            // Set admin status for role-based API routing
            final role = userData['role'];
            _api.setAdminStatus(role == 'admin' || role == 'admin_master');
            _isLoggedIn = true;
          } else {
            await logout();
          }
        } catch (e) {
          debugPrint('[AuthProvider] Token validation failed: $e');
          await logout();
        }
      }
    } catch (e) {
      debugPrint('[AuthProvider] Init failed: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login with email and password. Supports both parent and admin roles.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.login(email, password);
      
      if (response['success'] == true) {
        final token = response['data']['token'];
        final userData = response['data']['user'];
        final role = userData['role'];

        // Validate role is supported in this app
        if (role != 'parent' && role != 'admin' && role != 'admin_master') {
          _error = 'Akun ini tidak memiliki akses ke aplikasi ini.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await _api.setToken(token);
        await _api.saveUser(userData);
        
        // Set admin status for role-based API routing
        _api.setAdminStatus(role == 'admin' || role == 'admin_master');
        
        _isLoggedIn = true;
        _user = userData;
        _error = null;
        _isLoading = false;
        notifyListeners();

        // Push notifications target parents only. Register this Android device
        // for FCM. Best-effort: never blocks login or throws.
        if (isParent) {
          _setupFcm();
        }
        return true;
      } else {
        _error = response['message'] ?? 'Login gagal. Silakan coba lagi.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _error = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else if (e.type == DioExceptionType.connectionError) {
        _error = 'Tidak dapat terhubung ke server. Pastikan server berjalan.';
      } else if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;
        
        if (statusCode == 422) {
          final errors = data['errors'];
          if (errors != null && errors is Map && errors.isNotEmpty) {
            final firstError = errors.values.first;
            _error = firstError is List ? firstError.first.toString() : firstError.toString();
          } else {
            _error = data['message'] ?? 'Data tidak valid.';
          }
        } else if (statusCode == 401) {
          _error = 'Email atau password salah.';
        } else if (statusCode == 403) {
          _error = data['message'] ?? 'Akun tidak aktif atau tidak memiliki akses.';
        } else {
          _error = data['message'] ?? 'Terjadi kesalahan. Silakan coba lagi.';
        }
      } else {
        _error = 'Tidak dapat terhubung ke server.';
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] Login error: $e');
      _error = 'Terjadi kesalahan yang tidak diketahui. Silakan coba lagi.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout and clear all session data
  Future<void> logout() async {
    _teardownFcm();
    try {
      await _api.logout();
    } catch (e) {
      debugPrint('[AuthProvider] Logout API error (non-critical): $e');
    }
    _isLoggedIn = false;
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Register this device for push (parents only). Best-effort + async.
  void _setupFcm() {
    FcmService.instance.setupForLoggedInUser(platform: 'android').then((result) {
      debugPrint('[AuthProvider] FCM setup result: ${result.reason} token=${result.token ?? '-'}');
    }).catchError((Object e, StackTrace s) {
      debugPrint('[AuthProvider] FCM setup error (non-critical): $e');
    });
  }

  /// Unregister this device from push and tear down listeners (best-effort).
  void _teardownFcm() {
    FcmService.instance.teardownForLoggedOutUser().catchError((Object e) {
      debugPrint('[AuthProvider] FCM teardown error (non-critical): $e');
    });
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
