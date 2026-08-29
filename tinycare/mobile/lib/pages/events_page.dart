import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/api_error.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final ApiService _api = ApiService();
  List<dynamic> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final rawData = await _api.getEvents();
      if (!mounted) return;
      setState(() { _events = rawData; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = ApiErrorHandler.getMessage(e); _isLoading = false; });
    }
  }

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

  Future<void> _deleteEvent(dynamic event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Acara'),
        content: Text('Hapus "${event['title'] ?? ''}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await _api.deleteEvent(event['id']);
      if (response['success'] == true) {
        _showToast('Acara berhasil dihapus.');
        _loadEvents();
      } else {
        _showToast(response['message'] ?? 'Gagal menghapus.', isError: true);
      }
    } catch (e) {
      _showToast('Gagal menghapus acara.', isError: true);
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'activity': return AppColors.primary;
      case 'holiday': return AppColors.info;
      case 'special': return Colors.purple;
      case 'meeting': return AppColors.warning;
      default: return ThemeHelper.textMuted(context);
    }
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'activity': return 'Aktivitas';
      case 'holiday': return 'Libur';
      case 'special': return 'Spesial';
      case 'meeting': return 'Meeting';
      default: return type ?? '-';
    }
  }

  String _getTypeEmoji(String? type) {
    switch (type) {
      case 'activity': return '🎯';
      case 'holiday': return '🏖️';
      case 'special': return '⭐';
      case 'meeting': return '👥';
      default: return '📅';
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final d = DateTime.parse(date);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acara'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_outlined),
              onPressed: () async {
                final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EventFormPage()));
                if (result == true) _loadEvents();
              },
              tooltip: 'Tambah Acara',
            ),
        ],
      ),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _loadEvents)
              : _events.isEmpty
                  ? AppWidgets.emptyState(
                      icon: Icons.calendar_today,
                      title: 'Belum ada acara',
                      subtitle: isAdmin ? 'Tekan tombol + untuk membuat acara.' : null,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEvents,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _events.length,
                        itemBuilder: (context, index) => _buildEventCard(_events[index], isAdmin),
                      ),
                    ),
    );
  }

  Widget _buildEventCard(dynamic event, bool isAdmin) {
    final type = event['type'] ?? 'activity';
    final typeColor = _getTypeColor(type);
    final startDate = event['date'];
    DateTime? dateObj;
    try { dateObj = DateTime.parse(startDate ?? ''); } catch (_) {}

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
        onTap: () => _showDetail(event, isAdmin),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${dateObj?.day ?? '?'}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: typeColor)),
                    Text(_getTypeEmoji(type), style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event['title'] ?? 'Tanpa judul',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: ThemeHelper.textMuted(context)),
                        const SizedBox(width: 4),
                        Text(_formatDate(startDate), style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                        if (event['start_time'] != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, size: 12, color: ThemeHelper.textMuted(context)),
                          const SizedBox(width: 4),
                          Text(event['start_time'] ?? '', style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                        ],
                      ],
                    ),
                    if (event['location'] != null && event['location'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: ThemeHelper.textMuted(context)),
                          const SizedBox(width: 4),
                          Text(event['location'] ?? '', style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    AppWidgets.statusBadge(_getTypeLabel(type), typeColor),
                  ],
                ),
              ),
              Column(
                children: [
                  if (isAdmin)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 18, color: ThemeHelper.textMuted(context)),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final result = await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => EventFormPage(event: event)));
                          if (result == true) _loadEvents();
                        } else if (value == 'delete') {
                          _deleteEvent(event);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  Icon(Icons.chevron_right, color: ThemeHelper.textMuted(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(dynamic event, bool isAdmin) {
    final type = event['type'] ?? 'activity';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55, minChildSize: 0.3, maxChildSize: 0.85, expand: false,
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
                  Row(
                    children: [
                      Text(_getTypeEmoji(type), style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event['title'] ?? 'Tanpa judul', style: AppTypography.h2.copyWith(color: ThemeHelper.text(context))),
                            const SizedBox(height: 6),
                            AppWidgets.statusBadge(_getTypeLabel(type), _getTypeColor(type)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: ThemeHelper.bgAlt(context), borderRadius: AppRadius.lgAll),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: ThemeHelper.textMuted(context)),
                            const SizedBox(width: 12),
                            Text(_formatDate(event['date'])),
                          ],
                        ),
                        if (event['start_time'] != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 18, color: ThemeHelper.textMuted(context)),
                              const SizedBox(width: 12),
                              Text('${event['start_time']}${event['end_time'] != null ? ' - ${event['end_time']}' : ''}'),
                            ],
                          ),
                        ],
                        if (event['location'] != null && event['location'].toString().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 18, color: ThemeHelper.textMuted(context)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(event['location'])),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (event['description'] != null && event['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Deskripsi', style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
                    const SizedBox(height: 10),
                    Text(event['description'],
                        style: TextStyle(fontSize: 14, height: 1.7, color: ThemeHelper.text(context))),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ==================== Event Form (Create/Edit) ====================
class EventFormPage extends StatefulWidget {
  final dynamic event;
  const EventFormPage({super.key, this.event});

  @override
  State<EventFormPage> createState() => EventFormPageState();
}

class EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _locationController = TextEditingController();
  String _type = 'activity';
  bool _isSubmitting = false;
  String? _error;

  final ApiService _api = ApiService();
  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.event['title'] ?? '';
      _descriptionController.text = widget.event['description'] ?? '';
      _dateController.text = widget.event['date'] ?? '';
      _startTimeController.text = widget.event['start_time'] ?? '';
      _endTimeController.text = widget.event['end_time'] ?? '';
      _locationController.text = widget.event['location'] ?? '';
      _type = widget.event['type'] ?? 'activity';
    } else {
      // Default date = today
      _dateController.text = ApiService.today();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });

    try {
      Map<String, dynamic> response;
      if (_isEditing) {
        response = await _api.updateEvent(
          widget.event['id'],
          title: _titleController.text.trim(),
          date: _dateController.text.trim().isNotEmpty ? _dateController.text.trim() : null,
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
          type: _type,
          startTime: _startTimeController.text.trim().isNotEmpty ? _startTimeController.text.trim() : null,
          endTime: _endTimeController.text.trim().isNotEmpty ? _endTimeController.text.trim() : null,
          location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        );
      } else {
        response = await _api.createEvent(
          title: _titleController.text.trim(),
          date: _dateController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
          type: _type,
          startTime: _startTimeController.text.trim().isNotEmpty ? _startTimeController.text.trim() : null,
          endTime: _endTimeController.text.trim().isNotEmpty ? _endTimeController.text.trim() : null,
          location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        );
      }

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Acara diperbarui.' : 'Acara dibuat.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() { _error = response['message'] ?? 'Gagal menyimpan.'; _isSubmitting = false; });
      }
    } catch (e) {
      setState(() { _error = ApiErrorHandler.getMessage(e); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Acara' : 'Tambah Acara')),
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
                decoration: const InputDecoration(labelText: 'Judul Acara *'),
                validator: (v) => v == null || v.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Deskripsi', alignLabelWithHint: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Tanggal *', hintText: 'YYYY-MM-DD'),
                keyboardType: TextInputType.datetime,
                validator: (v) => v == null || v.isEmpty ? 'Tanggal tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Lokasi'),
              ),
              const SizedBox(height: 16),
              Text('Tipe Acara', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _buildTypeChip('activity', '🎯 Aktivitas'),
                  _buildTypeChip('holiday', '🏖️ Libur'),
                  _buildTypeChip('special', '⭐ Spesial'),
                  _buildTypeChip('meeting', '👥 Meeting'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration: const InputDecoration(labelText: 'Waktu Mulai', hintText: 'HH:MM'),
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration: const InputDecoration(labelText: 'Waktu Selesai', hintText: 'HH:MM'),
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSave,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isEditing ? 'Simpan Perubahan' : 'Buat Acara',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String value, String label) {
    final selected = _type == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : ThemeHelper.textSecondary(context))),
      selected: selected,
      onSelected: (_) => setState(() => _type = value),
      selectedColor: AppColors.primary,
      backgroundColor: ThemeHelper.surface(context),
      side: BorderSide(color: ThemeHelper.border(context)),
    );
  }
}
