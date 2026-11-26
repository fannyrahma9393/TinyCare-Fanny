import 'package:flutter/material.dart';

import '../services/cached_resource.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/child_select.dart';
import '../widgets/offline_banner.dart';
import 'package_page.dart';
import 'pickups_page.dart';
import '../l10n/app_strings.dart';

/// Tabbed child detail (mirrors web ParentChildDetail / admin ChildDetail).
/// Tabs: Ringkasan (progress overview), Perkembangan (assessments),
/// Kehadiran (attendance), Aktivitas (activities).
class ChildDetailPage extends StatefulWidget {
  const ChildDetailPage({super.key, required this.childId});

  final int childId;

  @override
  State<ChildDetailPage> createState() => _ChildDetailPageState();
}

class _ChildDetailPageState extends State<ChildDetailPage>
    with ResourceBinding {
  final ParentDataRepository _repo = ParentDataRepository();

  /// Cache-first resources: the child profile drives the page, the tabs are
  /// best-effort and keep their last payload when the API is unreachable.
  late final CachedResource<Map<String, dynamic>> _childRes;
  late final CachedResource<Map<String, dynamic>> _developmentRes;
  late final CachedResource<List<dynamic>> _attendanceRes;
  late final CachedResource<List<dynamic>> _activitiesRes;

  Map<String, dynamic>? get _child => _childRes.data;
  Map<String, dynamic>? get _development => _developmentRes.data;
  List<dynamic> get _attendance => _attendanceRes.data ?? const [];
  List<dynamic> get _activities => _activitiesRes.data ?? const [];

  String _tab = 'overview';

  @override
  void initState() {
    super.initState();
    _childRes = CachedResource<Map<String, dynamic>>(
      onChanged: onResourceChanged,
      isEmptyData: (data) => data.isEmpty,
    );
    _developmentRes = CachedResource<Map<String, dynamic>>(
      onChanged: onResourceChanged,
      isEmptyData: (data) => data.isEmpty,
    );
    _attendanceRes = CachedResource<List<dynamic>>(onChanged: onResourceChanged);
    _activitiesRes = CachedResource<List<dynamic>>(onChanged: onResourceChanged);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _repo.loadChildDetail(widget.childId, _childRes),
      _repo.loadDevelopment(widget.childId, _developmentRes),
      _repo.loadChildAttendance(widget.childId, _attendanceRes),
      _repo.loadChildActivities(widget.childId, _activitiesRes),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Detail Anak'))),
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
                              children: _buildContent(context),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    return [
                          ChildHeader(child: _child),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PackagePage(
                                        childId: _child!['id'] as int,
                                        childName: _child!['name'] as String,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                                  label: Text(
                                    tr('Paket'),
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PickupsPage(
                                        childId: _child!['id'] as int,
                                        childName: _child!['name'] as String,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                                  label: Text(
                                    tr('Penjemput'),
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildTabBar(),
                          const SizedBox(height: 16),
                          _buildTabContent(),
                        ];
  }

  Widget _buildTabBar() {
    final tabs = [
      ('overview', tr('Ringkasan')),
      ('development', tr('Perkembangan')),
      ('attendance', tr('Kehadiran')),
      ('activities', tr('Aktivitas')),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tabs.map((t) {
        final selected = _tab == t.$1;
        return ChoiceChip(
          label: Text(t.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : ThemeHelper.textSecondary(context))),
          selected: selected,
          onSelected: (_) => setState(() => _tab = t.$1),
          selectedColor: AppColors.primary,
          backgroundColor: ThemeHelper.surface(context),
          side: BorderSide(color: ThemeHelper.border(context)),
        );
      }).toList(),
    );
  }

  Widget _buildTabContent() {
    if (!mounted) return const SizedBox.shrink();
    switch (_tab) {
      case 'development':
        return _buildDevelopmentsTab();
      case 'attendance':
        return _buildAttendanceTab();
      case 'activities':
        return _buildActivitiesTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    final categories = _development?['categories'];
    if (categories is! List || categories.isEmpty) {
      return AppWidgets.emptyState(
        icon: Icons.trending_up,
        title: tr('Belum ada data perkembangan'),
      );
    }
    return Column(
      children: categories.map<Widget>((cat) {
        final avgProgress = (cat['average_progress'] ?? 0).toDouble();
        final total = cat['total_assessments'] ?? 0;
        final color = _progressColor(avgProgress);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeHelper.surface(context),
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: ThemeHelper.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${cat['icon'] ?? '📊'}  ', style: const TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      '${cat['name'] ?? '-'}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(tr('Progress'), style: TextStyle(fontSize: 11, color: ThemeHelper.textMuted(context))),
                  const Spacer(),
                  Text('${avgProgress.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ThemeHelper.text(context))),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (avgProgress / 100).clamp(0.0, 1.0),
                  backgroundColor: ThemeHelper.border(context),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 6),
              Text(tr('{{total}} penilaian', {'total': total}), style: TextStyle(fontSize: 11, color: ThemeHelper.textMuted(context))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDevelopmentsTab() {
    final categories = _development?['categories'];
    if (categories is! List) {
      return AppWidgets.emptyState(icon: Icons.trending_up, title: tr('Belum ada penilaian'));
    }
    final items = categories.expand<dynamic>((cat) {
      final recent = cat['recent_assessments'];
      if (recent is List) {
        return recent.map((a) => {'assessment': a, 'category': cat});
      }
      return <dynamic>[];
    }).toList();

    if (items.isEmpty) {
      return AppWidgets.emptyState(icon: Icons.trending_up, title: tr('Belum ada penilaian'));
    }
    return Column(
      children: items.map<Widget>((entry) {
        final a = entry['assessment'];
        final cat = entry['category'];
        final progress = (a['progress_percentage'] ?? 0).toDouble();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ThemeHelper.bgAlt(context),
            borderRadius: AppRadius.mdAll,
          ),
          child: Row(
            children: [
              Text('${cat['icon'] ?? '📊'} ', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['indicator'] ?? '-',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: ThemeHelper.text(context))),
                    const SizedBox(height: 2),
                    Text('${cat['name'] ?? ''} · ${a['observation_date'] ?? ''}',
                        style: TextStyle(fontSize: 11, color: ThemeHelper.textMuted(context))),
                  ],
                ),
              ),
              Text(a['progress_label'] ?? '-',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _progressColor(progress))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceTab() {
    if (_attendance.isEmpty) {
      return AppWidgets.emptyState(icon: Icons.calendar_today, title: tr('Belum ada catatan kehadiran'));
    }
    return Column(
      children: _attendance.map<Widget>((r) {
        final status = r['status'] ?? '-';
        final color = status == 'hadir' ? AppColors.success : AppColors.warning;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ThemeHelper.surface(context),
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: ThemeHelper.border(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['date'] ?? '-',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: ThemeHelper.text(context))),
                    const SizedBox(height: 2),
                    Text(tr('Masuk: {{checkIn}} · Keluar: {{checkOut}}', {
                      'checkIn': r['check_in_time'] ?? '-',
                      'checkOut': r['check_out_time'] ?? '-',
                    }),
                        style: TextStyle(fontSize: 11, color: ThemeHelper.textMuted(context))),
                  ],
                ),
              ),
              AppWidgets.statusBadge(status, color),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivitiesTab() {
    if (_activities.isEmpty) {
      return AppWidgets.emptyState(icon: Icons.emoji_events_outlined, title: tr('Belum ada aktivitas'));
    }
    return Column(
      children: _activities.map<Widget>((a) {
        final name = a['activity']?['name'] ?? a['name'] ?? '-';
        final date = a['date'] ?? '-';
        final time = a['time'] as String?;
        final notes = a['notes'] as String?;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ThemeHelper.surface(context),
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: ThemeHelper.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
              const SizedBox(height: 2),
              Text('$date${(time != null && time.isNotEmpty) ? ' · $time' : ''}',
                  style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context))),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(notes, style: TextStyle(fontSize: 12, color: ThemeHelper.textSecondary(context), height: 1.5)),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _progressColor(double percentage) {
    if (percentage >= 75) return AppColors.success;
    if (percentage >= 50) return AppColors.warning;
    if (percentage >= 25) return Colors.orange;
    return AppColors.error;
  }
}