import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  final ApiService _api = ApiService();
  List<dynamic> _activities = [];
  List<dynamic> _children = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final activities = await _api.getActivities();
      final children = await _api.getChildren();
      setState(() {
        _activities = activities;
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data aktivitas. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredActivities {
    if (_searchQuery.isEmpty) return _activities;
    return _activities.where((a) =>
      (a['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
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

  Future<void> _deleteActivity(dynamic activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Aktivitas'),
        content: Text('Hapus aktivitas "${activity['name'] ?? ''}"?'),
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
      final response = await _api.deleteActivity(activity['id']);
      if (response['success'] == true) {
        _showToast('Aktivitas berhasil dihapus.');
        _loadData();
      } else {
        _showToast(response['message'] ?? 'Gagal menghapus aktivitas.', isError: true);
      }
    } catch (e) {
      _showToast('Gagal menghapus aktivitas.', isError: true);
    }
  }

  // Backend Activity field: category (not type)
  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'fisik': return AppColors.success;
      case 'kognitif': return AppColors.info;
      case 'kreatif': return Colors.purple;
      case 'sosial': return AppColors.warning;
      case 'umum': return AppColors.primary;
      default: return ThemeHelper.textMuted(context);
    }
  }

  String _getCategoryLabel(String? category) {
    switch (category) {
      case 'fisik': return 'Fisik';
      case 'kognitif': return 'Kognitif';
      case 'kreatif': return 'Kreatif';
      case 'sosial': return 'Sosial';
      case 'umum': return 'Umum';
      default: return category ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas'),
        actions: [
          if (isAdmin && _children.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_outlined),
              onPressed: () async {
                final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => _ActivityFormPage(children: _children)));
                if (result == true) _loadData();
              },
              tooltip: 'Tambah Aktivitas',
            ),
        ],
      ),
      body: Column(
        children: [
if (_activities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari aktivitas...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: BorderSide(color: ThemeHelper.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: BorderSide(color: ThemeHelper.border(context)),
                  ),
                  filled: true,
                  fillColor: ThemeHelper.surface(context),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? AppWidgets.loadingIndicator()
                : _error != null
                    ? AppWidgets.errorState(message: _error!, onRetry: _loadData)
                    : _filteredActivities.isEmpty
                        ? AppWidgets.emptyState(
                            icon: Icons.emoji_events_outlined,
                            title: 'Belum ada aktivitas',
                            subtitle: isAdmin ? 'Tekan tombol + untuk menambah aktivitas.' : null,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredActivities.length,
                              itemBuilder: (context, index) =>
                                  _buildActivityCard(_filteredActivities[index], isAdmin),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(dynamic activity, bool isAdmin) {
    final category = activity['category'] ?? 'umum';
    final categoryColor = _getCategoryColor(category);

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
        onTap: isAdmin ? () async {
          final result = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => _ActivityFormPage(
              activity: activity, children: _children)));
          if (result == true) _loadData();
        } : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      activity['name'] ?? '-',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ThemeHelper.text(context)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppWidgets.statusBadge(_getCategoryLabel(category), categoryColor),
                ],
              ),
              if (activity['description'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  activity['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary(context), height: 1.5),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (activity['child'] != null) ...[
                    Icon(Icons.child_care, size: 14, color: ThemeHelper.textMuted(context)),
                    const SizedBox(width: 6),
                    Text(activity['child']['name'] ?? '-',
                        style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context))),
                    const SizedBox(width: 16),
                  ],
                  if (activity['date'] != null) ...[
                    Icon(Icons.calendar_today, size: 12, color: ThemeHelper.textMuted(context)),
                    const SizedBox(width: 6),
                    Text(activity['date'], style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context))),
                  ],
                  const Spacer(),
                  if (isAdmin)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 18, color: ThemeHelper.textMuted(context)),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final result = await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => _ActivityFormPage(
                              activity: activity, children: _children)));
                          if (result == true) _loadData();
                        } else if (value == 'delete') {
                          _deleteActivity(activity);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Activity Form (Create/Edit) ====================
class _ActivityFormPage extends StatefulWidget {
  final dynamic activity;
  final List<dynamic> children;
  const _ActivityFormPage({this.activity, required this.children});

  @override
  State<_ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<_ActivityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'umum';
  bool _isSubmitting = false;
  String? _error;

  final ApiService _api = ApiService();
  bool get _isEditing => widget.activity != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.activity['name'] ?? '';
      _descriptionController.text = widget.activity['description'] ?? '';
      _category = widget.activity['category'] ?? 'umum';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });

    try {
      Map<String, dynamic> response;
      if (_isEditing) {
        response = await _api.updateActivity(
          widget.activity['id'],
          name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
          category: _category,
        );
      } else {
        response = await _api.createActivity(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
          category: _category,
        );
      }

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Aktivitas diperbarui.' : 'Aktivitas ditambahkan.'),
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
      setState(() { _error = 'Gagal menyimpan. Silakan coba lagi.'; _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Aktivitas' : 'Tambah Aktivitas')),
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
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nama Aktivitas *'),
                validator: (v) => v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Deskripsi', alignLabelWithHint: true),
              ),
              const SizedBox(height: 16),

              // Category selector (backend field: category)
              Text('Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCategoryChip('umum', 'Umum'),
                  _buildCategoryChip('fisik', 'Fisik'),
                  _buildCategoryChip('kognitif', 'Kognitif'),
                  _buildCategoryChip('kreatif', 'Kreatif'),
                  _buildCategoryChip('sosial', 'Sosial'),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSave,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Aktivitas',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final selected = _category == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : ThemeHelper.textSecondary(context))),
      selected: selected,
      onSelected: (_) => setState(() => _category = value),
      selectedColor: AppColors.primary,
      backgroundColor: ThemeHelper.surface(context),
      side: BorderSide(color: ThemeHelper.border(context)),
    );
  }
}
