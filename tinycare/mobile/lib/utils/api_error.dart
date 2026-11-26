import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Centralized API error handler.
/// Extracts user-friendly messages from DioException and generic errors.
///
/// Usage:
/// ```dart
/// try {
///   final response = await _api.someEndpoint();
/// } catch (e) {
///   final msg = ApiErrorHandler.getMessage(e);
///   setState(() { _error = msg; });
/// }
/// ```
class ApiErrorHandler {
  ApiErrorHandler._();

  /// Get a user-friendly error message from any exception.
  static String getMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioException(error);
    }
    if (error is FormatException) {
      return 'Data dari server tidak valid.';
    }
    if (error is TypeError) {
      debugPrint('[ApiErrorHandler] TypeError: $error');
      return 'Terjadi kesalahan pemrosesan data.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  /// Get a user-friendly message specifically for DioException.
  static String _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke server timeout. Periksa koneksi internet Anda.';

      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Pastikan server berjalan.';

      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';

      case DioExceptionType.badCertificate:
        return 'Sertifikat SSL tidak valid.';

      case DioExceptionType.badResponse:
        return _handleBadResponse(e.response);

      case DioExceptionType.unknown:
      default:
        if (e.message?.contains('SocketException') == true ||
            e.message?.contains('Connection refused') == true) {
          return 'Tidak dapat terhubung ke server. Pastikan server berjalan.';
        }
        return 'Terjadi kesalahan jaringan. Silakan coba lagi.';
    }
  }

  /// Handle HTTP error responses (4xx, 5xx).
  static String _handleBadResponse(Response? response) {
    if (response == null) {
      return 'Tidak ada response dari server.';
    }

    final statusCode = response.statusCode;
    final data = response.data;

    // Try to extract message from response body
    String? serverMessage;
    if (data is Map) {
      serverMessage = data['message'] as String?;
    }

    switch (statusCode) {
      case 400:
        return serverMessage ?? 'Permintaan tidak valid.';

      case 401:
        return 'Sesi berakhir. Silakan login kembali.';

      case 403:
        return serverMessage ?? 'Anda tidak memiliki akses ke resource ini.';

      case 404:
        return serverMessage ?? 'Data tidak ditemukan.';

      case 409:
        return serverMessage ?? 'Terjadi konflik data.';

      case 422:
        return _handleValidationErrors(data);

      case 429:
        return 'Terlalu banyak permintaan. Silakan tunggu beberapa saat.';

      case 500:
        return serverMessage ?? 'Terjadi kesalahan di server. Silakan coba lagi.';

      case 502:
      case 503:
        return 'Server sedang tidak tersedia. Silakan coba lagi nanti.';

      default:
        if (serverMessage != null) return serverMessage;
        if (statusCode != null) {
          return 'Terjadi kesalahan (HTTP $statusCode).';
        }
        return 'Terjadi kesalahan yang tidak diketahui.';
    }
  }

  /// Handle 422 validation errors from Laravel.
  /// Returns the first validation error message in a human-readable format.
  static String _handleValidationErrors(dynamic data) {
    if (data is! Map) return 'Data tidak valid.';

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      // Collect all error messages
      final messages = <String>[];
      errors.forEach((field, value) {
        if (value is List) {
          for (final msg in value) {
            messages.add(msg.toString());
          }
        } else {
          messages.add(value.toString());
        }
      });

      if (messages.isEmpty) return 'Data tidak valid.';
      if (messages.length == 1) return messages.first;
      return messages.join('\n');
    }

    return data['message'] ?? 'Data tidak valid.';
  }

  /// Get HTTP status code from exception, if available.
  static int? getStatusCode(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode;
    }
    return null;
  }

  /// Check if error is a validation error (422).
  static bool isValidationError(dynamic error) {
    return getStatusCode(error) == 422;
  }

  /// Check if error is an auth error (401).
  static bool isAuthError(dynamic error) {
    return getStatusCode(error) == 401;
  }

  /// Check if error is a permission error (403).
  static bool isPermissionError(dynamic error) {
    return getStatusCode(error) == 403;
  }

  /// Check if error is a connection/network error.
  static bool isConnectionError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout;
    }
    return false;
  }

  /// Whether the failure means "the backend could not be reached / is not
  /// usable right now", as opposed to a real answer from a live API.
  ///
  /// True for transport problems (no connection, timeout, cancelled socket) and
  /// for 5xx responses. False for any 4xx: a 401/403/404/422 proves the API is
  /// online, so those keep following the regular authentication/error flow and
  /// must never be presented as an offline state.
  static bool isReachabilityError(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        final status = response.statusCode ?? 0;
        if (status >= 400 && status < 500) return false;
        if (status >= 500) return true;
        // A 2xx never arrives here; treat an unlabelled response as reachable.
        return false;
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.connectionError:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return true;
        case DioExceptionType.unknown:
          final message = error.message ?? '';
          return message.contains('SocketException') ||
              message.contains('Connection refused') ||
              message.contains('Failed host lookup') ||
              message.contains('Network is unreachable');
        case DioExceptionType.badCertificate:
        case DioExceptionType.cancel:
        case DioExceptionType.badResponse:
          return false;
        // Newer Dio releases add types here; anything unknown is treated as a
        // transport problem only when it carries a socket/host error.
        default:
          final message = error.message ?? '';
          return message.contains('SocketException') ||
              message.contains('Connection refused') ||
              message.contains('Failed host lookup') ||
              message.contains('Network is unreachable');
      }
    }
    return false;
  }

  /// Message shown when a WRITE operation could not be delivered because the
  /// backend is unreachable. The data has NOT been sent — never claim success.
  static String writeFailureMessage(dynamic error) {
    if (isReachabilityError(error)) {
      return 'Tidak ada koneksi. Data belum dikirim.';
    }
    return getMessage(error);
  }
}
