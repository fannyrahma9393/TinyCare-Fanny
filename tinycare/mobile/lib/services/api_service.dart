import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Change this to your server IP/URL for production
  static const String _customBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get _baseUrl {
    // User-defined override (via --dart-define=API_BASE_URL=...)
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;

    // Flutter Web
    if (kIsWeb) return 'http://localhost:8000/api';

    // Android Emulator
    // ignore: unnecessary_statements
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';

    // iOS Simulator
    // ignore: unnecessary_statements
    if (Platform.isIOS) return 'http://localhost:8000/api';

    // Desktop (development)
    return 'http://localhost:8000/api';
  }

  late Dio _dio;
  String? _token;
  bool _isAdmin = false;

  /// Set admin status for role-based API routing
  void setAdminStatus(bool isAdmin) {
    _isAdmin = isAdmin;
  }

  bool get isAdmin => _isAdmin;

  void init() {
    debugPrint('[ApiService] Base URL: $_baseUrl');
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('[ApiService] REQUEST: ${options.method} ${options.uri}');
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[ApiService] RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('[ApiService] ERROR: ${error.response?.statusCode} ${error.requestOptions.uri} ${error.message}');
        if (error.response?.statusCode == 401) {
          logout();
        }
        return handler.next(error);
      },
    ));
  }

  // ==================== AUTH ====================

  Future<Map<String, dynamic>> registerParent({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
    };
    if (phone != null && phone.isNotEmpty) data['phone'] = phone;
    if (address != null && address.isNotEmpty) data['address'] = address;
    final response = await _dio.post('/v1/auth/register-parent', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password, {String? adminAccessCode}) async {
    final data = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (adminAccessCode != null && adminAccessCode.isNotEmpty) {
      data['admin_access_code'] = adminAccessCode;
    }
    final response = await _dio.post('/v1/auth/login', data: data);
    return response.data;
  }

  /// Get current user profile from /me endpoint
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/v1/auth/me');
    return response.data;
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await _dio.post('/v1/auth/logout');
      }
    } catch (e) {
      debugPrint('[ApiService] Logout API error (non-critical): $e');
    }
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_data');
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // ==================== DASHBOARD ====================

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get(_isAdmin ? '/v1/admin/dashboard' : '/v1/parent/dashboard');
    return response.data;
  }

  // ==================== CHILDREN ====================

  Future<List<dynamic>> getChildren() async {
    final response = await _dio.get(_isAdmin ? '/v1/admin/children' : '/v1/parent/children');
    final data = response.data['data'];
    if (data is Map && data.containsKey('data')) {
      return data['data'] ?? [];
    }
    return data ?? [];
  }

  Future<Map<String, dynamic>> getChild(int id) async {
    final response = await _dio.get(_isAdmin ? '/v1/admin/children/$id' : '/v1/parent/children/$id');
    return response.data['data'];
  }

  // ==================== DAILY STORIES ====================

  Future<List<dynamic>> getDailyStories(int childId) async {
    final response = await _dio.get(_isAdmin ? '/v1/admin/daily-stories' : '/v1/parent/children/$childId/daily-stories');
    final data = response.data['data'];
    if (data is Map && data.containsKey('data')) {
      return data['data'] ?? [];
    }
    return data ?? [];
  }

  Future<Map<String, dynamic>?> getDailyStory(int childId, String date) async {
    final response = await _dio.get('/v1/parent/children/$childId/daily-stories/$date');
    return response.data['data'];
  }

  // ==================== ATTENDANCE ====================

  /// Get attendance list for admin.
  /// Admin endpoint supports: date, status, search, per_page
  Future<Map<String, dynamic>> getAttendanceList({String? date, String? status, String? search, int? perPage}) async {
    final response = await _dio.get('/v1/admin/attendance', queryParameters: {
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (search != null) 'search': search,
      if (perPage != null) 'per_page': perPage,
    });
    return response.data['data'] ?? {};
  }

  /// Get attendance for a parent's child (supports month/year filtering)
  Future<Map<String, dynamic>> getAttendance(int childId, {String? month, String? year}) async {
    if (_isAdmin) {
      // Admin endpoint: get all attendance, optionally filtered by date
      // We fetch with no date filter to get recent records, then the page filters client-side
      final response = await _dio.get('/v1/admin/attendance', queryParameters: {
        if (month != null && year != null) 'date': '$year-${month.padLeft(2, '0')}-01',
      });
      return response.data['data'] ?? {};
    }
    final response = await _dio.get('/v1/parent/children/$childId/attendance', queryParameters: {
      if (month != null) 'month': month,
      if (year != null) 'year': year,
    });
    return response.data['data'] ?? {};
  }

  // ==================== DEVELOPMENT ====================

  Future<Map<String, dynamic>> getDevelopment(int childId) async {
    final response = await _dio.get(_isAdmin ? '/v1/admin/children/$childId/development' : '/v1/parent/children/$childId/development');
    return response.data['data'] ?? {};
  }

  Future<List<dynamic>> getDevelopmentTimeline(int childId) async {
    final response = await _dio.get('/v1/parent/children/$childId/development/timeline');
    final data = response.data['data'];
    return data['timeline'] ?? [];
  }

  // ==================== INVOICES ====================

  Future<List<dynamic>> getInvoices() async {
    final response = await _dio.get(_isAdmin ? '/v1/admin/invoices' : '/v1/parent/invoices');
    final data = response.data['data'];
    if (data is Map && data.containsKey('data')) {
      return data['data'] ?? [];
    }
    return data ?? [];
  }

  Future<Map<String, dynamic>> getInvoice(int id) async {
    final response = await _dio.get(_isAdmin ? '/v1/admin/invoices/$id' : '/v1/parent/invoices/$id');
    return response.data['data'];
  }

  // ==================== PAYMENTS (Admin) ====================

  Future<List<dynamic>> getAdminPayments() async {
    final response = await _dio.get('/v1/admin/payments');
    final data = response.data['data'];
    if (data is Map && data.containsKey('data')) {
      return data['data'] ?? [];
    }
    return data ?? [];
  }

  Future<Map<String, dynamic>> verifyPayment(int paymentId) async {
    final response = await _dio.post('/v1/admin/payments/$paymentId/verify');
    return response.data;
  }

  Future<Map<String, dynamic>> rejectPayment(int paymentId, {String? reason}) async {
    final response = await _dio.post('/v1/admin/payments/$paymentId/reject', data: {
      if (reason != null) 'reason': reason,
    });
    return response.data;
  }

  // ==================== PARENT PAYMENTS ====================

  Future<Map<String, dynamic>> initiatePayment(String invoiceId, {String paymentMethod = 'bank_transfer'}) async {
    final response = await _dio.post('/v1/parent/invoices/$invoiceId/pay', data: {
      'payment_method': paymentMethod,
    });
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    final response = await _dio.get('/v1/parent/payments/$paymentId/status');
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> submitPayment(int invoiceId, String filePath, {String? amount, String? paymentMethod}) async {
    final map = <String, dynamic>{
      'invoice_id': invoiceId,
      'amount': amount ?? '',
      'payment_method': paymentMethod ?? '',
    };
    if (!kIsWeb) {
      map['proof_file'] = await MultipartFile.fromFile(filePath);
    }
    final formData = FormData.fromMap(map);
    final response = await _dio.post('/v1/parent/payments', data: formData);
    return response.data;
  }

  Future<List<dynamic>> getPayments(int invoiceId) async {
    final response = await _dio.get('/v1/parent/invoices/$invoiceId/payments');
    final data = response.data['data'];
    if (data is Map && data.containsKey('data')) {
      return data['data'] ?? [];
    }
    return data ?? [];
  }

  // ==================== ANNOUNCEMENTS ====================

  Future<List<dynamic>> getAnnouncements() async {
    final response = await _dio.get(_isAdmin ? '/v1/admin/announcements' : '/v1/parent/announcements');
    final data = response.data['data'];
    if (data is Map && data.containsKey('data')) {
      return data['data'] ?? [];
    }
    return data ?? [];
  }

  // ==================== EVENTS ====================

  Future<List<dynamic>> getEvents() async {
    final response = await _dio.get(_isAdmin ? '/v1/admin/events' : '/v1/parent/events');
    final respData = response.data;
    if (respData is! Map) return [];
    final data = respData['data'];
    if (data is Map && data.containsKey('events')) {
      final events = data['events'];
      return events is List ? events : [];
    }
    if (data is List) return data;
    return [];
  }

  // ==================== FEEDBACK ====================

  Future<List<dynamic>> getFeedback() async {
    final response = await _dio.get(_isAdmin ? '/v1/admin/feedback' : '/v1/parent/feedback');
    final respData = response.data;
    if (respData is! Map) return [];
    final data = respData['data'];
    if (data is Map && data.containsKey('data')) {
      final items = data['data'];
      return items is List ? items : [];
    }
    if (data is List) return data;
    return [];
  }

  Future<Map<String, dynamic>> submitFeedback({
    required String subject,
    required String message,
    required int rating,
    int? childId,
  }) async {
    final response = await _dio.post('/v1/parent/feedback', data: {
      'subject': subject,
      'message': message,
      'rating': rating,
      if (childId != null) 'child_id': childId,
    });
    return response.data;
  }

  // ==================== ADMIN PARENTS ====================

  Future<Map<String, dynamic>> getParents({String? filter, String? search}) async {
    final response = await _dio.get('/v1/admin/parents', queryParameters: {
      if (search != null) 'search': search,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getParent(int parentId) async {
    final response = await _dio.get('/v1/admin/parents/$parentId');
    return response.data;
  }

  // ==================== ADMIN ACTIVITIES ====================

  Future<List<dynamic>> getActivities() async {
    final response = await _dio.get('/v1/admin/activities');
    final data = response.data['data'];
    if (data is Map && data.containsKey('data')) {
      return data['data'] ?? [];
    }
    return data ?? [];
  }

  // ==================== ADMIN PACKAGES ====================

  Future<List<dynamic>> getPackages() async {
    debugPrint('[ApiService] getPackages: calling /v1/admin/packages (isAdmin=$_isAdmin)');
    final response = await _dio.get('/v1/admin/packages', queryParameters: {'per_page': 100});
    debugPrint('[ApiService] getPackages: status=${response.statusCode}');
    final rawData = response.data;
    if (rawData is! Map) {
      debugPrint('[ApiService] getPackages: response.data is not a Map, type=${rawData.runtimeType}');
      return [];
    }
    final data = rawData['data'];
    debugPrint('[ApiService] getPackages: data type=${data.runtimeType}, isMap=${data is Map}');
    if (data is Map && data.containsKey('data')) {
      final items = data['data'];
      if (items is List) {
        debugPrint('[ApiService] getPackages: parsed ${items.length} packages from paginated data');
        return items;
      }
      debugPrint('[ApiService] getPackages: data["data"] is not List, type=${items.runtimeType}');
      return [];
    }
    if (data is List) {
      debugPrint('[ApiService] getPackages: parsed ${data.length} packages (direct list)');
      return data;
    }
    debugPrint('[ApiService] getPackages: unexpected data structure, returning empty');
    return [];
  }

  /// Store package - backend requires: name, price, duration_days (integer)
  /// Also: description, facilities, quota, status, start_date, end_date
  Future<Map<String, dynamic>> createPackage({
    required String name,
    required dynamic price,
    required int durationDays,
    String? description,
    String? facilities,
    int? quota,
  }) async {
    final response = await _dio.post('/v1/admin/packages', data: {
      'name': name,
      'price': price,
      'duration_days': durationDays,
      if (description != null) 'description': description,
      if (facilities != null) 'facilities': facilities,
      if (quota != null) 'quota': quota,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updatePackage(int id, {
    String? name,
    dynamic price,
    int? durationDays,
    String? description,
    String? facilities,
    int? quota,
    String? status,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (price != null) data['price'] = price;
    if (durationDays != null) data['duration_days'] = durationDays;
    if (description != null) data['description'] = description;
    if (facilities != null) data['facilities'] = facilities;
    if (quota != null) data['quota'] = quota;
    if (status != null) data['status'] = status;
    final response = await _dio.put('/v1/admin/packages/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deletePackage(int id) async {
    final response = await _dio.delete('/v1/admin/packages/$id');
    return response.data;
  }

  /// Assign a package to a child (admin)
  Future<Map<String, dynamic>> assignPackageToChild(int childId, {required int packageId, required String startDate}) async {
    final response = await _dio.post('/v1/admin/children/$childId/packages', data: {
      'package_id': packageId,
      'start_date': startDate,
    });
    return response.data;
  }

  /// Get child's assigned packages (admin)
  Future<List<dynamic>> getChildPackages(int childId) async {
    final response = await _dio.get('/v1/admin/children/$childId/packages');
    final data = response.data['data'];
    if (data is List) return data;
    return [];
  }

  // ==================== ADMIN VOUCHERS ====================

  Future<List<dynamic>> getVouchers() async {
    final response = await _dio.get('/v1/admin/vouchers');
    final data = response.data['data'];
    if (data is Map && data.containsKey('data')) {
      return data['data'] ?? [];
    }
    return data ?? [];
  }

  /// Store voucher - backend requires:
  /// code, discount_type (nominal/percentage), discount_value, max_usage, start_date, end_date
  /// Also: description, min_transaction, status
  Future<Map<String, dynamic>> createVoucher({
    required String code,
    required String discountType,
    required dynamic discountValue,
    required int maxUsage,
    required String startDate,
    required String endDate,
    String? description,
    dynamic minTransaction,
  }) async {
    final response = await _dio.post('/v1/admin/vouchers', data: {
      'code': code,
      'discount_type': discountType,
      'discount_value': discountValue,
      'max_usage': maxUsage,
      'start_date': startDate,
      'end_date': endDate,
      if (description != null) 'description': description,
      if (minTransaction != null) 'min_transaction': minTransaction,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateVoucher(int id, {
    String? code,
    String? discountType,
    dynamic discountValue,
    int? maxUsage,
    String? startDate,
    String? endDate,
    String? description,
    dynamic minTransaction,
    String? status,
  }) async {
    final data = <String, dynamic>{};
    if (code != null) data['code'] = code;
    if (discountType != null) data['discount_type'] = discountType;
    if (discountValue != null) data['discount_value'] = discountValue;
    if (maxUsage != null) data['max_usage'] = maxUsage;
    if (startDate != null) data['start_date'] = startDate;
    if (endDate != null) data['end_date'] = endDate;
    if (description != null) data['description'] = description;
    if (minTransaction != null) data['min_transaction'] = minTransaction;
    if (status != null) data['status'] = status;
    final response = await _dio.put('/v1/admin/vouchers/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteVoucher(int id) async {
    final response = await _dio.delete('/v1/admin/vouchers/$id');
    return response.data;
  }

  // ==================== ADMIN REPORTS ====================

  Future<Map<String, dynamic>> getWeeklyReports({int? perPage}) async {
    final response = await _dio.get('/v1/admin/reports/weekly', queryParameters: {
      if (perPage != null) 'per_page': perPage,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMonthlyReports({int? perPage}) async {
    final response = await _dio.get('/v1/admin/reports/monthly', queryParameters: {
      if (perPage != null) 'per_page': perPage,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> generateWeeklyReport(int childId, {String? weekStart}) async {
    final response = await _dio.post('/v1/admin/children/$childId/reports/weekly', data: {
      if (weekStart != null) 'week_start': weekStart,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> generateMonthlyReport(int childId, {int? month, int? year}) async {
    final response = await _dio.post('/v1/admin/children/$childId/reports/monthly', data: {
      if (month != null) 'month': month,
      if (year != null) 'year': year,
    });
    return response.data;
  }

  // ==================== ADMIN DASHBOARD ====================

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await _dio.get('/v1/admin/dashboard');
    return response.data;
  }

  // ==================== USER MANAGEMENT ====================

  Future<Map<String, dynamic>> getUsers({String? filter, String? search}) async {
    final response = await _dio.get('/v1/admin/users', queryParameters: {
      if (filter != null) 'filter': filter,
      if (search != null) 'search': search,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getPendingUsers() async {
    final response = await _dio.get('/v1/admin/users/pending');
    return response.data;
  }

  Future<Map<String, dynamic>> approveUser(int userId) async {
    final response = await _dio.post('/v1/admin/users/$userId/approve');
    return response.data;
  }

  Future<Map<String, dynamic>> rejectUser(int userId, {String? reason}) async {
    final response = await _dio.post('/v1/admin/users/$userId/reject', data: {
      if (reason != null) 'reason': reason,
    });
    return response.data;
  }

  // ==================== ADMIN MANAGEMENT ====================

  Future<Map<String, dynamic>> getAdmins() async {
    final response = await _dio.get('/v1/admin/admins');
    return response.data;
  }

  Future<Map<String, dynamic>> createAdmin({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? position,
    String? adminRole,
  }) async {
    final response = await _dio.post('/v1/admin/admins', data: {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
      if (position != null) 'position': position,
      if (adminRole != null) 'admin_role': adminRole,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> activateAdmin(int adminId) async {
    final response = await _dio.post('/v1/admin/admins/$adminId/activate');
    return response.data;
  }

  Future<Map<String, dynamic>> deactivateAdmin(int adminId) async {
    final response = await _dio.post('/v1/admin/admins/$adminId/deactivate');
    return response.data;
  }

  // ==================== NOTIFICATIONS ====================

  Future<List<dynamic>> getNotifications() async {
    final response = await _dio.get('/v1/notifications');
    final data = response.data['data'];
    if (data is Map && data.containsKey('data')) {
      return data['data'] ?? [];
    }
    return data ?? [];
  }

  Future<void> markNotificationRead(int id) async {
    await _dio.put('/v1/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _dio.put('/v1/notifications/read-all');
  }

  // ==================== MEDIA ====================

  Future<List<dynamic>> getMedia(int childId) async {
    final response = await _dio.get('/v1/parent/children/$childId/media');
    final data = response.data['data'];
    if (data is Map && data.containsKey('data')) {
      return data['data'] ?? [];
    }
    return data ?? [];
  }

  // Vouchers (parent - admin vouchers are in ADMIN VOUCHERS section above)

  // ==================== CHILD ACTIVITIES ====================

  Future<List<dynamic>> getChildActivities(int childId) async {
    final response = await _dio.get('/v1/parent/children/$childId/activities');
    final data = response.data['data'];
    if (data is Map && data.containsKey('data')) {
      return data['data'] ?? [];
    }
    return data ?? [];
  }

  // ==================== ADMIN CHILDREN CRUD ====================

  /// Create child - backend requires: name, birth_date, gender, parent_ids (array)
  Future<Map<String, dynamic>> createChild({
    required String name,
    required String gender,
    required String birthDate,
    required List<int> parentIds,
    String? address,
    String? healthInfo,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    final response = await _dio.post('/v1/admin/children', data: {
      'name': name,
      'gender': gender,
      'birth_date': birthDate,
      'parent_ids': parentIds,
      if (address != null && address.isNotEmpty) 'address': address,
      if (healthInfo != null && healthInfo.isNotEmpty) 'health_info': healthInfo,
      if (emergencyContactName != null && emergencyContactName.isNotEmpty) 'emergency_contact_name': emergencyContactName,
      if (emergencyContactPhone != null && emergencyContactPhone.isNotEmpty) 'emergency_contact_phone': emergencyContactPhone,
    });
    return response.data;
  }

  /// Update child - backend accepts: name, birth_date, gender, parent_ids, status
  Future<Map<String, dynamic>> updateChild(int id, {
    String? name,
    String? gender,
    String? birthDate,
    List<int>? parentIds,
    String? address,
    String? healthInfo,
    String? status,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (gender != null) data['gender'] = gender;
    if (birthDate != null) data['birth_date'] = birthDate;
    if (parentIds != null) data['parent_ids'] = parentIds;
    if (address != null) data['address'] = address;
    if (healthInfo != null) data['health_info'] = healthInfo;
    if (status != null) data['status'] = status;
    final response = await _dio.put('/v1/admin/children/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteChild(int id) async {
    final response = await _dio.delete('/v1/admin/children/$id');
    return response.data;
  }

  // ==================== ADMIN ACTIVITIES CRUD ====================

  /// Create master activity - backend requires: name
  /// Backend fields: name, description, category (NOT type)
  Future<Map<String, dynamic>> createActivity({
    required String name,
    String? description,
    String? category,
  }) async {
    final response = await _dio.post('/v1/admin/activities', data: {
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateActivity(int id, {
    String? name,
    String? description,
    String? category,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (category != null) data['category'] = category;
    final response = await _dio.put('/v1/admin/activities/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteActivity(int id) async {
    final response = await _dio.delete('/v1/admin/activities/$id');
    return response.data;
  }

  // ==================== ADMIN ATTENDANCE CRUD ====================

  Future<Map<String, dynamic>> storeAttendance({
    required int childId,
    required String date,
    required String status,
    String? checkInTime,
    String? checkOutTime,
    String? notes,
  }) async {
    final response = await _dio.post('/v1/admin/attendance', data: {
      'child_id': childId,
      'date': date,
      'status': status,
      if (checkInTime != null) 'check_in_time': checkInTime,
      if (checkOutTime != null) 'check_out_time': checkOutTime,
      if (notes != null) 'notes': notes,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateAttendance(int id, {
    String? status,
    String? checkInTime,
    String? checkOutTime,
    String? notes,
  }) async {
    final response = await _dio.put('/v1/admin/attendance/$id', data: {
      if (status != null) 'status': status,
      if (checkInTime != null) 'check_in_time': checkInTime,
      if (checkOutTime != null) 'check_out_time': checkOutTime,
      if (notes != null) 'notes': notes,
    });
    return response.data;
  }

  // ==================== ADMIN DAILY STORIES CRUD ====================

  Future<Map<String, dynamic>> storeDailyStory({
    required int childId,
    String? date,
    String? summary,
    String? mood,
    String? mealRating,
    String? mealNotes,
    dynamic sleepHours,
    String? sleepNotes,
  }) async {
    final response = await _dio.post('/v1/admin/children/$childId/daily-stories', data: {
      if (date != null) 'date': date,
      if (summary != null) 'summary': summary,
      if (mood != null) 'mood': mood,
      if (mealRating != null) 'meal_rating': mealRating,
      if (mealNotes != null) 'meal_notes': mealNotes,
      if (sleepHours != null) 'sleep_hours': sleepHours,
      if (sleepNotes != null) 'sleep_notes': sleepNotes,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateDailyStory(int id, {
    String? summary,
    String? mood,
    String? mealRating,
    String? mealNotes,
    dynamic sleepHours,
    String? sleepNotes,
  }) async {
    final response = await _dio.put('/v1/admin/daily-stories/$id', data: {
      if (summary != null) 'summary': summary,
      if (mood != null) 'mood': mood,
      if (mealRating != null) 'meal_rating': mealRating,
      if (mealNotes != null) 'meal_notes': mealNotes,
      if (sleepHours != null) 'sleep_hours': sleepHours,
      if (sleepNotes != null) 'sleep_notes': sleepNotes,
    });
    return response.data;
  }

  // ==================== ADMIN DEVELOPMENT CRUD ====================

  Future<List<dynamic>> getDevelopmentCategories() async {
    final response = await _dio.get('/v1/admin/development-categories');
    final data = response.data['data'];
    if (data is List) return data;
    return [];
  }

  Future<Map<String, dynamic>> storeDevelopmentCategory({
    required String name,
    String? description,
    String? icon,
  }) async {
    final response = await _dio.post('/v1/admin/development-categories', data: {
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
    });
    return response.data;
  }

  /// Store assessment - backend requires:
  /// development_category_id, indicator (required), progress (enum), observation_date (required)
  /// progress enum: belum, mulai, berkembang, baik, sangat_baik
  Future<Map<String, dynamic>> storeAssessment({
    required int childId,
    required int developmentCategoryId,
    required String indicator,
    required String progress,
    required String observationDate,
    String? notes,
  }) async {
    final response = await _dio.post('/v1/admin/children/$childId/development-assessments', data: {
      'development_category_id': developmentCategoryId,
      'indicator': indicator,
      'progress': progress,
      'observation_date': observationDate,
      if (notes != null) 'notes': notes,
    });
    return response.data;
  }

  /// Update assessment - backend accepts: indicator, progress, observation_date, notes
  Future<Map<String, dynamic>> updateAssessment(int id, {
    String? indicator,
    String? progress,
    String? observationDate,
    String? notes,
  }) async {
    final data = <String, dynamic>{};
    if (indicator != null) data['indicator'] = indicator;
    if (progress != null) data['progress'] = progress;
    if (observationDate != null) data['observation_date'] = observationDate;
    if (notes != null) data['notes'] = notes;
    final response = await _dio.put('/v1/admin/development-assessments/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteAssessment(int id) async {
    final response = await _dio.delete('/v1/admin/development-assessments/$id');
    return response.data;
  }

  // ==================== ADMIN ANNOUNCEMENTS CRUD ====================

  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    String? content,
    String? priority,
    String? publishDate,
  }) async {
    final response = await _dio.post('/v1/admin/announcements', data: {
      'title': title,
      if (content != null) 'content': content,
      if (priority != null) 'priority': priority,
      if (publishDate != null) 'publish_date': publishDate,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateAnnouncement(int id, {
    required String title,
    String? content,
    String? priority,
    String? publishDate,
  }) async {
    final response = await _dio.put('/v1/admin/announcements/$id', data: {
      'title': title,
      if (content != null) 'content': content,
      if (priority != null) 'priority': priority,
      if (publishDate != null) 'publish_date': publishDate,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> deleteAnnouncement(int id) async {
    final response = await _dio.delete('/v1/admin/announcements/$id');
    return response.data;
  }

  // ==================== ADMIN EVENTS CRUD ====================

  /// Store event - backend requires: title, date (required).
  /// Also: description, start_time, end_time, location, type, status
  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String date,
    String? description,
    String? type,
    String? startTime,
    String? endTime,
    String? location,
  }) async {
    final response = await _dio.post('/v1/admin/events', data: {
      'title': title,
      'date': date,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (location != null) 'location': location,
    });
    return response.data;
  }

  /// Update event - backend accepts: title, date, description, start_time, end_time, location, type, status
  Future<Map<String, dynamic>> updateEvent(int id, {
    String? title,
    String? date,
    String? description,
    String? type,
    String? startTime,
    String? endTime,
    String? location,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (date != null) data['date'] = date;
    if (description != null) data['description'] = description;
    if (type != null) data['type'] = type;
    if (startTime != null) data['start_time'] = startTime;
    if (endTime != null) data['end_time'] = endTime;
    if (location != null) data['location'] = location;
    final response = await _dio.put('/v1/admin/events/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteEvent(int id) async {
    final response = await _dio.delete('/v1/admin/events/$id');
    return response.data;
  }

  // ==================== ADMIN FEEDBACK ====================

  /// Respond to feedback - backend field: admin_response (required)
  Future<Map<String, dynamic>> respondFeedback(int feedbackId, {required String adminResponse}) async {
    final result = await _dio.post('/v1/admin/feedback/$feedbackId/respond', data: {
      'admin_response': adminResponse,
    });
    return result.data;
  }

  Future<Map<String, dynamic>> updateFeedbackStatus(int feedbackId, {required String status}) async {
    final result = await _dio.put('/v1/admin/feedback/$feedbackId/status', data: {
      'status': status,
    });
    return result.data;
  }

  // ==================== ADMIN INVOICES ====================

  /// Create invoice - backend requires: child_id, package_id, due_date
  /// Also: voucher_code, notes. Subtotal/total are auto-calculated.
  Future<Map<String, dynamic>> createInvoice({
    required int childId,
    required int packageId,
    required String dueDate,
    String? voucherCode,
    String? notes,
  }) async {
    final response = await _dio.post('/v1/admin/invoices', data: {
      'child_id': childId,
      'package_id': packageId,
      'due_date': dueDate,
      if (voucherCode != null && voucherCode.isNotEmpty) 'voucher_code': voucherCode,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return response.data;
  }

  /// Delete invoice (backend: apiResource with except update/destroy)
  Future<Map<String, dynamic>> deleteInvoice(int id) async {
    final response = await _dio.delete('/v1/admin/invoices/$id');
    return response.data;
  }

  /// Update invoice status - backend requires: status (pending/paid/failed/expired/cancelled)
  Future<Map<String, dynamic>> updateInvoiceStatus(int invoiceId, {required String status}) async {
    final response = await _dio.put('/v1/admin/invoices/$invoiceId/status', data: {
      'status': status,
    });
    return response.data;
  }

  // Helper: get today's date in YYYY-MM-DD format
  static String today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ==================== ADMIN PAYMENT PROOF ====================

  Future<Map<String, dynamic>> showPaymentProof(int paymentId) async {
    final response = await _dio.get('/v1/admin/payments/$paymentId/proof');
    return response.data;
  }

  // ==================== PARENTS LIST FOR CHILD FORM ====================

  Future<List<dynamic>> getParentsList() async {
    final response = await _dio.get('/v1/admin/parents');
    final data = response.data['data'];
    if (data is Map && data.containsKey('data')) {
      return data['data'] ?? [];
    }
    return data ?? [];
  }
}
