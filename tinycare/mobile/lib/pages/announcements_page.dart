import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/cached_resource.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/offline_banner.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage>
    with ResourceBinding {
  final ApiService _api = ApiService();
  final ParentDataRepository _repo = ParentDataRepository();

  /// Cache-first announcement list. Deleting/creating re-fetches from the API
  /// so the cache always mirrors what the backend accepted.
  late final CachedResource<List<dynamic>> _res;
  List<dynamic> get _announcements => _res.data ?? const [];

  @override
  void initState() {
    super.initState();
    _res = CachedResource<List<dynamic>>(onChanged: onResourceChanged);
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() => _repo.loadAnnouncements(_res);

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }

  Future<void> _deleteAnnouncement(dynamic item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Hapus Pengumuman')),
        content: Text(tr('Hapus "{{title}}"?', {'title': item['title'] ?? ''})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Batal'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(tr('Hapus')),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await _api.deleteAnnouncement(item['id']);
      if (response['success'] == true) {
        _showToast(tr('Pengumuman berhasil dihapus.'));
        _loadAnnouncements();
      } else {
        _showToast(response['message'] ?? tr('Gagal menghapus.'), isError: true);
      }
    } catch (e) {
      _showToast(tr('Gagal menghapus pengumuman.'), isError: true);
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'urgent': return AppColors.error;
      case 'high': return AppColors.warning;
      case 'normal': return AppColors.primary;
      default: return ThemeHelper.textMuted(context);
    }
  }

  String _getPriorityLabel(String? priority) {
    switch (priority) {
      case 'urgent': return tr('Mendesak');
      case 'high': return tr('Penting');
      case 'normal': return tr('Normal');
      case 'low': return tr('Rendah');
      default: return priority ?? '-';
    }
  }

  IconData _getPriorityIcon(String? priority) {
    switch (priority) {
      case 'urgent': return Icons.warning_amber;
      case 'high': return Icons.info_outline;
      case 'normal': return Icons.announcement;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Pengumuman')),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_outlined),
              onPressed: () async {
                final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _AnnouncementFormPage()));
                if (result == true) _loadAnnouncements();
              },
              tooltip: tr('Tambah Pengumuman'),
            ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(resource: _res, onRetry: _loadAnnouncements),
          Expanded(
            child: _res.isLoading
                ? AppWidgets.loadingIndicator()
                : _res.error != null
                    ? AppWidgets.errorState(
                        message: tr(_res.error!),
                        onRetry: _loadAnnouncements,
                      )
                    : _announcements.isEmpty
                        ? AppWidgets.emptyState(
                            icon: Icons.campaign_outlined,
                            title: tr('Tidak ada pengumuman'),
                            subtitle: isAdmin
                                ? tr('Tekan tombol + untuk membuat pengumuman.')
                                : null,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAnnouncements,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _announcements.length,
                              itemBuilder: (context, index) =>
                                  _buildCard(_announcements[index], isAdmin),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(dynamic item, bool isAdmin) {
    final priority = item['priority'] ?? 'normal';
    final color = _getPriorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: ThemeHelper.border(context)),
        boxShadow: AppColors.cardShadow,
      ),
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => _showDetail(item, isAdmin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(_getPriorityIcon(priority), size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(_getPriorityLabel(priority),
                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item['title'] ?? '-',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
                      ),
                      if (isAdmin)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 18, color: ThemeHelper.textMuted(context)),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final result = await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => _AnnouncementFormPage(announcement: item)));
                              if (result == true) _loadAnnouncements();
                            } else if (value == 'delete') {
                              _deleteAnnouncement(item);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'edit', child: Text(tr('Edit'))),
                            PopupMenuItem(value: 'delete', child: Text(tr('Hapus'))),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['content'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: ThemeHelper.textSecondary(context), height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: ThemeHelper.textMuted(context)),
                      const SizedBox(width: 6),
                      Text(item['publish_date'] ?? item['created_at'] ?? '-',
                          style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(dynamic item, bool isAdmin) {
    final priority = item['priority'] ?? 'normal';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.9, expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: ThemeHelper.border(context), borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    AppWidgets.statusBadge(_getPriorityLabel(priority), _getPriorityColor(priority)),
                    const SizedBox(height: 14),
                    Text(item['title'] ?? '', style: AppTypography.h1.copyWith(color: ThemeHelper.text(context))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: ThemeHelper.textMuted(context)),
                        const SizedBox(width: 6),
                        Text(item['publish_date'] ?? '-', style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(item['content'] ?? '',
                        style: TextStyle(fontSize: 16, height: 1.7, color: ThemeHelper.text(context))),
                  ],
                ),
              );
            },
          );
        },
    );
  }
}

// ==================== Announcement Form ====================
class _AnnouncementFormPage extends StatefulWidget {
  final dynamic announcement;
  const _AnnouncementFormPage({this.announcement});

  @override
  State<_AnnouncementFormPage> createState() => _AnnouncementFormPageState();
}

class _AnnouncementFormPageState extends State<_AnnouncementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _dateController = TextEditingController();
  String _priority = 'normal';
  bool _isSubmitting = false;
  String? _error;

  final ApiService _api = ApiService();
  bool get _isEditing => widget.announcement != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.announcement['title'] ?? '';
      _contentController.text = widget.announcement['content'] ?? '';
      _dateController.text = widget.announcement['publish_date'] ?? '';
      _priority = widget.announcement['priority'] ?? 'normal';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });

    try {
      Map<String, dynamic> response;
      if (_isEditing) {
        response = await _api.updateAnnouncement(
          widget.announcement['id'],
          title: _titleController.text.trim(),
          content: _contentController.text.trim().isNotEmpty ? _contentController.text.trim() : null,
          priority: _priority,
          publishDate: _dateController.text.trim().isNotEmpty ? _dateController.text.trim() : null,
        );
      } else {
        response = await _api.createAnnouncement(
          title: _titleController.text.trim(),
          content: _contentController.text.trim().isNotEmpty ? _contentController.text.trim() : null,
          priority: _priority,
          publishDate: _dateController.text.trim().isNotEmpty ? _dateController.text.trim() : null,
        );
      }

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? tr('Pengumuman diperbarui.') : tr('Pengumuman dibuat.')),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() { _error = response['message'] ?? tr('Gagal menyimpan.'); _isSubmitting = false; });
      }
    } catch (e) {
      setState(() { _error = tr('Gagal menyimpan. Silakan coba lagi.'); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? tr('Edit Pengumuman') : tr('Tambah Pengumuman'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                AppWidgets.errorAlert(_error!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Judul *')),
                validator: (v) => v == null || v.isEmpty ? tr('Judul tidak boleh kosong') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 6,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Isi Pengumuman *'), alignLabelWithHint: true),
                validator: (v) => v == null || v.isEmpty ? tr('Isi pengumuman tidak boleh kosong') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Tanggal Publikasi'), hintText: tr('YYYY-MM-DD')),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),
              Text(tr('Prioritas'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPriorityChip('low', tr('Rendah')),
                  _buildPriorityChip('normal', tr('Normal')),
                  _buildPriorityChip('high', tr('Penting')),
                  _buildPriorityChip('urgent', tr('Mendesak')),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSave,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isEditing ? tr('Simpan Perubahan') : tr('Buat Pengumuman'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label) {
    final selected = _priority == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : ThemeHelper.textSecondary(context))),
      selected: selected,
      onSelected: (_) => setState(() => _priority = value),
      selectedColor: AppColors.primary,
      backgroundColor: ThemeHelper.surface(context),
      side: BorderSide(color: ThemeHelper.border(context)),
    );
  }
}
