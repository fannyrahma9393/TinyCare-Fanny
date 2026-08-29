import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class VouchersPage extends StatefulWidget {
  const VouchersPage({super.key});

  @override
  State<VouchersPage> createState() => _VouchersPageState();
}

class _VouchersPageState extends State<VouchersPage> {
  final ApiService _api = ApiService();
  List<dynamic> _vouchers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final vouchers = await _api.getVouchers();
      setState(() { _vouchers = vouchers; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat data voucher.'; _isLoading = false; });
    }
  }

  Future<void> _showCreateForm() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const _VoucherFormPage()));
    if (result == true) _loadVouchers();
  }

  Future<void> _showEditForm(dynamic voucher) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => _VoucherFormPage(voucher: voucher)));
    if (result == true) _loadVouchers();
  }

  Future<void> _deleteVoucher(dynamic voucher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Voucher'),
        content: Text('Yakin ingin menghapus voucher "${voucher['code']}"?'),
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
      await _api.deleteVoucher(voucher['id']);
      _showToast('Voucher berhasil dihapus.');
      _loadVouchers();
    } catch (e) {
      _showToast('Gagal menghapus voucher.', isError: true);
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
        title: const Text('Voucher'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showCreateForm),
        ],
      ),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _loadVouchers)
              : _vouchers.isEmpty
                  ? AppWidgets.emptyState(
                      icon: Icons.card_giftcard_outlined,
                      title: 'Belum ada voucher',
                      subtitle: 'Ketuk tombol + untuk menambahkan voucher.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVouchers,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _vouchers.length,
                        itemBuilder: (context, index) => _buildVoucherCard(_vouchers[index]),
                      ),
                    ),
    );
  }

  Widget _buildVoucherCard(dynamic voucher) {
    final isActive = voucher['is_active'] ?? true;
    final usageCount = voucher['usage_count'] ?? 0;
    final maxUses = voucher['max_uses'];

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
                    Text(
                      voucher['code'] ?? '-',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.05),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voucher['type'] == 'percentage'
                          ? '${voucher['value']}% diskon'
                          : 'Rp ${voucher['value'] ?? 0} diskon',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeHelper.text(context)),
                    ),
                  ],
                ),
              ),
              AppWidgets.statusBadge(isActive ? 'Aktif' : 'Nonaktif', isActive ? AppColors.success : ThemeHelper.textMuted(context)),
            ],
          ),
          if (voucher['description'] != null && voucher['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(voucher['description'], style: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary(context), height: 1.5)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people_outline, size: 14, color: ThemeHelper.textMuted(context)),
              const SizedBox(width: 6),
              Text(
                'Digunakan: $usageCount${maxUses != null ? ' / $maxUses' : ''}',
                style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context)),
              ),
              const Spacer(),
              if (voucher['expires_at'] != null) ...[
                Icon(Icons.calendar_today, size: 12, color: ThemeHelper.textMuted(context)),
                const SizedBox(width: 6),
                Text('Berlaku hingga ${voucher['expires_at']}', style: TextStyle(fontSize: 11, color: ThemeHelper.textMuted(context))),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditForm(voucher),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteVoucher(voucher),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Hapus', style: TextStyle(fontSize: 12)),
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

// ==================== Voucher Form Page (Create/Edit) ====================
class _VoucherFormPage extends StatefulWidget {
  final Map<String, dynamic>? voucher;
  const _VoucherFormPage({this.voucher});

  @override
  State<_VoucherFormPage> createState() => _VoucherFormPageState();
}

class _VoucherFormPageState extends State<_VoucherFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _discountValueController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _maxUsageController;
  late final TextEditingController _minTransactionController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late String _discountType;
  bool _isSubmitting = false;
  String? _error;

  bool get _isEditing => widget.voucher != null;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.voucher?['code'] ?? '');
    _discountValueController = TextEditingController(
      text: widget.voucher?['discount_value']?.toString() ?? widget.voucher?['value']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(text: widget.voucher?['description'] ?? '');
    _maxUsageController = TextEditingController(
      text: widget.voucher?['max_usage']?.toString() ?? widget.voucher?['max_uses']?.toString() ?? '',
    );
    _minTransactionController = TextEditingController(
      text: widget.voucher?['min_transaction']?.toString() ?? '',
    );
    _startDateController = TextEditingController(
      text: widget.voucher?['start_date'] ?? '',
    );
    _endDateController = TextEditingController(
      text: widget.voucher?['end_date'] ?? widget.voucher?['expires_at'] ?? '',
    );
    _discountType = widget.voucher?['discount_type'] ?? widget.voucher?['type'] ?? 'percentage';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountValueController.dispose();
    _descriptionController.dispose();
    _maxUsageController.dispose();
    _minTransactionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSubmitting = true; _error = null; });

    try {
      final api = ApiService();
      final maxUsage = int.tryParse(_maxUsageController.text) ?? 1;
      final minTx = _minTransactionController.text.trim().isNotEmpty
          ? double.tryParse(_minTransactionController.text.trim())
          : null;
      final response = _isEditing
          ? await api.updateVoucher(
              widget.voucher!['id'],
              code: _codeController.text.trim(),
              discountType: _discountType,
              discountValue: double.tryParse(_discountValueController.text) ?? 0,
              maxUsage: maxUsage,
              startDate: _startDateController.text.trim().isNotEmpty ? _startDateController.text.trim() : null,
              endDate: _endDateController.text.trim().isNotEmpty ? _endDateController.text.trim() : null,
              description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
              minTransaction: minTx,
            )
          : await api.createVoucher(
              code: _codeController.text.trim(),
              discountType: _discountType,
              discountValue: double.tryParse(_discountValueController.text) ?? 0,
              maxUsage: maxUsage,
              startDate: _startDateController.text.trim(),
              endDate: _endDateController.text.trim(),
              description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
              minTransaction: minTx,
            );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Voucher berhasil diperbarui.' : 'Voucher berhasil ditambahkan.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() { _error = response['message'] ?? 'Gagal menyimpan voucher.'; _isSubmitting = false; });
      }
    } catch (e) {
      setState(() { _error = 'Gagal menyimpan voucher. Silakan coba lagi.'; _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Voucher' : 'Tambah Voucher')),
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
                controller: _codeController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Kode Voucher *'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v == null || v.isEmpty ? 'Kode tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _discountType,
                decoration: const InputDecoration(labelText: 'Tipe Diskon *'),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Persen (%)')),
                  DropdownMenuItem(value: 'nominal', child: Text('Nominal (Rp)')),
                ],
                onChanged: (v) { if (v != null) setState(() => _discountType = v); },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountValueController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Nilai Diskon *',
                  suffixText: _discountType == 'percentage' ? '%' : 'Rp',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nilai tidak boleh kosong';
                  final num = double.tryParse(v);
                  if (num == null || num <= 0) return 'Nilai harus lebih dari 0';
                  if (_discountType == 'percentage' && num > 100) return 'Persen maksimal 100';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxUsageController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Maksimum Penggunaan *'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Maksimum penggunaan tidak boleh kosong';
                  if (int.tryParse(v) == null || int.tryParse(v)! < 1) return 'Minimal 1';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      decoration: const InputDecoration(labelText: 'Tanggal Mulai *', hintText: 'YYYY-MM-DD'),
                      keyboardType: TextInputType.datetime,
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      decoration: const InputDecoration(labelText: 'Tanggal Berakhir *', hintText: 'YYYY-MM-DD'),
                      keyboardType: TextInputType.datetime,
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minTransactionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minimum Transaksi', hintText: 'Opsional'),
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
                      : Text(_isEditing ? 'Perbarui' : 'Simpan', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
