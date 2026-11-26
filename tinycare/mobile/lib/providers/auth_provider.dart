import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../services/offline_cache_service.dart';
import '../services/translation_service.dart';

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
      final savedUser = await _api.getSavedUser();
      String? token;
      try {
        token = await _api.getToken();
      } catch (e) {
        debugPrint('[AuthProvider] getToken failed: $e');
      }

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

            // Scope the offline cache to this account: only data this user is
            // allowed to see is ever written or read on this device.
            await _bindCacheScope(userData['id']);

            // Session restored without a fresh login: re-arm FCM so push
            // listeners and token registration keep working after the app is
            // reopened. setupForLoggedInUser() is idempotent, so calling it
            // here AND after login is safe (no duplicate listeners).
            _setupFcm();
          } else {
            await logout();
          }
        } catch (e) {
          // The backend could not be reached (network error, timeout, or a
          // transient 5xx). This is NOT proof the session is invalid, so we
          // keep the session and the stored token/cached user instead of
          // logging the user out. A real 401 is handled by the Dio
          // interceptor (ApiService.onError), which will call logout for us.
          debugPrint('[AuthProvider] Token validation failed (network/transient): $e');
          if (_user == null) {
            // Restore from cache so the user can still enter the app offline.
            if (savedUser != null) {
              _user = savedUser;
              final role = savedUser['role'];
              _api.setAdminStatus(role == 'admin' || role == 'admin_master');
              _isLoggedIn = true;
              await _bindCacheScope(savedUser['id']);
              _setupFcm();
            }
            // If we have a token but no cached user and no network, the
            // session cannot be validated. Keep the token (do not wipe); the
            // user will be asked to log in.
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthProvider] Init failed: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Point the offline cache at the signed-in account. Passing null (missing
  /// id) leaves the cache unbound so nothing can be read or written.
  ///
  /// Awaited on every call site: pages load their cached resources as soon as
  /// the session is restored, and an unbound scope would silently read nothing.
  Future<void> _bindCacheScope(Object? userId) async {
    try {
      await OfflineCacheService.instance.bindUser(userId);
    } catch (e) {
      debugPrint('[AuthProvider] bindUser failed: $e');
    }
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

        // A fresh login is a new session: drop whatever cache belonged to the
        // previous scope, then bind the cache to this account so a different
        // parent can never read the previous user's data.
        await OfflineCacheService.instance.clearCurrentUser();
        await _bindCacheScope(userData['id']);
        
        _isLoggedIn = true;
        _user = userData;
        _error = null;
        _isLoading = false;
        notifyListeners();

        // Register this device for FCM push. Parents receive child/payment/
        // feedback events; admins receive payment_submitted + feedback_created.
        // Best-effort: never blocks login or throws.
        _setupFcm();

        // Refresh the remote translation overlay after login (best-effort;
        // cached/static translations are used when the network fails).
        TranslationService.instance.refresh();
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
    // Belt and braces: the cache is bound to the session, so it is wiped and
    // unbound even if the token removal above failed for any reason.
    try {
      await OfflineCacheService.instance.clearCurrentUser();
      await OfflineCacheService.instance.unbindUser();
    } catch (e) {
      debugPrint('[AuthProvider] Cache cleanup error (non-critical): $e');
    }
    _isLoggedIn = false;
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Register this device for push (all roles). Best-effort + async.
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
