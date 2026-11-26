import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../services/cached_resource.dart';
import '../theme/app_theme.dart';

/// Slim indicator shown above the content of a cache-first page.
///
/// - Nothing at all while the data is fresh from the backend.
/// - A light progress line while a refresh runs on top of visible data (never a
///   blank screen when a cache exists).
/// - An offline bar with the "last updated" timestamp when the backend could
///   not be reached, plus a retry action.
///
/// All wording goes through the TinyCare localization system.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.resource,
    this.onRetry,
  });

  final CachedResource<dynamic> resource;

  /// Re-runs the load (pull-to-refresh and the banner button).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (resource.isRefreshing) {
      children.add(
        const LinearProgressIndicator(
          minHeight: 2,
          color: AppColors.primary,
          backgroundColor: Colors.transparent,
        ),
      );
    }

    if (resource.isOffline) {
      children.add(_buildOfflineBar(context));
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _buildOfflineBar(BuildContext context) {
    final muted = ThemeHelper.textSecondary(context);
    final timestamp = resource.lastUpdated;

    final message = timestamp == null
        ? tr('Offline • Menampilkan data terakhir')
        : tr('Offline • Data terakhir diperbarui {{time}}',
            {'time': formatLastUpdated(timestamp)});

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        border: Border(bottom: BorderSide(color: AppColors.warning.withValues(alpha: 0.35))),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: muted, height: 1.3),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                tr('Coba Lagi'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

/// Locale-aware "27 Sep 2026, 18:42" formatting for last-updated stamps.
String formatLastUpdated(DateTime value) {
  final locale = AppStrings.instance.isEnglish ? 'en' : 'id';
  try {
    return DateFormat('d MMM y, HH:mm', locale).format(value.toLocal());
  } catch (_) {
    return DateFormat('d MMM y, HH:mm').format(value.toLocal());
  }
}
