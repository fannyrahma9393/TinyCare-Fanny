import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/child_select.dart';

/// Parent view: activities for one child (mirrors web ParentActivitiesDetail).
class ActivitiesDetailPage extends StatefulWidget {
  const ActivitiesDetailPage({super.key, required this.childId});

  final int childId;

  @override
  State<ActivitiesDetailPage> createState() => _ActivitiesDetailPageState();
}

class _ActivitiesDetailPageState extends State<ActivitiesDetailPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _child;
  List<dynamic> _activities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final child = await _api.getChild(widget.childId);
      final activities = await _api.getChildActivities(widget.childId);
      setState(() {
        _child = child;
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = 'Gagal memuat data aktivitas.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivitas Anak')),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: () {
                  setState(() { _isLoading = true; _error = null; });
                  _loadData();
                })
              : _child == null
                  ? AppWidgets.emptyState(icon: Icons.child_care, title: 'Anak tidak ditemukan.')
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          ChildHeader(
                            child: _child,
                            subtitle: 'Aktivitas yang diikuti anak Anda.',
                          ),
                          const SizedBox(height: 20),
                          if (_activities.isEmpty)
                            AppWidgets.emptyState(
                              icon: Icons.emoji_events_outlined,
                              title: 'Belum ada aktivitas',
                              subtitle: 'Aktivitas akan muncul ketika ada kegiatan terbaru.',
                            )
                          else
                            ..._activities.map((a) => _ActivityCard(item: a)),
                        ],
                      ),
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