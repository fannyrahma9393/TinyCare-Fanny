import 'package:flutter/material.dart';

import '../services/cached_resource.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/child_select.dart';
import '../widgets/offline_banner.dart';
import '../l10n/app_strings.dart';

/// Parent view: activities for one child (mirrors web ParentActivitiesDetail).
class ActivitiesDetailPage extends StatefulWidget {
  const ActivitiesDetailPage({super.key, required this.childId});

  final int childId;

  @override
  State<ActivitiesDetailPage> createState() => _ActivitiesDetailPageState();
}

class _ActivitiesDetailPageState extends State<ActivitiesDetailPage>
    with ResourceBinding {
  final ParentDataRepository _repo = ParentDataRepository();

  /// Cache-first child header + activity list.
  late final CachedResource<Map<String, dynamic>> _childRes;
  late final CachedResource<List<dynamic>> _activitiesRes;

  Map<String, dynamic>? get _child => _childRes.data;
  List<dynamic> get _activities => _activitiesRes.data ?? const [];

  @override
  void initState() {
    super.initState();
    _childRes = CachedResource<Map<String, dynamic>>(
      onChanged: onResourceChanged,
      isEmptyData: (data) => data.isEmpty,
    );
    _activitiesRes = CachedResource<List<dynamic>>(onChanged: onResourceChanged);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _repo.loadChildDetail(widget.childId, _childRes),
      _repo.loadChildActivities(widget.childId, _activitiesRes),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Aktivitas Anak'))),
      body: Column(
        children: [
          OfflineBanner(resource: _childRes, onRetry: _loadData),
          Expanded(
            child: _childRes.isLoading
                ? AppWidgets.loadingIndicator()
                : _childRes.error != null
                    ? AppWidgets.errorState(
                        message: tr(_childRes.error!),
                        onRetry: _loadData,
                      )
                    : _child == null
                        ? AppWidgets.emptyState(
                            icon: Icons.child_care,
                            title: tr('Anak tidak ditemukan.'),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppColors.primary,
                            child: ListView(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              children: [
                                ChildHeader(
                                  child: _child,
                                  subtitle: tr('Aktivitas yang diikuti anak Anda.'),
                                ),
                                const SizedBox(height: 20),
                                if (_activities.isEmpty)
                                  AppWidgets.emptyState(
                                    icon: Icons.emoji_events_outlined,
                                    title: tr('Belum ada aktivitas'),
                                    subtitle: tr('Aktivitas akan muncul ketika ada kegiatan terbaru.'),
                                  )
                                else
                                  ..._activities.map((a) => _ActivityCard(item: a)),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}


class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);
    final secColor = ThemeHelper.textSecondary(context);
    final name = item['activity']?['name'] ?? item['name'] ?? '-';
    final date = item['date'] ?? '-';
    final time = item['time'] as String?;
    final notes = item['notes'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: ThemeHelper.border(context)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 4),
          Text('$date${(time != null && time.isNotEmpty) ? ' · $time' : ''}',
              style: TextStyle(fontSize: 12, color: mutedColor)),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(notes, style: TextStyle(fontSize: 12, color: secColor, height: 1.5)),
          ],
        ],
      ),
    );
  }
}