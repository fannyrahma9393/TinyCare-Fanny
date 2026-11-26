import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/cached_resource.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/child_photo.dart';
import '../widgets/offline_banner.dart';
import '../l10n/app_strings.dart';

/// Child Information — mirrors web ChildInformation.jsx + ParentInformation.jsx.
/// Both admin and parent see child card grid first. Click a child to see their
/// information list.
class ChildInformationPage extends StatefulWidget {
  const ChildInformationPage({super.key});

  @override
  State<ChildInformationPage> createState() => _ChildInformationPageState();
}

class _ChildInformationPageState extends State<ChildInformationPage>
    with ResourceBinding {
  final ApiService _api = ApiService();
  final ParentDataRepository _repo = ParentDataRepository();

  /// Cache-first children list plus a per-selection information resource.
  late final CachedResource<List<dynamic>> _childrenRes;
  CachedResource<List<dynamic>>? _infoRes;

  List<dynamic> get _children => _childrenRes.data ?? const [];
  List<dynamic> get _informations => _infoRes?.data ?? const [];
  int? _selectedChildId;
  bool get _isAdmin => context.read<AuthProvider>().isAdmin;

  /// State of whichever pane is currently on screen.
  String? get _error =>
      _selectedChildId == null ? _childrenRes.error : _infoRes?.error;
  bool get _isLoading => _selectedChildId == null
      ? _childrenRes.isLoading
      : (_infoRes?.isLoading ?? false);

  @override
  void initState() {
    super.initState();
    _childrenRes = CachedResource<List<dynamic>>(onChanged: onResourceChanged);
    _loadData();
  }

  Future<void> _loadData() => _repo.loadChildren(_childrenRes);

  /// Refreshes the currently selected child's information entries.
  Future<void> _selectChild(int childId) {
    final resource = _infoRes;
    if (resource == null) return Future.value();
    return _repo.loadChildInformationFor(childId, resource, isAdmin: _isAdmin);
  }

  /// Opens a child's information pane. A fresh resource per selection keeps one
  /// child's cached entries from flashing under another child's header.
  void _openChild(int childId) {
    setState(() {
      _selectedChildId = childId;
      _infoRes = CachedResource<List<dynamic>>(onChanged: onResourceChanged);
    });
    _selectChild(childId);
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

  Future<void> _deleteInformation(dynamic info) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Hapus Informasi')),
        content: Text(tr('Hapus informasi "{{title}}"?',
            {'title': info['title'] ?? ''})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('Batal'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(tr('Hapus')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final response = await _api.deleteChildInformation(info['id']);
      if (response['success'] == true) {
        _showToast(tr('Informasi berhasil dihapus.'));
        _selectChild(_selectedChildId!);
      } else {
        _showToast(response['message'] ?? tr('Gagal menghapus.'),
            isError: true);
      }
    } catch (e) {
      _showToast(tr('Gagal menghapus.'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Informasi Anak')),
        actions: [
          if (isAdmin && _selectedChildId != null)
            IconButton(
              icon: const Icon(Icons.add_outlined),
              tooltip: tr('Tambah Informasi'),
              onPressed: () async {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => _InformationFormPage(
                            children: _children,
                            selectedChildId: _selectedChildId)));
                if (result == true) _selectChild(_selectedChildId!);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(
            resource: _infoRes ?? _childrenRes,
            onRetry: _selectedChildId != null
                ? () => _selectChild(_selectedChildId!)
                : _loadData,
          ),
          Expanded(
            child: _selectedChildId == null
                ? _buildChildGrid(context, textColor, mutedColor)
                : _buildInfoList(context, textColor, mutedColor),
          ),
        ],
      ),
    );
  }

  /// Child card grid — matches web ChildInformation.jsx / ParentInformation.jsx
  Widget _buildChildGrid(
      BuildContext context, Color textColor, Color mutedColor) {
    if (_isLoading) return AppWidgets.loadingIndicator();
    if (_error != null) {
      return AppWidgets.errorState(
          message: tr(_error!), onRetry: _loadData);
    }
    if (_children.isEmpty) {
      return AppWidgets.emptyState(
        icon: Icons.child_care,
        title: tr('Belum ada data anak'),
        subtitle: tr('Tambahkan data anak terlebih dahulu untuk mengelola informasi.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.77,
        ),
        itemCount: _children.length,
        itemBuilder: (context, index) {
          final child = _children[index];
          final isActive = child['status'] == 'active';
          return GestureDetector(
            onTap: () => _openChild(child['id']),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: ThemeHelper.surface(context),
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: ThemeHelper.border(context)),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Center(
                    child: ChildPhoto(
                      child: child,
                      width: 88,
                      radius: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    child['name'] ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? ThemeHelper.successBg(context)
                          : ThemeHelper.bgAlt(context),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      isActive ? tr('Status: Aktif') : tr('Status: Nonaktif'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppColors.success : mutedColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tr('Lihat Informasi'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          size: 14, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Info list for selected child — matches web ChildInformationDetail.jsx
  Widget _buildInfoList(
      BuildContext context, Color textColor, Color mutedColor) {
    final childName = _children
        .where((c) => c['id'] == _selectedChildId)
        .map((c) => c['name'] ?? '-')
        .firstOrNull;

    return Column(
      children: [
        // Back button + child header (matching web)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeHelper.surface(context),
            border: Border(
                bottom: BorderSide(color: ThemeHelper.border(context))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () => setState(() {
                  _selectedChildId = null;
                  _infoRes = null;
                }),
              ),
              const SizedBox(width: 4),
              ChildPhoto(
                child: _children
                    .where((c) => c['id'] == _selectedChildId)
                    .firstOrNull,
                width: 48,
                radius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childName ?? '-',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor),
                    ),
                    Text(
                      tr('Kelola informasi untuk {{name}}',
                          {'name': childName ?? ''}),
                      style: TextStyle(
                          fontSize: 12, color: mutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? AppWidgets.loadingIndicator()
              : _error != null
                  ? AppWidgets.errorState(
                      message: _error!,
                      onRetry: () => _selectChild(_selectedChildId!))
                  : _informations.isEmpty
                      ? AppWidgets.emptyState(
                          icon: Icons.info_outline,
                          title: tr('Belum ada informasi'),
                          subtitle: tr('Belum ada informasi untuk {{name}}.',
                              {'name': childName ?? tr('anak ini')}),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _selectChild(_selectedChildId!),
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _informations.length,
                            itemBuilder: (context, index) =>
                                _buildInfoCard(_informations[index]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(dynamic info) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final priority = info['priority'] ?? 'normal';
    final (label, color, bg) = switch (priority) {
      'urgent' => (tr('Mendesak'), AppColors.error, ThemeHelper.errorBg(context)),
      'important' => (tr('Penting'), AppColors.warning, ThemeHelper.warningBg(context)),
      _ => (tr('Normal'), ThemeHelper.textMuted(context), ThemeHelper.bgAlt(context)),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: ThemeHelper.border(context)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(info['title'] ?? '-',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ThemeHelper.text(context))),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(99)),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 18,
                      color: ThemeHelper.textMuted(context)),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => _InformationFormPage(
                                  children: _children,
                                  information: info,
                                  selectedChildId: _selectedChildId)));
                      if (result == true) {
                        _selectChild(_selectedChildId!);
                      }
                    } else if (value == 'delete') {
                      _deleteInformation(info);
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
          Text(info['content'] ?? '',
              style: TextStyle(
                  fontSize: 13,
                  color: ThemeHelper.textSecondary(context),
                  height: 1.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(_formatDate(info['created_at']),
                  style: TextStyle(
                      fontSize: 11,
                      color: ThemeHelper.textMuted(context))),
              if (info['creator'] != null)
                Text(
                    tr(' · oleh {{name}}', {
                      'name': info['creator']['name'] ?? '',
                    }),
                    style: TextStyle(
                        fontSize: 11,
                        color: ThemeHelper.textMuted(context))),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final s = value.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}

class _InformationFormPage extends StatefulWidget {
  final List<dynamic> children;
  final dynamic information;
  final int? selectedChildId;

  const _InformationFormPage(
      {required this.children, this.information, this.selectedChildId});

  @override
  State<_InformationFormPage> createState() => _InformationFormPageState();
}

class _InformationFormPageState extends State<_InformationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  int? _childId;
  String _priority = 'normal';
  bool _isSubmitting = false;
  String? _error;
  final ApiService _api = ApiService();

  bool get _isEditing => widget.information != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.information['title'] ?? '';
      _contentController.text = widget.information['content'] ?? '';
      _childId = widget.information['child']?['id'] ??
          widget.information['child_id'];
      _priority = widget.information['priority'] ?? 'normal';
    } else {
      _childId = widget.selectedChildId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      Map<String, dynamic> response;
      if (_isEditing) {
        response = await _api.updateChildInformation(
          widget.information['id'],
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          priority: _priority,
        );
      } else {
        response = await _api.createChildInformation(
          childId: _childId!,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          priority: _priority,
        );
      }
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing
                  ? tr('Informasi diperbarui.')
                  : tr('Informasi berhasil dibuat.')),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _error = response['message'] ?? tr('Gagal menyimpan.');
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = tr('Gagal menyimpan. Silakan coba lagi.');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? tr('Edit Informasi') : tr('Tambah Informasi'))),
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
              if (!_isEditing && _childId == null) ...[
                DropdownButtonFormField<int>(
                  initialValue: _childId,
                  decoration:
                      InputDecoration(labelText: tr('Anak *')),
                  items: widget.children
                      .map<DropdownMenuItem<int>>((c) =>
                          DropdownMenuItem(
                              value: c['id'],
                              child: Text(c['name'] ?? '-')))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _childId = v),
                  validator: (v) => v == null ? tr('Pilih anak') : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration:
                    InputDecoration(labelText: tr('Judul *')),
                validator: (v) => v == null || v.isEmpty
                    ? tr('Judul tidak boleh kosong')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                    labelText: tr('Konten *'), alignLabelWithHint: true),
                validator: (v) => v == null || v.isEmpty
                    ? tr('Konten tidak boleh kosong')
                    : null,
              ),
              const SizedBox(height: 16),
              Text(tr('Prioritas'),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ThemeHelper.text(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPriorityChip('normal', tr('Normal')),
                  _buildPriorityChip('important', tr('Penting')),
                  _buildPriorityChip('urgent', tr('Mendesak')),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSave,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _isEditing
                              ? tr('Simpan Perubahan')
                              : tr('Simpan Informasi'),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
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
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: selected
                  ? Colors.white
                  : ThemeHelper.textSecondary(context))),
      selected: selected,
      onSelected: (_) => setState(() => _priority = value),
      selectedColor: AppColors.primary,
      backgroundColor: ThemeHelper.surface(context),
      side: BorderSide(color: ThemeHelper.border(context)),
    );
  }
}
