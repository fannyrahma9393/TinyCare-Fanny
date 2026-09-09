import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Parsed push notification delivered to the mobile app.
class FcmNotification {
  const FcmNotification({
    required this.title,
    required this.body,
    this.link,
    this.type,
    this.childId,
    this.informationId,
    this.announcementId,
    this.invoiceId,
    this.paymentId,
    this.feedbackId,
  });

  final String title;
  final String body;
  final String? link;
  final String? type;
  final int? childId;
  final int? informationId;
  final int? announcementId;
  final int? invoiceId;
  final int? paymentId;
  final int? feedbackId;

  factory FcmNotification.fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    return FcmNotification.fromData(
      message.data,
      title: notification?.title,
      body: notification?.body,
    );
  }

  /// Pure parser — works with the backend `data` payload (keys: title, body,
  /// link, type, child_id, information_id, announcement_id, invoice_id,
  /// payment_id, feedback_id) and optional notification strings.
  /// Kept dependency-free so it is unit-testable without Firebase channels.
  factory FcmNotification.fromData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    return FcmNotification(
      title: title ?? data['title']?.toString() ?? 'TinyCare',
      body: body ?? data['body']?.toString() ?? '',
      link: data['link']?.toString(),
      type: data['type']?.toString(),
      childId: _toInt(data['child_id']),
      informationId: _toInt(data['information_id']),
      announcementId: _toInt(data['announcement_id']),
      invoiceId: _toInt(data['invoice_id']),
      paymentId: _toInt(data['payment_id']),
      feedbackId: _toInt(data['feedback_id']),
    );
  }

  /// Resolve the app route to open for this notification, falling back to the
  /// parent dashboard. Uses `link` when it maps to a known route, otherwise
  /// maps by backend `type`.
  String resolveRoute() {
    if (link != null && link!.isNotEmpty) {
      final normalized = _normalizeLink(link!);
      final route = _routeForLink(normalized);
      if (route != null) return route;
    }
    switch (type) {
      case 'announcement':
        return '/announcements';
      case 'daily_story':
        return '/daily-stories';
      case 'development':
        return '/development';
      case 'child_information':
        return '/information';
      case 'invoice':
      case 'invoice_created':
      case 'payment_verified':
      case 'payment_rejected':
        return '/invoices';
      case 'payment_submitted':
        return '/payments';
      case 'feedback':
      case 'feedback_created':
      case 'feedback_replied':
        return '/feedback';
      default:
        return '/dashboard';
    }
  }

  /// Whether this notification can open an invoice detail page
  /// (requires a valid invoice_id in the payload).
  bool get canOpenInvoiceDetail =>
      invoiceId != null &&
      (type == 'invoice_created' ||
          type == 'payment_verified' ||
          type == 'payment_rejected' ||
          type == 'invoice' ||
          type == 'payment_submitted');
  

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static String _normalizeLink(String link) {
    final lower = link.toLowerCase();
    if (lower.contains('/parent/development')) return '/development';
    if (lower.contains('/parent/children') && lower.contains('/daily-stories')) {
      return '/daily-stories';
    }
    if (lower.contains('/parent/information')) return '/parent/information';
    if (lower.contains('/admin/payments')) return '/payments';
    if (lower.contains('/parent/invoices')) return '/invoices';
    return link;
  }

  static String? _routeForLink(String link) {
    switch (link) {
      case '/dashboard':
      case '/daily-stories':
      case '/development':
      case '/children':
      case '/attendance':
      case '/invoices':
      case '/announcements':
      case '/events':
      case '/feedback':
      case '/profile':
      case '/packages':
      case '/vouchers':
      case '/reports':
      case '/activities':
      case '/payments':
        return link;
      default:
        return null;
    }
  }
}

/// Outcome of an attempt to register for push notifications.
enum FcmRegistrationReason {
  registered,
  notConfigured,
  permissionDenied,
  permissionNotGranted,
  tokenError,
}

class FcmRegistrationResult {
  const FcmRegistrationResult({required this.reason, this.token});

  final FcmRegistrationReason reason;
  final String? token;

  bool get enabled => reason == FcmRegistrationReason.registered;
}

/// Top-level handler for messages received while the app is in the background
/// or terminated. MUST be a top-level function (firebase_messaging runs it in
/// a separate isolate). On Android, FCM auto-displays the system notification
/// from the `notification` payload, so this stays dependency-free.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
      '[FcmService] Background message received: ${message.messageId} (${message.data['type']})');
}

/// Central Firebase Cloud Messaging integration for the mobile app.
///
/// - Initializes Firebase (guarded: if google-services.json is missing the
///   app still runs normally).
/// - Requests notification permission, fetches the FCM token and registers it
///   on the backend for the logged-in user (Android device).
/// - Handles token refresh (re-register), foreground messages (in-app
///   feedback), and background/terminated notification taps (routing).
///
/// Failures never throw out — push is best-effort and must not break login.
class FcmService {
  FcmService._() : _api = ApiService();

