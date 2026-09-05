import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Admin events page — mirrors web Events.
///
/// Lists upcoming and past events with date, title, description.
/// Admin can create, edit, delete events.
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _api = ApiService();
  List<dynamic> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final events = await _api.getEvents();
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data acara.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);
    final surfaceColor = ThemeHelper.surface(context);
    final borderColor = ThemeHelper.border(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _EventFormPage()),
              );
              if (result == true) _loadEvents();
            },
          ),
        ],
      ),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _loadEvents)
              : _events.isEmpty
                  ? AppWidgets.emptyState(
                      icon: Icons.event_outlined,
                      title: 'Belum ada acara',
                      subtitle: 'Tekan tombol + untuk menambahkan acara.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEvents,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _events.length,
                        itemBuilder: (context, index) =>
                            _buildEventCard(_events[index]),
                      ),
                    ),
    );
  }

  Widget _buildEventCard(dynamic event) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);
    final surfaceColor = ThemeHelper.surface(context);
    final borderColor = ThemeHelper.border(context);
    final isActive = (event['status'] ?? 'active') == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: borderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'] ?? '-',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(event['start_date'] ?? ''),
                          style: TextStyle(fontSize: 12, color: mutedColor),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          event['start_time'] ?? '',
                          style: TextStyle(fontSize: 12, color: mutedColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppWidgets.statusBadge(
                isActive ? 'Aktif' : 'Terselesaikan',
                isActive ? AppColors.success : mutedColor,
              ),
            ],
          ),
          if (event['description'] != null && event['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              event['description'].toString(),
              style: TextStyle(fontSize: 12, color: mutedColor, height: 1.5),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => _EventFormPage(event: event)),
                    );
                    if (result == true) _loadEvents();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteEvent(event),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Hapus', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(dynamic event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Acara'),
        content: Text('Yakin ingin menghapus acara "${event['title']}"?'),
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
      await _api.deleteEvent(event['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Acara berhasil dihapus.'), backgroundColor: AppColors.success),
      );
      _loadEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Gagal menghapus acara.'), backgroundColor: AppColors.error),
      );
    }
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '-';
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        final m = int.tryParse(parts[1]);
        return '${parts[2]} ${months[m! - 1]} ${parts[0]}';
      }
    } catch (_) {}
    return date;
  }
}

class _EventFormPage extends StatefulWidget {
  final dynamic event;
  const _EventFormPage({this.event});

  @override
  State<_EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<_EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;
  final _api = ApiService();

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.event['title'] ?? '';
      _descriptionController.text = widget.event['description'] ?? '';
      _dateController.text = widget.event['start_date'] ?? '';
      _timeController.text = widget.event['start_time'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });
    try {
      final response = _isEditing
          ? await _api.updateEvent(
              widget.event['id'],
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              startDate: _dateController.text.trim(),
              startTime: _timeController.text.trim(),
            )
          : await _api.createEvent(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              startDate: _dateController.text.trim(),
              startTime: _timeController.text.trim(),
            );
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Acara diperbarui.' : 'Acara berhasil dibuat.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() { _error = response['message'] ?? 'Gagal menyimpan.'; _isSubmitting = false; });
      }
    } catch (e) {
      setState(() { _error = 'Gagal menyimpan. Silakan coba lagi.'; _isSubmitting = false; });
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
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Tanggal *', hintText: 'YYYY-MM-DD'),
                validator: (v) => v == null || v.isEmpty ? 'Tanggal tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: 'Waktu *', hintText: 'HH:MM'),
                validator: (v) => v == null || v.isEmpty ? 'Waktu tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Deskripsi', alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Acara',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
