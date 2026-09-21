import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'announcement_detail_page.dart';
import 'invoice_detail_page.dart';
import '../l10n/app_strings.dart';

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
        _error = tr('Gagal memuat notifikasi.');
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
      await _load();
      if (!mounted) return;
      AppWidgets.showSnackBar(context, tr('Semua notifikasi ditandai sudah dibaca.'));
    } catch (e) {
      if (!mounted) return;
      AppWidgets.showSnackBar(context, tr('Gagal menandai notifikasi.'), isError: true);
    }
  }

  /// Open the target page for a notification.
  /// - announcement (with announcement_id) opens the announcement detail.
  /// - invoice/payment events (with invoice_id) open the invoice detail.
  /// - payment_submitted (admin) opens the payments list.
  /// - feedback events open the feedback list.
  /// Other types just mark as read.
  void _handleTap(dynamic n) {
    final id = n['id'] as int;
    final isRead = n['is_read'] == true;
    final type = n['type'] as String?;
    final data = n['data'];
    final dataMap = (data is Map) ? data : const <dynamic, dynamic>{};

    int? asInt(dynamic v) => v == null ? null : int.tryParse(v.toString());

    if (type == 'announcement') {
      final announcementId = asInt(dataMap['announcement_id']);
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

    // Invoice / payment notifications that carry an invoice_id open the
    // invoice detail directly (parent view).
    final invoiceId = asInt(dataMap['invoice_id']);
    const invoiceDeepLinkTypes = {
      'invoice',
      'invoice_created',
      'payment_verified',
      'payment_rejected',
    };
    if (invoiceId != null && invoiceDeepLinkTypes.contains(type)) {
      if (!isRead) _markRead(id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceDetailPage(invoiceId: invoiceId),
        ),
      );
      return;
    }

    // Feedback notifications -> feedback page (no standalone detail page).
    if (type == 'feedback' || type == 'feedback_created' || type == 'feedback_replied') {
      if (!isRead) _markRead(id);
      Navigator.pushNamed(context, '/feedback');
      return;
    }

    // Payment submitted (admin) -> payments page.
    if (type == 'payment_submitted' || type == 'payment') {
      if (!isRead) _markRead(id);
      Navigator.pushNamed(context, '/payments');
      return;
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
      AppWidgets.showSnackBar(context, tr('Gagal memperbarui notifikasi.'), isError: true);
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'payment':
      case 'payment_submitted':
        return Icons.payment;
      case 'payment_verified':
        return Icons.verified;
      case 'payment_rejected':
        return Icons.cancel;
      case 'invoice':
      case 'invoice_created':
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
      case 'feedback_created':
      case 'feedback_replied':
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
      if (diff.inMinutes < 1) return tr('Baru saja');
      if (diff.inHours < 1) {
        return tr('{{minutes}} mnt lalu', {'minutes': diff.inMinutes});
      }
      if (diff.inDays < 1) {
        return tr('{{hours}} jam lalu', {'hours': diff.inHours});
      }
      final months = [
        tr('Jan'), tr('Feb'), tr('Mar'), tr('Apr'), tr('Mei'), tr('Jun'),
        tr('Jul'), tr('Agu'), tr('Sep'), tr('Okt'), tr('Nov'), tr('Des'),
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
        title: Text(tr('Notifikasi')),
        actions: [
          if (_items.any((n) => n['is_read'] == false))
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, size: 18, color: Colors.white),
              label: Text(
                tr('Baca Semua'),
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
                      title: tr('Belum ada notifikasi'),
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
    final title = n['title'] as String? ?? tr('Notifikasi');
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