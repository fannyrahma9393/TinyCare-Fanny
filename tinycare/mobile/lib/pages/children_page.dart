import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/api_error.dart';
import '../utils/currency.dart';
import '../widgets/child_photo.dart';
import 'child_detail_page.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';

class ChildrenPage extends StatefulWidget {
  const ChildrenPage({super.key});

  @override
  State<ChildrenPage> createState() => _ChildrenPageState();
}

class _ChildrenPageState extends State<ChildrenPage> {
  final ApiService _api = ApiService();
  List<dynamic> _children = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final children = await _api.getChildren();
      setState(() {
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = tr('Gagal memuat data anak. Silakan coba lagi.');
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredChildren {
    if (_searchQuery.isEmpty) return _children;
    return _children.where((c) =>
      (c['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())
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

  Future<void> _toggleChildStatus(dynamic child) async {
    final isActive = (child['status'] ?? 'active') == 'active';
    final newStatus = isActive ? 'inactive' : 'active';
    final action = isActive ? tr('menonaktifkan') : tr('mengaktifkan');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? tr('Nonaktifkan Anak') : tr('Aktifkan Anak')),
        content: Text(tr('Apakah Anda yakin ingin {{action}} {{name}}?', {
          'action': action,
          'name': child['name'] ?? tr('anak ini'),
        })),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Batal'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isActive ? AppColors.error : AppColors.primary,
            ),
            child: Text(isActive ? tr('Nonaktifkan') : tr('Aktifkan')),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await _api.updateChild(child['id'], status: newStatus);
      if (response['success'] == true) {
        _showToast(tr('Anak berhasil {{action}}.',
            {'action': isActive ? tr('dinonaktifkan') : tr('diaktifkan')}));
        _loadChildren();
      } else {
        _showToast(response['message'] ?? tr('Gagal {{action}} anak.', {'action': action}), isError: true);
      }
    } catch (e) {
      _showToast(tr('Gagal {{action}} anak. Silakan coba lagi.', {'action': action}), isError: true);
    }
  }

  Future<void> _deleteChild(dynamic child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Hapus Anak')),
        content: Text(tr('Apakah Anda yakin ingin menghapus {{name}}?',
            {'name': child['name'] ?? tr('anak ini')})),
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
      final response = await _api.deleteChild(child['id']);
      if (response['success'] == true) {
        _showToast(tr('Anak berhasil dihapus.'));
        _loadChildren();
      } else {
        _showToast(response['message'] ?? tr('Gagal menghapus anak.'), isError: true);
      }
    } catch (e) {
      _showToast(tr('Gagal menghapus anak. Silakan coba lagi.'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Anak')),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () async {
                final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _ChildFormPage()));
                if (result == true) _loadChildren();
              },
              tooltip: tr('Tambah Anak'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: tr('Cari nama anak...'),
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

          // List
          Expanded(
            child: _isLoading
                ? AppWidgets.loadingIndicator()
                : _error != null
                    ? AppWidgets.errorState(message: _error!, onRetry: _loadChildren)
                    : _filteredChildren.isEmpty
                        ? AppWidgets.emptyState(
                            icon: Icons.child_care,
                            title: _searchQuery.isNotEmpty
                                ? tr('Tidak ditemukan')
                                : tr('Belum ada anak terdaftar'),
                            subtitle: _searchQuery.isNotEmpty
                                ? tr('Coba kata kunci lain.')
                                : tr('Tekan tombol + untuk menambah anak.'),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadChildren,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredChildren.length,
                              itemBuilder: (context, index) =>
                                  _buildChildCard(_filteredChildren[index], isAdmin),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(dynamic child, bool isAdmin) {
    final packages = child['child_packages'] ?? [];
    final activePackage = packages.isNotEmpty ? packages.first['package'] : null;
    final status = child['status'] ?? 'active';
    final statusColor = status == 'active' ? AppColors.success : ThemeHelper.textMuted(context);

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
        onTap: () {
          if (isAdmin) {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => _ChildFormPage(child: child)));
          } else {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChildDetailPage(childId: child['id'])));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ChildPhoto(child: child, width: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child['name'] ?? '-', style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
                        const SizedBox(height: 4),
                        Text(
                          '${child['gender'] == 'male' ? tr('Laki-laki') : child['gender'] == 'female' ? tr('Perempuan') : '-'} · ${child['birth_date'] ?? '-'}',
                          style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context)),
                        ),
                      ],
                    ),
                  ),
                  AppWidgets.statusBadge(
                    status == 'active' ? tr('Aktif') : tr('Nonaktif'),
                    statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ThemeHelper.bgAlt(context),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Column(
                  children: [
                    AppWidgets.infoRow(
                      tr('Paket Aktif'),
                      activePackage?['name'] ?? tr('Belum ada paket'),
                    ),
                    if (activePackage != null)
                      AppWidgets.infoRow(
                        tr('Harga'),
                        CurrencyHelper.formatRupiah(activePackage['price']),
                      ),
                    // Backend uses parents (many-to-many), not parent
                    if (child['parents'] != null && (child['parents'] as List).isNotEmpty)
                      AppWidgets.infoRow(
                        tr('Orang Tua'),
                        (child['parents'] as List)
                            .map((p) => p['user']?['name'] ?? '-')
                            .join(', '),
                      )
                    else if (child['parent'] != null || child['user'] != null)
                      AppWidgets.infoRow(
                        tr('Orang Tua'),
                        child['parent']?['user']?['name'] ??
                            child['user']?['name'] ?? '-',
                      ),
                  ],
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => _ChildFormPage(child: child)));
                          if (result == true) _loadChildren();
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(tr('Edit'), style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleChildStatus(child),
                        icon: Icon(status == 'active' ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 16),
                        label: Text(status == 'active' ? tr('Nonaktifkan') : tr('Aktifkan'), style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: status == 'active' ? AppColors.warning : AppColors.success,
                          side: BorderSide(color: status == 'active' ? AppColors.warning : AppColors.success),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteChild(child),
                        icon: const Icon(Icons.delete, size: 16),
                        label: Text(tr('Hapus'), style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Child Form (Create/Edit) ====================
class _ChildFormPage extends StatefulWidget {
  final dynamic child;
  const _ChildFormPage({this.child});

  @override
  State<_ChildFormPage> createState() => _ChildFormPageState();
}

class _ChildFormPageState extends State<_ChildFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();
  final _healthController = TextEditingController();
  final _emNameController = TextEditingController();
  final _emPhoneController = TextEditingController();
  String _gender = 'male';
  int? _selectedParentId;
  bool _isSubmitting = false;
  String? _error;
  String? _photoPath;
  List<dynamic> _parents = [];
  List<dynamic> _packages = [];
  int? _selectedPackageId;
  bool _isLoadingPackages = true;
  String? _packageError;

  bool get _isEditing => widget.child != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.child['name'] ?? '';
      _birthDateController.text = widget.child['birth_date'] ?? '';
      _notesController.text = widget.child['notes'] ?? '';
      _addressController.text = widget.child['address'] ?? '';
      _healthController.text = widget.child['health_info'] ?? '';
      _emNameController.text = widget.child['emergency_contact_name'] ?? '';
      _emPhoneController.text = widget.child['emergency_contact_phone'] ?? '';
      _gender = widget.child['gender'] ?? 'male';
      // Backend uses parents (many-to-many), not parent_id
      final parents = widget.child['parents'] as List? ?? [];
      if (parents.isNotEmpty) {
        _selectedParentId = parents[0]['id'];
      } else {
        _selectedParentId = widget.child['parent_id'] ?? widget.child['user_id'];
      }
      // Pre-select active package if editing
      final childPackages = widget.child['child_packages'] as List? ?? [];
      for (final cp in childPackages) {
        if ((cp['status'] ?? '') == 'active') {
          _selectedPackageId = cp['package_id'];
          break;
        }
      }
      if (_selectedPackageId == null && childPackages.isNotEmpty) {
        _selectedPackageId = childPackages[0]['package_id'];
      }
    }
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    debugPrint('[ChildForm] _loadFormData: starting...');

    // Load parents
    try {
      final parents = await _api.getParentsList();
      debugPrint('[ChildForm] Parents loaded: ${parents.length} items');
      if (mounted) setState(() => _parents = parents);
    } catch (e) {
      debugPrint('[ChildForm] Failed to load parents: $e');
    }

    // Load packages
    try {
      debugPrint('[ChildForm] Loading packages...');
      final packages = await _api.getPackages();
      debugPrint('[ChildForm] Packages loaded: ${packages.length} items');
      for (final pkg in packages) {
        debugPrint('[ChildForm]   - id=${pkg["id"]}, name=${pkg["name"]}, status=${pkg["status"]}');
      }
      if (mounted) setState(() { _packages = packages; _isLoadingPackages = false; });
    } catch (e) {
      debugPrint('[ChildForm] Failed to load packages: $e');
      if (mounted) setState(() { _packageError = tr('Gagal memuat paket. Silakan coba lagi.'); _isLoadingPackages = false; });
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  final ApiService _api = ApiService();

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    _healthController.dispose();
    _emNameController.dispose();
    _emPhoneController.dispose();
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
      debugPrint('[ChildForm] _handleSave: name=${_nameController.text.trim()}, gender=$_gender, birthDate=${_birthDateController.text.trim()}, parentId=$_selectedParentId, packageId=$_selectedPackageId, isEditing=$_isEditing');

      if (_isEditing) {
        response = await _api.updateChild(
          widget.child['id'],
          name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
          gender: _gender,
          birthDate: _birthDateController.text.trim().isNotEmpty ? _birthDateController.text.trim() : null,
          parentIds: _selectedParentId != null ? [_selectedParentId!] : null,
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
          healthInfo: _healthController.text.trim().isNotEmpty ? _healthController.text.trim() : null,
          emergencyContactName: _emNameController.text.trim().isNotEmpty ? _emNameController.text.trim() : null,
          emergencyContactPhone: _emPhoneController.text.trim().isNotEmpty ? _emPhoneController.text.trim() : null,
          photoPath: _photoPath,
        );
      } else {
        response = await _api.createChild(
          name: _nameController.text.trim(),
          gender: _gender,
          birthDate: _birthDateController.text.trim().isNotEmpty ? _birthDateController.text.trim() : '2020-01-01',
          parentIds: _selectedParentId != null ? [_selectedParentId!] : [],
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
          healthInfo: _healthController.text.trim().isNotEmpty ? _healthController.text.trim() : null,
          emergencyContactName: _emNameController.text.trim().isNotEmpty ? _emNameController.text.trim() : null,
          emergencyContactPhone: _emPhoneController.text.trim().isNotEmpty ? _emPhoneController.text.trim() : null,
          photoPath: _photoPath,
        );
      }

      debugPrint('[ChildForm] Child save response: success=${response["success"]}');

      if (response['success'] == true) {
        final childData = response['data'];
        final childId = childData?['id'];
        debugPrint('[ChildForm] Child created/updated: id=$childId');

        // Assign package if selected (new child or changed package)
        if (_selectedPackageId != null && childId != null) {
          final previousPackageId = _isEditing ? (widget.child['child_packages'] as List?)?.isNotEmpty == true
              ? widget.child['child_packages'][0]['package_id'] : null : null;
          if (!_isEditing || _selectedPackageId != previousPackageId) {
            try {
              final now = DateTime.now();
              final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
              debugPrint('[ChildForm] Assigning package: childId=$childId, packageId=$_selectedPackageId, startDate=$today');
              final pkgResponse = await _api.assignPackageToChild(childId, packageId: _selectedPackageId!, startDate: today);
              debugPrint('[ChildForm] Package assignment response: success=${pkgResponse["success"]}');
            } catch (e) {
              debugPrint('[ChildForm] Package assignment failed: $e');
            }
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? tr('Anak berhasil diperbarui.') : tr('Anak berhasil ditambahkan.')),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _error = response['message'] ?? tr('Gagal menyimpan data.');
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() { _error = ApiErrorHandler.getMessage(e); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? tr('Edit Anak') : tr('Tambah Anak')),
      ),
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

              // Photo picker
              Center(
                child: InkWell(
                  onTap: _pickPhoto,
                  borderRadius: AppRadius.mdAll,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      color: ThemeHelper.bgAlt(context),
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(color: ThemeHelper.border(context)),
                    ),
                    child: (!kIsWeb && _photoPath != null)
                        ? ClipRRect(
                            borderRadius: AppRadius.mdAll,
                            child: Image.file(
                              File(_photoPath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : _isEditing && widget.child?['photo_url'] != null
                            ? ClipRRect(
                                borderRadius: AppRadius.mdAll,
                                child: Image.network(
                                  ApiService.resolveMediaUrl(widget.child['photo_url']),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo, color: AppColors.primary, size: 28),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isEditing ? tr('Ganti Foto') : tr('Unggah Foto'),
                                    style: TextStyle(fontSize: 12, color: ThemeHelper.textSecondary(context)),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Nama Anak *')),
                validator: (v) => v == null || v.isEmpty ? tr('Nama tidak boleh kosong') : null,
              ),
              const SizedBox(height: 16),

              // Gender
              Text(tr('Jenis Kelamin'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = 'male'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _gender == 'male' ? AppColors.primarySubtle : ThemeHelper.surface(context),
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(
                            color: _gender == 'male' ? AppColors.primary : ThemeHelper.border(context),
                            width: _gender == 'male' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.boy, color: _gender == 'male' ? AppColors.primary : ThemeHelper.textMuted(context)),
                            const SizedBox(width: 8),
                            Text(tr('Laki-laki'), style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _gender == 'male' ? AppColors.primary : ThemeHelper.textSecondary(context),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = 'female'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _gender == 'female' ? AppColors.primarySubtle : ThemeHelper.surface(context),
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(
                            color: _gender == 'female' ? AppColors.primary : ThemeHelper.border(context),
                            width: _gender == 'female' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.girl, color: _gender == 'female' ? AppColors.primary : ThemeHelper.textMuted(context)),
                            const SizedBox(width: 8),
                            Text(tr('Perempuan'), style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _gender == 'female' ? AppColors.primary : ThemeHelper.textSecondary(context),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _birthDateController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: tr('Tanggal Lahir'),
                  hintText: tr('YYYY-MM-DD'),
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),

              // Parent selector
              if (_parents.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  initialValue: _selectedParentId,
                  decoration: InputDecoration(labelText: tr('Orang Tua *')),
                  items: _parents.map<DropdownMenuItem<int>>((p) {
                    final user = p['user'];
                    // Backend requires parents.id, NOT users.id
                    return DropdownMenuItem(
                      value: p['id'] is int ? p['id'] as int : int.tryParse(p['id'].toString()),
                      child: Text(user?['name'] ?? tr('Orang Tua')),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedParentId = v),
                  validator: (v) => v == null ? tr('Pilih orang tua') : null,
                ),
                const SizedBox(height: 16),
              ],

              // Package selector
              const SizedBox(height: 8),
              Text(tr('Paket (Opsional)'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
              const SizedBox(height: 8),
              if (_isLoadingPackages)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ThemeHelper.surface(context),
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: ThemeHelper.border(context)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text(tr('Memuat paket...'), style: TextStyle(fontSize: 13, color: ThemeHelper.textMuted(context))),
                    ],
                  ),
                )
              else if (_packageError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeHelper.errorBg(context),
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_packageError!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                      TextButton(
                        onPressed: () {
                          setState(() { _isLoadingPackages = true; _packageError = null; });
                          _loadFormData();
                        },
                        child: Text(tr('Coba Lagi'), style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                )
              else if (_packages.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ThemeHelper.surface(context),
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: ThemeHelper.border(context)),
                  ),
                  child: Text(tr('Belum ada paket aktif. Tambahkan paket terlebih dahulu.'), style: TextStyle(fontSize: 13, color: ThemeHelper.textMuted(context))),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedPackageId,
                  decoration: InputDecoration(labelText: tr('Pilih Paket')),
                  items: _packages.map<DropdownMenuItem<int>>((pkg) {
                    final pkgPrice = CurrencyHelper.formatRupiah(pkg['price']);
                    final pkgDuration = pkg['duration_days']?.toString() ?? '-';
                    return DropdownMenuItem(
                      value: pkg['id'] is int ? pkg['id'] as int : int.tryParse(pkg['id'].toString()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(pkg['name'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            tr('{{pkgPrice}} · {{pkgDuration}} hari', {'pkgPrice': pkgPrice, 'pkgDuration': pkgDuration}), style: TextStyle(fontSize: 11, color: ThemeHelper.textMuted(context))),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    debugPrint('[ChildForm] Package selected: $v');
                    setState(() => _selectedPackageId = v);
                  },
                ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: tr('Catatan'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                maxLines: 2,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: tr('Alamat'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _healthController,
                maxLines: 3,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: tr('Info Kesehatan'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emNameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Kontak Darurat - Nama')),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emPhoneController,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: tr('Kontak Darurat - Telepon')),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSave,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(_isEditing ? tr('Simpan Perubahan') : tr('Tambah Anak'),
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
