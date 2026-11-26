import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/cached_resource.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../utils/api_error.dart';
import '../utils/currency.dart';
import '../widgets/offline_banner.dart';
import 'invoice_detail_page.dart';
import '../l10n/app_strings.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> with ResourceBinding {
  final ApiService _api = ApiService();
  final ParentDataRepository _repo = ParentDataRepository();

  /// Cache-first invoices: shows the last payload instantly, then refreshes.
  late final CachedResource<List<dynamic>> _res;
  List<dynamic> get _invoices => _res.data ?? const [];

  @override
  void initState() {
    super.initState();
    _res = CachedResource<List<dynamic>>(onChanged: onResourceChanged);
    _loadInvoices();
  }

  Future<void> _loadInvoices() => _repo.loadInvoices(_res);


  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return ThemeHelper.textMuted(context);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return tr('Lunas');
      case 'pending':
        return tr('Menunggu Pembayaran');
      case 'failed':
        return tr('Gagal');
      case 'expired':
        return tr('Kedaluwarsa');
      case 'cancelled':
        return tr('Dibatalkan');
      default:
        return status;
    }
  }

  Future<void> _updateInvoiceStatus(int invoiceId, String status) async {
    try {
      final response = await _api.updateInvoiceStatus(invoiceId, status: status);
      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Status invoice diperbarui.')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        );
        _loadInvoices();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? tr('Gagal memperbarui status.')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Gagal memperbarui status.')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Tagihan')),
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const _InvoiceFormPage()));
          if (result == true) _loadInvoices();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ) : null,
      body: Column(
        children: [
          OfflineBanner(resource: _res, onRetry: _loadInvoices),
          Expanded(
            child: _res.isLoading
                ? AppWidgets.loadingIndicator()
                : _res.error != null
                    ? AppWidgets.errorState(
                        message: tr(_res.error!),
                        onRetry: _loadInvoices,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInvoices,
                        color: AppColors.primary,
                        child: _invoices.isEmpty
                            ? AppWidgets.emptyState(
                                icon: Icons.receipt_long,
                                title: tr('Belum ada tagihan'),
                                subtitle: tr('Tagihan akan muncul ketika ada invoice baru.'),
                              )
                            : _buildList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _invoices.length,
      itemBuilder: (context, index) => _buildInvoiceCard(_invoices[index], isAdmin),
    );
  }

  Widget _buildInvoiceCard(dynamic inv, [bool isAdmin = false]) {
    final status = inv['status'] ?? 'pending';
    final color = _statusColor(status);
    final isPaid = status == 'paid';
    final isPending = status == 'pending';
    final isExpired = status == 'expired';
    final dueDate = inv['due_date'] != null
        ? DateTime.tryParse(inv['due_date'])
        : null;
    final isOverdue = isPending && dueDate != null && dueDate.isBefore(DateTime.now());

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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InvoiceDetailPage(invoiceId: inv['id'])),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      inv['invoice_number'] ?? '-',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: ThemeHelper.text(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppWidgets.statusBadge(_statusLabel(status), color),
                ],
              ),
              const SizedBox(height: 12),

              // Info rows
              AppWidgets.infoRow(tr('Anak'), inv['child']?['name'] ?? '-'),
              AppWidgets.infoRow(tr('Paket'), inv['package']?['name'] ?? '-'),

              Divider(
                height: 17,
                color: ThemeHelper.border(context),
              ),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr('Total'), style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: ThemeHelper.text(context),
                  )),
                  Text(
                    CurrencyHelper.formatRupiah(inv['total']),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              // Due date
              if (dueDate != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Jatuh tempo: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? AppColors.error : ThemeHelper.textMuted(context),
                    fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],

              // Pay button for pending (parent only)
              if (isPending && !isAdmin) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showInvoiceDetail(inv),
                    icon: const Icon(Icons.payment, size: 18),
                    label: Text(tr('Bayar Sekarang')),
                  ),
                ),
              ],

              // Admin: Status update
              if (isPending && isAdmin) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateInvoiceStatus(inv['id'], 'paid'),
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: Text(tr('Tandai Lunas'), style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateInvoiceStatus(inv['id'], 'cancelled'),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: Text(tr('Batalkan'), style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Paid badge
              if (isPaid) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      tr('Sudah dibayar'),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],

              // Expired badge
              if (isExpired) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: AppColors.error),
                    const SizedBox(width: 6),
                    Text(
                      tr('Invoice kedaluwarsa'),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
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

  void _showInvoiceDetail(dynamic inv) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoiceDetailPage(invoiceId: inv['id'])),
    );
  }
}

// ==================== Invoice Form (Create) ====================
class _InvoiceFormPage extends StatefulWidget {
  const _InvoiceFormPage();

  @override
  State<_InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends State<_InvoiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedChildId;
  int? _selectedPackageId;
  final _dueDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _voucherCodeController = TextEditingController();
  List<dynamic> _children = [];
  List<dynamic> _packages = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _dueDateController.text = ApiService.today();
    _loadData();
  }

  @override
  void dispose() {
    _dueDateController.dispose();
    _notesController.dispose();
    _voucherCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final children = await _api.getChildren();
      final packages = await _api.getPackages();
      setState(() {
        _children = children;
        _packages = packages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = tr('Gagal memuat data.'); _isLoading = false; });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });

    try {
      final response = await _api.createInvoice(
        childId: _selectedChildId!,
        packageId: _selectedPackageId!,
        dueDate: _dueDateController.text.trim(),
        voucherCode: _voucherCodeController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('Invoice berhasil dibuat.')),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() { _error = response['message'] ?? tr('Gagal membuat invoice.'); _isSubmitting = false; });
      }
    } catch (e) {
      setState(() { _error = ApiErrorHandler.getMessage(e); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('Buat Invoice'))),
        body: AppWidgets.loadingIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr('Buat Invoice'))),
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

              DropdownButtonFormField<int>(
                initialValue: _selectedChildId,
                decoration: InputDecoration(labelText: tr('Anak *')),
                items: _children.map<DropdownMenuItem<int>>((c) =>
                  DropdownMenuItem(value: c['id'], child: Text(c['name'] ?? '-'))
                ).toList(),
                onChanged: (v) => setState(() => _selectedChildId = v),
                validator: (v) => v == null ? tr('Pilih anak') : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                initialValue: _selectedPackageId,
                decoration: InputDecoration(labelText: tr('Paket *')),
                items: _packages.map<DropdownMenuItem<int>>((p) =>
                  DropdownMenuItem(value: p['id'], child: Text('${p['name']} - ${CurrencyHelper.formatRupiah(p['price'])}'))
                ).toList(),
                onChanged: (v) => setState(() => _selectedPackageId = v),
                validator: (v) => v == null ? tr('Pilih paket') : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dueDateController,
                decoration: InputDecoration(labelText: tr('Jatuh Tempo *'), hintText: tr('YYYY-MM-DD')),
                keyboardType: TextInputType.datetime,
                validator: (v) => v == null || v.isEmpty ? tr('Tanggal jatuh tempo tidak boleh kosong') : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _voucherCodeController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: tr('Kode Voucher'),
                  hintText: tr('Opsional'),
                ),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(labelText: tr('Catatan'), alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(tr('Buat Invoice'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
