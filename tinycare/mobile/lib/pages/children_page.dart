import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/api_error.dart';
import '../utils/currency.dart';
import 'package:provider/provider.dart';

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
        _error = 'Gagal memuat data anak. Silakan coba lagi.';
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
    final action = isActive ? 'menonaktifkan' : 'mengaktifkan';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isActive ? 'Nonaktifkan' : 'Aktifkan'} Anak'),
        content: Text('Apakah Anda yakin ingin $action ${child['name'] ?? 'anak ini'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isActive ? AppColors.error : AppColors.primary,
            ),
            child: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await _api.updateChild(child['id'], status: newStatus);
      if (response['success'] == true) {
        _showToast('Anak berhasil $action.');
        _loadChildren();
      } else {
        _showToast(response['message'] ?? 'Gagal $action anak.', isError: true);
      }
    } catch (e) {
      _showToast('Gagal $action anak. Silakan coba lagi.', isError: true);
    }
  }

  Future<void> _deleteChild(dynamic child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Anak'),
        content: Text('Apakah Anda yakin ingin menghapus ${child['name'] ?? 'anak ini'}?'),
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
      final response = await _api.deleteChild(child['id']);
      if (response['success'] == true) {
        _showToast('Anak berhasil dihapus.');
        _loadChildren();
      } else {
        _showToast(response['message'] ?? 'Gagal menghapus anak.', isError: true);
      }
    } catch (e) {
      _showToast('Gagal menghapus anak. Silakan coba lagi.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Anak'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () async {
                final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _ChildFormPage()));
                if (result == true) _loadChildren();
              },
              tooltip: 'Tambah Anak',
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
                  hintText: 'Cari nama anak...',
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
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
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
                                ? 'Tidak ditemukan'
                                : 'Belum ada anak terdaftar',
                            subtitle: _searchQuery.isNotEmpty
                                ? 'Coba kata kunci lain.'
                                : 'Tekan tombol + untuk menambah anak.',
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
    final statusColor = status == 'active' ? AppColors.success : AppColors.textMuted;
    final initial = (child['name'] ?? '?')[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () {
          if (isAdmin) {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => _ChildFormPage(child: child)));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child['name'] ?? '-', style: AppTypography.h3),
                        const SizedBox(height: 4),
                        Text(
                          '${child['gender'] == 'male' ? 'Laki-laki' : child['gender'] == 'female' ? 'Perempuan' : '-'} · ${child['birth_date'] ?? '-'}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  AppWidgets.statusBadge(
                    status == 'active' ? 'Aktif' : 'Nonaktif',
                    statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgAlt,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Column(
                  children: [
                    AppWidgets.infoRow(
                      'Paket Aktif',
                      activePackage?['name'] ?? 'Belum ada paket',
                    ),
                    if (activePackage != null)
                      AppWidgets.infoRow(
                        'Harga',
                        CurrencyHelper.formatRupiah(activePackage['price']),
                      ),
                    // Backend uses parents (many-to-many), not parent
                    if (child['parents'] != null && (child['parents'] as List).isNotEmpty)
                      AppWidgets.infoRow(
                        'Orang Tua',
                        (child['parents'] as List)
                            .map((p) => p['user']?['name'] ?? '-')
                            .join(', '),
                      )
                    else if (child['parent'] != null || child['user'] != null)
                      AppWidgets.infoRow(
                        'Orang Tua',
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
                        label: const Text('Edit', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleChildStatus(child),
                        icon: Icon(status == 'active' ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 16),
                        label: Text(status == 'active' ? 'Nonaktifkan' : 'Aktifkan', style: const TextStyle(fontSize: 12)),
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
  String _gender = 'male';
  int? _selectedParentId;
  bool _isSubmitting = false;
  String? _error;
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
      if (mounted) setState(() { _packageError = 'Gagal memuat paket. Silakan coba lagi.'; _isLoadingPackages = false; });
    }
  }

  final ApiService _api = ApiService();

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _notesController.dispose();
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
        );
      } else {
        response = await _api.createChild(
          name: _nameController.text.trim(),
          gender: _gender,
          birthDate: _birthDateController.text.trim().isNotEmpty ? _birthDateController.text.trim() : '2020-01-01',
          parentIds: _selectedParentId != null ? [_selectedParentId!] : [],
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
              content: Text(_isEditing ? 'Anak berhasil diperbarui.' : 'Anak berhasil ditambahkan.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Gagal menyimpan data.';
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Anak' : 'Tambah Anak'),
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

              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nama Anak *'),
                validator: (v) => v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // Gender
              const Text('Jenis Kelamin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = 'male'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _gender == 'male' ? AppColors.primarySubtle : AppColors.surface,
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(
                            color: _gender == 'male' ? AppColors.primary : AppColors.border,
                            width: _gender == 'male' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.boy, color: _gender == 'male' ? AppColors.primary : AppColors.textMuted),
                            const SizedBox(width: 8),
                            Text('Laki-laki', style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _gender == 'male' ? AppColors.primary : AppColors.textSecondary,
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
                          color: _gender == 'female' ? AppColors.primarySubtle : AppColors.surface,
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(
                            color: _gender == 'female' ? AppColors.primary : AppColors.border,
                            width: _gender == 'female' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.girl, color: _gender == 'female' ? AppColors.primary : AppColors.textMuted),
                            const SizedBox(width: 8),
                            Text('Perempuan', style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _gender == 'female' ? AppColors.primary : AppColors.textSecondary,
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
                decoration: const InputDecoration(
                  labelText: 'Tanggal Lahir',
                  hintText: 'YYYY-MM-DD',
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),

              // Parent selector
              if (_parents.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  initialValue: _selectedParentId,
                  decoration: const InputDecoration(labelText: 'Orang Tua *'),
                  items: _parents.map<DropdownMenuItem<int>>((p) {
                    final user = p['user'];
                    // Backend requires parents.id, NOT users.id
                    return DropdownMenuItem(
                      value: p['id'] is int ? p['id'] as int : int.tryParse(p['id'].toString()),
                      child: Text(user?['name'] ?? 'Orang Tua'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedParentId = v),
                  validator: (v) => v == null ? 'Pilih orang tua' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Package selector
              const SizedBox(height: 8),
              const Text('Paket (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
              const SizedBox(height: 8),
              if (_isLoadingPackages)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Memuat paket...', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                )
              else if (_packageError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
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
                        child: const Text('Coba Lagi', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                )
              else if (_packages.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text('Belum ada paket aktif. Tambahkan paket terlebih dahulu.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedPackageId,
                  decoration: const InputDecoration(labelText: 'Pilih Paket'),
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
                          Text('$pkgPrice · $pkgDuration hari', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  alignLabelWithHint: true,
                ),
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
                      : Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Anak',
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
