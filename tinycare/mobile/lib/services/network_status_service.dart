import 'package:flutter/foundation.dart';

import '../utils/api_error.dart';

/// Tracks whether the TinyCare backend is actually reachable.
///
/// The app does NOT treat "the device has internet" as "the API is alive":
/// a device on Wi-Fi behind a down host still cannot reach the API. Therefore
/// the only signal used here is what the API itself answered:
/// - a response (2xx/4xx)  -> the backend is reachable,
/// - a transport failure or 5xx -> the backend is not usable right now.
///
/// This service is a pure indicator. It never logs the user out, and a 401
/// keeps following the existing authentication flow handled by `ApiService`.
class NetworkStatusService extends ChangeNotifier {
  NetworkStatusService._();

  static final NetworkStatusService instance = NetworkStatusService._();

  bool _apiReachable = true;
  bool _hasVerdict = false;
  int _consecutiveFailures = 0;
  DateTime? _lastSuccessAt;
  DateTime? _lastFailureAt;

  /// Whether the last API attempt suggested the backend is usable.
  bool get isApiReachable => _apiReachable;

  /// Whether any API attempt has been observed yet this app run.
  bool get hasVerdict => _hasVerdict;

  /// Consecutive transport/5xx failures, 0 after a success.
  int get consecutiveFailures => _consecutiveFailures;

  DateTime? get lastSuccessAt => _lastSuccessAt;

  DateTime? get lastFailureAt => _lastFailureAt;

  /// Convenience alias used by the offline banner.
  bool get isOffline => _hasVerdict && !_apiReachable;

  /// The backend answered — it is reachable, whatever the status code was.
  void reportSuccess() {
    final changed = !_apiReachable || _hasVerdict == false;
    _apiReachable = true;
    _hasVerdict = true;
    _consecutiveFailures = 0;
    _lastSuccessAt = DateTime.now();
    if (changed) notifyListeners();
  }

  /// The request could not be completed. Only transport problems and 5xx mean
  /// "the backend is unreachable"; a 4xx is a normal answer and keeps the
  /// backend marked reachable.
  void reportFailure(Object? error) {
    if (!ApiErrorHandler.isReachabilityError(error)) {
      // A real HTTP answer (401, 403, 404, 422...) proves the API is alive.
      _apiReachable = true;
      _lastSuccessAt = DateTime.now();
      return;
    }
    _apiReachable = false;
    _hasVerdict = true;
    _consecutiveFailures++;
    _lastFailureAt = DateTime.now();
    notifyListeners();
  }

  /// Forget the current verdict (used after logout / scope changes).
  void reset() {
    _apiReachable = true;
    _hasVerdict = false;
    _consecutiveFailures = 0;
    _lastSuccessAt = null;
    _lastFailureAt = null;
    notifyListeners();
  }
}
