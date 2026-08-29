import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';

class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({super.key});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  final ApiService _api = ApiService();
  List<dynamic> _admins = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.getAdmins();
      setState(() {
        _admins = response['data']?['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data admin. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleActive(dynamic admin) async {
    final isActive = admin['user']?['status'] == 'active';
    try {
      if (isActive) {
        await _api.deactivateAdmin(admin['id']);
        _showToast('${admin['user']?['name']} berhasil dinonaktifkan.');
      } else {
        await _api.activateAdmin(admin['id']);
        _showToast('${admin['user']?['name']} berhasil diaktifkan.');
      }
      _loadAdmins();
    } catch (e) {
      _showToast('Gagal mengubah status. Silakan coba lagi.', isError: true);
    }
  }

  Future<void> _showCreateForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _CreateAdminPage()),
    );
    if (result == true) _loadAdmins();
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdminMaster) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kelola Admin')),
        body: AppWidgets.emptyState(
          icon: Icons.shield_outlined,
          title: 'Akses Ditolak',
          subtitle: 'Hanya admin_master yang dapat mengelola admin.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateForm,
          ),
        ],
      ),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _loadAdmins)
              : _admins.isEmpty
                  ? AppWidgets.emptyState(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Belum ada admin',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAdmins,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _admins.length,
                        itemBuilder: (context, index) => _buildAdminCard(_admins[index]),
                      ),
                    ),
    );
  }

  Widget _buildAdminCard(dynamic admin) {
    final user = admin['user'];
    final isActive = user?['status'] == 'active';
    final role = user?['role']?['name'] ?? 'admin';
    final auth = context.read<AuthProvider>();
    final isSelf = user?['id'] == auth.user?['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: ThemeHelper.border(context)),
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
                    Text(user?['name'] ?? '-', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: ThemeHelper.text(context))),
                    const SizedBox(height: 2),
                    Text(user?['email'] ?? '-', style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                  ],
                ),
              ),
              AppWidgets.statusBadge(
                isActive ? 'Aktif' : 'Nonaktif',
                isActive ? AppColors.success : ThemeHelper.textMuted(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              AppWidgets.statusBadge(
                role == 'admin_master' ? 'Admin Master' : 'Admin',
                role == 'admin_master' ? AppColors.primary : AppColors.info,
              ),
              const Spacer(),
              if (!isSelf)
                OutlinedButton(
                  onPressed: () => _toggleActive(admin),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isActive ? AppColors.error : AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    side: BorderSide(color: isActive ? AppColors.error : AppColors.primary),
                  ),
                  child: Text(isActive ? 'Nonaktifkan' : 'Aktifkan', style: const TextStyle(fontSize: 12)),
                ),
              if (isSelf)
                Text('Akun Anda', style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context))),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== Create Admin Page ====================
class _CreateAdminPage extends StatefulWidget {
  const _CreateAdminPage();

  @override
  State<_CreateAdminPage> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends State<_CreateAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();
  String _adminRole = 'admin';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final api = ApiService();
      final response = await api.createAdmin(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        position: _positionController.text.trim(),
        adminRole: _adminRole,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Admin berhasil ditambahkan.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Gagal menambahkan admin.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal menambahkan admin. Silakan coba lagi.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeHelper.errorBg(context),
                    borderRadius: AppRadius.smAll,
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nama *'),
                validator: (v) => v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email *'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                  if (!v.contains('@')) return 'Email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    tooltip: _obscurePassword ? 'Password tersembunyi' : 'Password terlihat',
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                  if (v.length < 8) return 'Password minimal 8 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password *',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    tooltip: _obscureConfirm ? 'Password tersembunyi' : 'Password terlihat',
                  ),
                ),
                validator: (v) {
                  if (v != _passwordController.text) return 'Password tidak cocok';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _positionController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Posisi'),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _adminRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'admin_master', child: Text('Admin Master')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _adminRole = v);
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleCreate,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
