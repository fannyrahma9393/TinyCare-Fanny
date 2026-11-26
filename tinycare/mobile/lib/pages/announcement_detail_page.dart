import 'package:flutter/material.dart';
import '../services/cached_resource.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/offline_banner.dart';
import '../l10n/app_strings.dart';

/// Full-screen detail of a single announcement, opened from a push/in-app
/// notification tap (data.type = announcement, data.announcement_id = X).
/// The backend enforces that the announcement is visible to the current
/// parent, so unknown/not-allowed announcements show an error state.
class AnnouncementDetailPage extends StatefulWidget {
  const AnnouncementDetailPage({super.key, required this.announcementId});

  final int announcementId;

  @override
  State<AnnouncementDetailPage> createState() => _AnnouncementDetailPageState();
}

class _AnnouncementDetailPageState extends State<AnnouncementDetailPage>
    with ResourceBinding {
  final ParentDataRepository _repo = ParentDataRepository();

  /// Cache-first announcement detail. An unreadable/not-visible announcement
  /// is a real API error, so the cached copy is never shown in that case.
  late final CachedResource<Map<String, dynamic>> _res;
  Map<String, dynamic>? get _announcement => _res.data;

  @override
  void initState() {
    super.initState();
    _res = CachedResource<Map<String, dynamic>>(
      onChanged: onResourceChanged,
      isEmptyData: (data) => data.isEmpty,
    );
    _load();
  }

  Future<void> _load() => _repo.loadAnnouncementDetail(widget.announcementId, _res);


  Color _priorityColor(String? priority) {
    switch (priority) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'normal':
        return AppColors.primary;
      default:
        return ThemeHelper.textMuted(context);
    }
  }

  String _priorityLabel(String? priority) {
    switch (priority) {
      case 'urgent':
        return tr('Mendesak');
      case 'high':
        return tr('Penting');
      case 'normal':
        return tr('Normal');
      case 'low':
        return tr('Rendah');
      default:
        return priority ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Pengumuman'))),
      body: Column(
        children: [
          OfflineBanner(resource: _res, onRetry: _load),
          Expanded(
            child: _res.isLoading
                ? AppWidgets.loadingIndicator()
                : _res.error != null
                    ? AppWidgets.errorState(
                        message: tr(_res.error!),
                        onRetry: _load,
                      )
                    : _buildDetail(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail() {
    final item = _announcement!;
    final priority = item['priority'] as String? ?? 'normal';
    final color = _priorityColor(priority);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWidgets.statusBadge(_priorityLabel(priority), color),
          const SizedBox(height: 14),
          Text(
            item['title'] as String? ?? '',
            style: AppTypography.h1.copyWith(color: ThemeHelper.text(context)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 14, color: ThemeHelper.textMuted(context)),
              const SizedBox(width: 6),
              Text(
                item['publish_date'] as String? ?? item['created_at'] as String? ?? '-',
                style: AppTypography.caption
                    .copyWith(color: ThemeHelper.textMuted(context)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            item['content'] as String? ?? '',
            style: TextStyle(
              fontSize: 16,
              height: 1.7,
              color: ThemeHelper.text(context),
            ),
          ),
        ],
      ),
    );
  }
}