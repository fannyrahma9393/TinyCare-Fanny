import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../l10n/app_strings.dart';

class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  final ApiService _api = ApiService();
  List<dynamic> _packages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final packages = await _api.getPackages();
      setState(() { _packages = packages; _isLoading = false; });
    } catch (e) {
      setState(() { _error = tr('Gagal memuat data paket.'); _isLoading = false; });
    }
  }

  Future<void> _showCreateForm() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const _PackageFormPage()));
    if (result == true) _loadPackages();
  }

  Future<void> _showEditForm(dynamic package) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => _PackageFormPage(package: package)));
    if (result == true) _loadPackages();
  }

  Future<void> _deletePackage(dynamic package) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Hapus Paket')),
        content: Text(tr('Yakin ingin menghapus paket "{{name}}"?',
            {'name': package['name'] ?? ''})),
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
      await _api.deletePackage(package['id']);
      _showToast(tr('Paket berhasil dihapus.'));
      _loadPackages();
    } catch (e) {
      _showToast(tr('Gagal menghapus paket.'), isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Paket')),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showCreateForm),
        ],
      ),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _loadPackages)
              : _packages.isEmpty
                  ? AppWidgets.emptyState(
                      icon: Icons.inventory_2_outlined,
                      title: tr('Belum ada paket'),
                      subtitle: tr('Ketuk tombol + untuk menambahkan paket.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPackages,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _packages.length,
                        itemBuilder: (context, index) => _buildPackageCard(_packages[index]),
                      ),
                    ),
    );
  }

  Widget _buildPackageCard(dynamic package) {
    // Backend uses 'status' field ('active'/'inactive'), not 'is_active'
    final isActive = (package['status'] ?? 'active') == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(package['name'] ?? '-', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
                    const SizedBox(height: 4),
                    Text(CurrencyHelper.formatRupiah(package['price']), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
              ),
              AppWidgets.statusBadge(isActive ? tr('Aktif') : tr('Nonaktif'), isActive ? AppColors.success : ThemeHelper.textMuted(context)),
            ],
          ),
          if (package['description'] != null && package['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(package['description'], style: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary(context), height: 1.5)),
          ],
          if (package['duration_days'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: ThemeHelper.textMuted(context)),
                const SizedBox(width: 6),
                Text('${package['duration_days']} hari', style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context))),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditForm(package),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(tr('Edit'), style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deletePackage(package),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(tr('Hapus'), style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== Package Form Page (Create/Edit) ====================
class _PackageFormPage extends StatefulWidget {
  final Map<String, dynamic>? package;
  const _PackageFormPage({this.package});

  @override
  State<_PackageFormPage> createState() => _PackageFormPageState();
}

class _PackageFormPageState extends State<_PackageFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationDaysController;
  late final TextEditingController _facilitiesController;
  late final TextEditingController _quotaController;
  bool _isSubmitting = false;
  String? _error;

  bool get _isEditing => widget.package != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.package?['name'] ?? '');
    _priceController = TextEditingController(
      text: widget.package?['price'] != null ? CurrencyHelper.parseToDouble(widget.package!['price']).toStringAsFixed(0) : '',
    );
    _descriptionController = TextEditingController(text: widget.package?['description'] ?? '');
    _durationDaysController = TextEditingController(
      text: widget.package?['duration_days']?.toString() ?? '',
    );
    _facilitiesController = TextEditingController(text: widget.package?['facilities'] ?? '');
    _quotaController = TextEditingController(
      text: widget.package?['quota']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _durationDaysController.dispose();
    _facilitiesController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSubmitting = true; _error = null; });

    try {
      final api = ApiService();
      final durationDays = int.tryParse(_durationDaysController.text.trim()) ?? 30;
      final quota = _quotaController.text.trim().isNotEmpty ? int.tryParse(_quotaController.text.trim()) : null;

      final response = _isEditing
          ? await api.updatePackage(
              widget.package!['id'],
              name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
              price: double.tryParse(_priceController.text),
              durationDays: durationDays,
              description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
              facilities: _facilitiesController.text.trim().isNotEmpty ? _facilitiesController.text.trim() : null,
              quota: quota,
            )
          : await api.createPackage(
              name: _nameController.text.trim(),
              price: double.tryParse(_priceController.text) ?? 0,
              durationDays: durationDays,
              description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
              facilities: _facilitiesController.text.trim().isNotEmpty ? _facilitiesController.text.trim() : null,
              quota: quota,
            );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? tr('Paket berhasil diperbarui.') : tr('Paket berhasil ditambahkan.')),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() { _error = response['message'] ?? tr('Gagal menyimpan paket.'); _isSubmitting = false; });
      }
    } catch (e) {
      setState(() { _error = tr('Gagal menyimpan paket. Silakan coba lagi.'); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? tr('Edit Paket') : tr('Tambah Paket'))),
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
                decoration: InputDecoration(labelText: tr('Nama Paket *')),
                validator: (v) => v == null || v.isEmpty ? tr('Nama tidak boleh kosong') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Harga (Rp) *')),
                validator: (v) {
                  if (v == null || v.isEmpty) return tr('Harga tidak boleh kosong');
                  if (double.tryParse(v) == null) return tr('Harga harus berupa angka');
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationDaysController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Durasi (hari) *'), hintText: tr('contoh: 30')),
                validator: (v) {
                  if (v == null || v.isEmpty) return tr('Durasi tidak boleh kosong');
                  if (int.tryParse(v) == null || int.tryParse(v)! < 1) return tr('Durasi minimal 1 hari');
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _facilitiesController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Fasilitas')),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quotaController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Kuota'), hintText: tr('Kosongkan jika tidak terbatas')),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: tr('Deskripsi'), alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isEditing ? tr('Perbarui') : tr('Simpan'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
