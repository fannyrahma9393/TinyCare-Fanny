import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/api_error.dart';
import '../utils/currency.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final ApiService _api = ApiService();
  List<dynamic> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final invoices = await _api.getInvoices();
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat tagihan. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

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
        return 'Lunas';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'failed':
        return 'Gagal';
      case 'expired':
        return 'Kedaluwarsa';
      case 'cancelled':
        return 'Dibatalkan';
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
            content: Text('Status invoice diperbarui.'),
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
            content: Text(response['message'] ?? 'Gagal memperbarui status.'),
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
          content: const Text('Gagal memperbarui status.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      );
    }
  }

  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan'),
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
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _errorMessage != null
              ? AppWidgets.errorState(
                  message: _errorMessage!,
                  onRetry: _loadInvoices,
                )
              : RefreshIndicator(
                  onRefresh: _loadInvoices,
                  color: AppColors.primary,
                  child: _invoices.isEmpty
                      ? AppWidgets.emptyState(
                          icon: Icons.receipt_long,
                          title: 'Belum ada tagihan',
                          subtitle: 'Tagihan akan muncul ketika ada invoice baru.',
                        )
                      : _buildList(),
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
        onTap: () => _showInvoiceDetail(inv),
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
              AppWidgets.infoRow('Anak', inv['child']?['name'] ?? '-'),
              AppWidgets.infoRow('Paket', inv['package']?['name'] ?? '-'),

              Divider(
                height: 17,
                color: ThemeHelper.border(context),
              ),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: TextStyle(
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
                    label: const Text('Bayar Sekarang'),
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
                        label: const Text('Tandai Lunas', style: TextStyle(fontSize: 12)),
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
                        label: const Text('Batalkan', style: TextStyle(fontSize: 12)),
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
                      'Sudah dibayar',
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
                      'Invoice kedaluwarsa',
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
      MaterialPageRoute(builder: (_) => _InvoiceDetailPage(invoice: inv)),
    );
  }
}

// ==================== Invoice Detail Page ====================
class _InvoiceDetailPage extends StatefulWidget {
  final Map<String, dynamic> invoice;
  const _InvoiceDetailPage({required this.invoice});

