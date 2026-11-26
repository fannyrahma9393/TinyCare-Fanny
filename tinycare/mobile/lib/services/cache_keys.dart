/// Stable cache keys for every parent-facing resource.
///
/// Keys are scoped per user by [OfflineCacheService]; the constants below only
/// name the resource inside that per-user namespace. Keys containing a child id
/// keep each child's payload separate so switching children never mixes data.
class CacheKeys {
  CacheKeys._();

  static const String profile = 'parent.profile';
  static const String dashboard = 'parent.dashboard';
  static const String children = 'parent.children';
  static const String activities = 'parent.activities';
  static const String announcements = 'parent.announcements';
  static const String announcementDetailPrefix = 'parent.announcement.';
  static const String invoices = 'parent.invoices';
  static const String invoiceDetailPrefix = 'parent.invoice.';
  static const String invoicePaymentsPrefix = 'parent.invoice.payments.';
  static const String paymentStatusPrefix = 'parent.payment.status.';
  static const String feedback = 'parent.feedback';
  static const String feedbackDetailPrefix = 'parent.feedback.detail.';
  static const String notifications = 'parent.notifications';
  static const String packages = 'parent.packages';
  static const String childInformationPrefix = 'parent.child_information.';
  static const String adminPaymentsPrefix = 'admin.payments.';

  static String childDetail(int childId) => 'parent.child.$childId';

  static String childActivities(int childId) =>
      'parent.child.$childId.activities';

  static String childDevelopment(int childId) =>
      'parent.child.$childId.development';

  static String childDevelopmentTimeline(int childId) =>
      'parent.child.$childId.development.timeline';

  static String childDailyStories(int childId) =>
      'parent.child.$childId.daily_stories';

  static String childDailyStory(int childId, String date) =>
      'parent.child.$childId.daily_story.$date';

  static String childAttendance(int childId) =>
      'parent.child.$childId.attendance';

  static String childPackage(int childId) => 'parent.child.$childId.package';

  static String childPackageHistory(int childId) =>
      'parent.child.$childId.package.history';

  static String childInformation(int? childId) =>
      '$childInformationPrefix${childId ?? 'all'}';

  static String childInformationDetail(int id) => 'parent.child_information.id.$id';

  static String announcementDetail(int id) => '$announcementDetailPrefix$id';

  static String invoiceDetail(int id) => '$invoiceDetailPrefix$id';

  static String invoicePayments(int id) => '$invoicePaymentsPrefix$id';

  static String paymentStatus(String paymentId) => '$paymentStatusPrefix$paymentId';

  static String feedbackDetail(int id) => '$feedbackDetailPrefix$id';

  static String adminPayments(String? status) =>
      '$adminPaymentsPrefix${status ?? 'all'}';
}
