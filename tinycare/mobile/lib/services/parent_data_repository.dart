import 'api_service.dart';
import 'cache_keys.dart';
import 'cached_resource.dart';
import 'offline_cache_service.dart';
import '../utils/api_error.dart';

/// Repository layer between the pages and [ApiService].
///
/// This is the single place that knows about the offline cache: widgets only
/// hand over a [CachedResource] and read `data` / `status` / `lastUpdated`.
/// Reads are cache-first and write-through; nothing here ever performs a write
/// that the backend has not confirmed.
class ParentDataRepository {
  ParentDataRepository([ApiService? api]) : _api = api ?? ApiService();

  final ApiService _api;

  static final ParentDataRepository instance = ParentDataRepository();

  OfflineCacheService get cache => OfflineCacheService.instance;

  // ==================== PROFILE ====================

  Future<void> loadProfile(
    CachedResource<Map<String, dynamic>> resource, {
    String errorKey = 'Tidak dapat memuat profil. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.profile,
      fetch: () async {
        final response = await _api.getMe();
        final data = response['data'];
        if (data is Map) return data.cast<String, dynamic>();
        return <String, dynamic>{};
      },
      errorKey: errorKey,
    );
  }

  // ==================== DASHBOARD ====================

  Future<void> loadDashboard(
    CachedResource<Map<String, dynamic>> resource, {
    String errorKey = 'Gagal memuat dashboard',
  }) {
    return resource.load(
      cacheKey: CacheKeys.dashboard,
      fetch: () async {
        final response = await _api.getDashboard();
        final data = response['data'];
        if (data is Map) return data.cast<String, dynamic>();
        return <String, dynamic>{};
      },
      errorKey: errorKey,
    );
  }

  // ==================== CHILDREN ====================

  /// Plain (uncached) child lookup, for headers where the full child object is
  /// already supplied by the caller or lives in another resource's payload.
  Future<Map<String, dynamic>?> loadChildDetailOnce(int childId) {
    return _api.getChild(childId);
  }

  Future<void> loadChildren(
    CachedResource<List<dynamic>> resource, {
    String errorKey = 'Gagal memuat data anak. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.children,
      fetch: () => _api.getChildren(),
      errorKey: errorKey,
    );
  }

  Future<void> loadChildDetail(
    int childId,
    CachedResource<Map<String, dynamic>> resource, {
    String errorKey = 'Gagal memuat data anak. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.childDetail(childId),
      fetch: () => _api.getChild(childId),
      errorKey: errorKey,
    );
  }

  Future<void> loadChildActivities(
    int childId,
    CachedResource<List<dynamic>> resource, {
    String errorKey = 'Gagal memuat data aktivitas. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.childActivities(childId),
      fetch: () => _api.getChildActivities(childId),
      errorKey: errorKey,
    );
  }

  // ==================== ACTIVITIES ====================

  Future<void> loadActivities(
    CachedResource<List<dynamic>> resource, {
    String errorKey = 'Gagal memuat data aktivitas. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.activities,
      fetch: () => _api.getActivities(),
      errorKey: errorKey,
    );
  }

  // ==================== DEVELOPMENT ====================

  Future<void> loadDevelopment(
    int childId,
    CachedResource<Map<String, dynamic>> resource, {
    String errorKey = 'Gagal memuat data. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.childDevelopment(childId),
      fetch: () => _api.getDevelopment(childId),
      errorKey: errorKey,
    );
  }

  Future<void> loadDevelopmentTimeline(
    int childId,
    CachedResource<List<dynamic>> resource, {
    String errorKey = 'Gagal memuat data. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.childDevelopmentTimeline(childId),
      fetch: () => _api.getDevelopmentTimeline(childId),
      errorKey: errorKey,
    );
  }

  // ==================== ATTENDANCE ====================

  Future<void> loadChildAttendance(
    int childId,
    CachedResource<List<dynamic>> resource, {
    String errorKey = 'Gagal memuat data. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.childAttendance(childId),
      fetch: () async {
        final response = await _api.getAttendance(childId);
        final inner = response['attendance'];
        if (inner is List) return inner;
        if (inner is Map) {
          final items = inner['data'];
          return items is List ? items : <dynamic>[];
        }
        return <dynamic>[];
      },
      errorKey: errorKey,
    );
  }

  // ==================== DAILY STORIES ====================
  Future<void> loadDailyStories(
    int childId,
    CachedResource<List<dynamic>> resource, {
    String errorKey = 'Gagal memuat Daily Stories.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.childDailyStories(childId),
      fetch: () => _api.getDailyStories(childId),
      errorKey: errorKey,
    );
  }

  // ==================== CHILD INFORMATION ====================

  /// Child information, resolving the parent or admin endpoint automatically.
  Future<void> loadChildInformationFor(
    int childId,
    CachedResource<List<dynamic>> resource, {
    required bool isAdmin,
    String errorKey = 'Gagal memuat informasi.',
  }) {
    return loadChildInformation(
      childId,
      resource,
      errorKey: errorKey,
      isAdmin: isAdmin,
    );
  }