  /// Singleton shared across the app.
  static final FcmService instance = FcmService._();

  final ApiService _api;

  ApiService get api => _api;

  bool _configured = false;
  bool _initialized = false;
  bool _initialMessageHandled = false;
  String? _currentToken;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenSub;

  /// Called by the app to show clear in-app feedback for foreground messages.
  void Function(FcmNotification notification)? onForegroundMessage;

  /// Called by the app to route navigation when a notification is tapped.
  void Function(FcmNotification notification)? onNotificationTap;

  bool get isConfigured => _configured;

  /// Initialize Firebase Messaging. Safe to call before login. If Firebase is
  /// not configured (no google-services.json), the app continues without push.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await Firebase.initializeApp();
      _configured = true;

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      _configured = false;
      debugPrint('[FcmService] Firebase init failed (push disabled): $e');
    }
  }

  /// Register the logged-in user for push: request permission, fetch token,
  /// register on the backend, and wire up listeners. Only meaningful for
  /// parents — callers should gate by role.
  ///
  /// Never throws.
  Future<FcmRegistrationResult> setupForLoggedInUser({
    String platform = 'android',
  }) async {
    await initialize();
    if (!_configured) {
      return const FcmRegistrationResult(
          reason: FcmRegistrationReason.notConfigured);
    }

    final messaging = FirebaseMessaging.instance;

    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final authorized = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!authorized) {
        return const FcmRegistrationResult(
            reason: FcmRegistrationReason.permissionDenied);
      }
    } catch (e) {
      debugPrint('[FcmService] Permission request failed: $e');
      return const FcmRegistrationResult(
          reason: FcmRegistrationReason.permissionNotGranted);
    }

    String? token;
    try {
      token = await messaging.getToken();
    } catch (e) {
      debugPrint('[FcmService] Failed to get FCM token: $e');
      return const FcmRegistrationResult(reason: FcmRegistrationReason.tokenError);
    }

    if (token == null || token.isEmpty) {
      return const FcmRegistrationResult(reason: FcmRegistrationReason.tokenError);
    }

    _currentToken = token;

    // Register token on the backend for THIS user. Must be called while
    // authenticated (auth_provider wires it after login).
    await _registerToken(token, platform: platform);

    _wireListeners(platform: platform);

    return FcmRegistrationResult(reason: FcmRegistrationReason.registered, token: token);
  }

  /// Register (and on refresh re-register) the token with the backend.
  Future<void> _registerToken(String token, {String? platform}) async {
    String? device;
    try {
      device = defaultTargetPlatform.toString();
    } catch (_) {
      device = null;
    }
    await _api.registerFcmToken(token,
        platform: platform ?? 'android', device: device);
  }

  void _wireListeners({String? platform}) {
    _tokenSub?.cancel();
    _foregroundSub?.cancel();
    _openedSub?.cancel();

    final messaging = FirebaseMessaging.instance;

    // Token refresh -> re-register the new token (backend upserts by user).
    _tokenSub = messaging.onTokenRefresh.listen((token) async {
      final previous = _currentToken;
      _currentToken = token;
      if (previous != null && previous != token) {
        await _api.unregisterFcmToken(previous);
      }
      await _registerToken(token, platform: platform);
    }, onError: (Object e) {
      debugPrint('[FcmService] Token refresh error: $e');
    });

    // Foreground message -> in-app feedback.
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      final notification = FcmNotification.fromRemoteMessage(message);
      onForegroundMessage?.call(notification);
    }, onError: (Object e) {
      debugPrint('[FcmService] Foreground message error: $e');
    });

    // App opened from a notification (background -> foreground).
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationTap?.call(FcmNotification.fromRemoteMessage(message));
    });

    // App launched from a terminated-state notification.
    _handleInitialMessage(messaging);
  }

  /// Process the notification that launched the app (terminated state).
  /// Guarded so it only ever fires once per app run — setupForLoggedInUser()
  /// is safe to call multiple times (login + session restore) without the
  /// initial tap being routed twice.
  Future<void> _handleInitialMessage(FirebaseMessaging messaging) async {
    if (_initialMessageHandled) return;
    _initialMessageHandled = true;
    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        onNotificationTap?.call(FcmNotification.fromRemoteMessage(initial));
      }
    } catch (e) {
      debugPrint('[FcmService] getInitialMessage error: $e');
    }
  }

  /// Remove the current user's token from the backend and tear down listeners.
  /// Called on logout (best-effort, never throws).
  Future<void> teardownForLoggedOutUser() async {
    final token = _currentToken;
    _currentToken = null;

    await _tokenSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    _tokenSub = null;
    _foregroundSub = null;
    _openedSub = null;

    if (token != null && token.isNotEmpty && _configured) {
      await _api.unregisterFcmToken(token);
    }
  }
}