  @override
  State<_InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<_InvoiceDetailPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _paymentInfo;
  List<dynamic> _payments = [];
  bool _paying = false;
  String? _detailError;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      final payments = await _api.getPayments(widget.invoice['id']);
      setState(() {
        _payments = payments;
      });
    } catch (e) {
      // Payments loading failed, non-critical
    }
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _paying = true;
      _detailError = null;
    });
    try {
      final result = await _api.initiatePayment(
        widget.invoice['id'].toString(),
      );
      setState(() {
        _paymentInfo = result;
        _paying = false;
      });
    } catch (e) {
      setState(() {
        _detailError = 'Pembayaran belum dapat dimulai. Silakan coba lagi.';
        _paying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final status = inv['status'] ?? 'pending';
    final isPaid = status == 'paid';

    return Scaffold(
      appBar: AppBar(
        title: Text(inv['invoice_number'] ?? 'Detail Invoice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv['invoice_number'] ?? '-',
                        style: AppTypography.h1.copyWith(color: ThemeHelper.text(context)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${inv['child']?['name'] ?? '-'} · ${inv['package']?['name'] ?? '-'}',
                        style: AppTypography.bodySmall.copyWith(color: ThemeHelper.textSecondary(context)),
                      ),
                    ],
                  ),
                ),
                AppWidgets.statusBadge(
                  _statusLabel(status),
                  _statusColor(status),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Invoice Summary Card
            _buildCard(
              title: 'Detail Invoice',
              child: Column(
                children: [
                  AppWidgets.infoRow('Anak', inv['child']?['name'] ?? '-'),
                  AppWidgets.infoRow('Paket', inv['package']?['name'] ?? '-'),
                  AppWidgets.infoRow('Subtotal', CurrencyHelper.formatRupiah(inv['subtotal'])),
                  if (inv['discount'] != null && CurrencyHelper.parseToDouble(inv['discount']) > 0)
                    AppWidgets.infoRow(
                      'Diskon',
                      '- ${CurrencyHelper.formatRupiah(inv['discount'])}',
                    ),
                  Divider(
                    height: 17,
                    color: ThemeHelper.border(context),
                  ),
                  AppWidgets.infoRow('Total', CurrencyHelper.formatRupiah(inv['total']), isTotal: true),
                  const SizedBox(height: 4),
                  AppWidgets.infoRow('Status', _statusLabel(status)),
                  AppWidgets.infoRow('Jatuh Tempo', inv['due_date'] ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Section
            _buildCard(
              title: 'Pembayaran',
              child: isPaid
                  ? _buildPaidState()
                  : _paymentInfo != null
                      ? _buildPaymentInstructions()
                      : _buildPayButton(),
            ),

            // Error
            if (_detailError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ThemeHelper.errorBg(context),
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _detailError!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Payment History
            if (_payments.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCard(
                title: 'Riwayat Pembayaran',
                child: Column(
                  children: _payments.map<Widget>((p) {
                    final pStatus = p['status'] ?? 'pending';
                    final pColor = pStatus == 'verified'
                        ? AppColors.success
                        : pStatus == 'pending'
                            ? AppColors.warning
                            : AppColors.error;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeHelper.bgAlt(context),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CurrencyHelper.formatRupiah(p['amount']),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeHelper.text(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p['payment_method'] ?? 'Bank Transfer'} · ${p['created_at'] ?? '-'}',
                                style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context)),
                              ),
                            ],
                          ),
                          AppWidgets.statusBadge(
                            pStatus == 'verified'
                                ? 'Terverifikasi'
                                : pStatus == 'pending'
                                    ? 'Menunggu'
                                    : 'Ditolak',
                            pColor,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: ThemeHelper.border(context)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildPaidState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeHelper.successBg(context),
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 40, color: AppColors.success),
          const SizedBox(height: 10),
          const Text(
            'Pembayaran Berhasil',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.success,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Invoice ini sudah lunas.',
            style: TextStyle(fontSize: 13, color: ThemeHelper.textMuted(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return Column(
      children: [
        Text(
          'Klik tombol di bawah untuk memulai pembayaran.',
          style: AppTypography.bodySmall.copyWith(color: ThemeHelper.textSecondary(context)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _paying ? null : _initiatePayment,
            icon: _paying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.payment, size: 18),
            label: Text(_paying ? 'Memproses...' : 'Bayar Sekarang'),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInstructions() {
    final info = _paymentInfo!;
    final amount = CurrencyHelper.parseToDouble(info['amount']);
    final totalWithCode = CurrencyHelper.parseToDouble(info['total_with_code']);
    final uniqueDigit = totalWithCode - amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // VA Number Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ThemeHelper.infoBg(context),
            borderRadius: AppRadius.lgAll,
          ),
          child: Column(
            children: [
              const Text(
                'Virtual Account',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                info['va_number'] ?? '-',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  letterSpacing: 0.05,
                  color: ThemeHelper.text(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${info['bank_name'] ?? ''} · ${info['account_name'] ?? ''}',
                style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Transfer Amount
        Text('Transfer sebesar:', style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ThemeHelper.text(context),
        )),
        const SizedBox(height: 6),
        Text(
          CurrencyHelper.formatRupiah(totalWithCode),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        Text(
          '(termasuk digit unik: +${uniqueDigit.toInt()})',
          style: TextStyle(fontSize: 11, color: ThemeHelper.textMuted(context)),
        ),
        const SizedBox(height: 18),

        // Instructions
        if (info['instructions'] != null) ...[
          Text('Cara Pembayaran:', style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ThemeHelper.text(context),
          )),
          const SizedBox(height: 10),
          ..._buildInstructions(info['instructions']),
        ],

        // Expiry
        if (info['expires_at'] != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeHelper.warningBg(context),
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Berlaku hingga: ${info['expires_at']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildInstructions(dynamic instructions) {
    if (instructions is Map) {
      return instructions.entries.map<Widget>((e) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ThemeHelper.bgAlt(context),
            borderRadius: AppRadius.smAll,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.key.toString().toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ThemeHelper.textMuted(context),
                  letterSpacing: 0.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                e.value.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: ThemeHelper.textSecondary(context),
                ),
              ),
            ],
          ),
        );
      }).toList();
    }
    return [const SizedBox.shrink()];
  }

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
        return 'Lunas';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'failed':
        return 'Gagal';
      case 'expired':
        return 'Kedaluwarsa';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
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
      setState(() { _error = 'Gagal memuat data.'; _isLoading = false; });
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
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invoice berhasil dibuat.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() { _error = response['message'] ?? 'Gagal membuat invoice.'; _isSubmitting = false; });
      }
    } catch (e) {
      setState(() { _error = ApiErrorHandler.getMessage(e); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Buat Invoice')),
        body: AppWidgets.loadingIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Invoice')),
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
                decoration: const InputDecoration(labelText: 'Anak *'),
                items: _children.map<DropdownMenuItem<int>>((c) =>
                  DropdownMenuItem(value: c['id'], child: Text(c['name'] ?? '-'))
                ).toList(),
                onChanged: (v) => setState(() => _selectedChildId = v),
                validator: (v) => v == null ? 'Pilih anak' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                initialValue: _selectedPackageId,
                decoration: const InputDecoration(labelText: 'Paket *'),
                items: _packages.map<DropdownMenuItem<int>>((p) =>
                  DropdownMenuItem(value: p['id'], child: Text('${p['name']} - ${CurrencyHelper.formatRupiah(p['price'])}'))
                ).toList(),
                onChanged: (v) => setState(() => _selectedPackageId = v),
                validator: (v) => v == null ? 'Pilih paket' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dueDateController,
                decoration: const InputDecoration(labelText: 'Jatuh Tempo *', hintText: 'YYYY-MM-DD'),
                keyboardType: TextInputType.datetime,
                validator: (v) => v == null || v.isEmpty ? 'Tanggal jatuh tempo tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Catatan', alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Buat Invoice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