  Future<void> loadChildInformation(
    int? childId,
    CachedResource<List<dynamic>> resource, {
    bool isAdmin = false,
    String errorKey = 'Gagal memuat informasi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.childInformation(childId),
      fetch: () => isAdmin
          ? _api.getAdminChildInformation(childId: childId)
          : _api.getChildInformation(childId: childId),
      errorKey: errorKey,
    );
  }

  // ==================== PACKAGES ====================

  Future<void> loadPackages(
    CachedResource<List<dynamic>> resource, {
    String errorKey = 'Gagal memuat paket. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.packages,
      fetch: () => _api.getPackages(),
      errorKey: errorKey,
    );
  }

  Future<void> loadChildPackage(
    int childId,
    CachedResource<Map<String, dynamic>?> resource, {
    String errorKey = 'Gagal memuat paket. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.childPackage(childId),
      fetch: () => _api.getParentChildPackage(childId),
      errorKey: errorKey,
    );
  }

  Future<void> loadChildPackageHistory(
    int childId,
    CachedResource<List<dynamic>> resource, {
    String errorKey = 'Gagal memuat paket. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.childPackageHistory(childId),
      fetch: () => _api.getParentChildPackageHistory(childId),
      errorKey: errorKey,
    );
  }

  // ==================== INVOICES ====================

  Future<void> loadInvoices(
    CachedResource<List<dynamic>> resource, {
    String errorKey = 'Gagal memuat tagihan. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.invoices,
      fetch: () => _api.getInvoices(),
      errorKey: errorKey,
    );
  }

  Future<void> loadInvoiceDetail(
    int invoiceId,
    CachedResource<Map<String, dynamic>> resource, {
    String errorKey = 'Gagal memuat detail invoice.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.invoiceDetail(invoiceId),
      fetch: () => _api.getInvoice(invoiceId),
      errorKey: errorKey,
    );
  }

  // ==================== PAYMENTS ====================

  Future<void> loadInvoicePayments(
    int invoiceId,
    CachedResource<List<dynamic>> resource, {
    String errorKey = 'Gagal memuat data pembayaran. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.invoicePayments(invoiceId),
      fetch: () => _api.getPayments(invoiceId),
      errorKey: errorKey,
    );
  }

  Future<void> loadPaymentStatus(
    String paymentId,
    CachedResource<Map<String, dynamic>> resource, {
    String errorKey = 'Gagal memuat data pembayaran. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.paymentStatus(paymentId),
      fetch: () => _api.checkPaymentStatus(paymentId),
      errorKey: errorKey,
    );
  }

  /// Admin payment list, optionally filtered by status.
  Future<void> loadAdminPayments(
    CachedResource<List<dynamic>> resource, {
    String? status,
    String errorKey = 'Gagal memuat data pembayaran. Silakan coba lagi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.adminPayments(status),
      fetch: () => _api.getAdminPayments(status: status),
      errorKey: errorKey,
    );
  }

  // ==================== ANNOUNCEMENTS ====================

  Future<void> loadAnnouncements(
    CachedResource<List<dynamic>> resource, {
    String errorKey = 'Gagal memuat pengumuman.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.announcements,
      fetch: () => _api.getAnnouncements(),
      errorKey: errorKey,
    );
  }

  Future<void> loadAnnouncementDetail(
    int id,
    CachedResource<Map<String, dynamic>> resource, {
    String errorKey = 'Gagal memuat pengumuman.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.announcementDetail(id),
      fetch: () async {
        final data = await _api.getAnnouncement(id);
        return data ?? <String, dynamic>{};
      },
      errorKey: errorKey,
    );
  }

  // ==================== FEEDBACK ====================

  Future<void> loadFeedback(
    CachedResource<List<dynamic>> resource, {
    String errorKey = 'Gagal memuat feedback.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.feedback,
      fetch: () => _api.getFeedback(),
      errorKey: errorKey,
    );
  }

  // ==================== NOTIFICATIONS ====================

  Future<void> loadNotifications(
    CachedResource<List<dynamic>> resource, {
    String errorKey = 'Gagal memuat notifikasi.',
  }) {
    return resource.load(
      cacheKey: CacheKeys.notifications,
      fetch: () => _api.getNotifications(),
      errorKey: errorKey,
    );
  }

  // ==================== WRITES ====================

  /// Upload payment proof. The future completes only when the backend confirmed
  /// the upload; an offline attempt throws so the UI can say the data was not
  /// sent instead of faking a success.
  Future<Map<String, dynamic>> submitPaymentProof({
    required int invoiceId,
    required String filePath,
    String? amount,
    String? paymentMethod,
  }) {
    return _api.submitPayment(
      invoiceId,
      filePath,
      amount: amount,
      paymentMethod: paymentMethod,
    );
  }

  /// Send parent feedback. Same contract as [submitPaymentProof]: success is
  /// only reported once the backend answered with `success: true`.
  Future<Map<String, dynamic>> sendFeedback({
    required String subject,
    required String message,
    required int rating,
    int? childId,
  }) {
    return _api.submitFeedback(
      subject: subject,
      message: message,
      rating: rating,
      childId: childId,
    );
  }

  /// User-facing message for a failed write. Reachability problems get the
  /// dedicated "not sent" wording; anything else falls back to the API message.
  static String writeFailureMessage(Object error) {
    return ApiErrorHandler.writeFailureMessage(error);
  }
}
