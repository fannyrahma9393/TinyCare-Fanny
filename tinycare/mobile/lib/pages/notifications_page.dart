import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'announcement_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ApiService _api = ApiService();
  List<dynamic> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _api.getNotifications();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat notifikasi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
      await _load();
      if (!mounted) return;
      AppWidgets.showSnackBar(context, 'Semua notifikasi ditandai sudah dibaca.');
    } catch (e) {
      if (!mounted) return;
      AppWidgets.showSnackBar(context, 'Gagal menandai notifikasi.', isError: true);
    }
  }

  /// Open the target page for a notification. Announcement notifications
  /// (type=announcement with data.announcement_id) open the announcement
  /// detail; other types just mark as read.
  void _handleTap(dynamic n) {
    final id = n['id'] as int;
    final isRead = n['is_read'] == true;
    final type = n['type'] as String?;

    if (type == 'announcement') {
      final data = n['data'];
      final announcementId = (data is Map && data['announcement_id'] != null)
          ? int.tryParse(data['announcement_id'].toString())
          : null;
      if (announcementId != null) {
        if (!isRead) _markRead(id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnnouncementDetailPage(announcementId: announcementId),
          ),
        );
        return;
      }
    }

    if (!isRead) _markRead(id);
  }

  Future<void> _markRead(int id) async {
    try {
      await _api.markNotificationRead(id);
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          if (_items[i]['id'] == id) {
            _items[i]['is_read'] = true;
            _items[i]['read_at'] = DateTime.now().toIso8601String();
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      AppWidgets.showSnackBar(context, 'Gagal memperbarui notifikasi.', isError: true);
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'payment':
        return Icons.payment;
      case 'invoice':
        return Icons.receipt_long;
      case 'attendance':
        return Icons.calendar_today;
      case 'activity':
        return Icons.emoji_events_outlined;
      case 'daily_story':
        return Icons.auto_stories;
      case 'child_information':
        return Icons.fact_check_outlined;
      case 'announcement':
        return Icons.campaign;
      case 'event':
        return Icons.event;
      case 'feedback':
        return Icons.rate_review;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _timeLabel(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final date = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inHours < 1) return '${diff.inMinutes} mnt lalu';
      if (diff.inDays < 1) return '${diff.inHours} jam lalu';
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (_items.any((n) => n['is_read'] == false))
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, size: 18, color: Colors.white),
              label: const Text(
                'Baca Semua',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? AppWidgets.emptyState(
                      icon: Icons.notifications_outlined,
                      title: 'Belum ada notifikasi',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _buildNotificationCard(_items[index]),
                      ),
                    ),
    );
  }

  Widget _buildNotificationCard(dynamic n) {
    final isRead = n['is_read'] == true;
    final title = n['title'] as String? ?? 'Notifikasi';
    final message = n['message'] as String?;
    final type = n['type'] as String?;
    final time = _timeLabel(n['created_at'] as String?);

    return InkWell(
      onTap: () => _handleTap(n),
      borderRadius: AppRadius.lgAll,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? ThemeHelper.surface(context)
              : ThemeHelper.successBg(context),
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: isRead
                ? ThemeHelper.border(context)
                : AppColors.primaryLight,
          ),
          boxShadow: isRead ? null : AppColors.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(
                _iconForType(type),
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                            color: ThemeHelper.text(context),
                          ),
                        ),
                      ),
                      if (!isRead) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: ThemeHelper.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                  if (message != null && message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: ThemeHelper.textSecondary(context),
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}