import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../utils/currency.dart';
import '../widgets/child_photo.dart';

/// Parent invoice detail page — mirrors web's ParentInvoiceDetail.
///
/// Shows invoice header, line items / breakdown, voucher info, payment
/// status, and buttons to view payments or initiate/submit payment.
class ParentInvoiceDetailPage extends StatefulWidget {
  final int invoiceId;

  const ParentInvoiceDetailPage({super.key, required this.invoiceId});

  @override
  State<ParentInvoiceDetailPage> createState() => _ParentInvoiceDetailPageState();
}

class _ParentInvoiceDetailPageState extends State<ParentInvoiceDetailPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _invoice;
  List<dynamic> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final invoice = await _api.getInvoice(widget.invoiceId);
      final payments = await _api.getPayments(widget.invoiceId);
      setState(() {
        _invoice = invoice;
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat detail invoice.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);
    final surfaceColor = ThemeHelper.surface(context);
    final bgAlt = ThemeHelper.bgAlt(context);
    final borderColor = ThemeHelper.border(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _load)
              : _invoice == null
                  ? AppWidgets.emptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Invoice tidak ditemukan',
                      subtitle: 'Invoice ini tidak tersedia.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header card
                            Container(
                              width: double.infinity,
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
                                      Text(
                                        _invoice!['invoice_number'] ?? 'INV-####',
                                        style: AppTypography.h3
                                            .copyWith(color: AppColors.primary),
                                      ),
                                      AppWidgets.statusBadge(
                                        (_invoice!['status'] ?? 'pending').toUpperCase(),
                                        _statusColor(_invoice!['status']),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow('Tanggal Terbit',
                                      (_invoice!['created_at'] ?? '-')),
                                  _buildInfoRow('Tanggal Jatuh Tempo',
                                      _invoice!['due_date'] ?? '-'),
                                  if (_invoice!['paid_at'] != null)
                                    _buildInfoRow('Tanggal Bayar',
                                        _invoice!['paid_at']),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Jumlah',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: mutedColor,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        CurrencyHelper.formatRupiah(_invoice!['total'] ?? 0),
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  if ((_invoice!['voucher_discount'] ?? 0) > 0) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Diskon Voucher',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: mutedColor,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          '- ${CurrencyHelper.formatRupiah(_invoice!['voucher_discount'] ?? 0)}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.success),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Child info
                            Text(
                              'Anak',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: bgAlt,
                                borderRadius: AppRadius.mdAll,
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  ChildPhoto(
                                    child: _invoice!['child'] ?? {},
                                    width: 48,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _invoice!['child']?['name'] ?? '-',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: textColor),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Paket: ${_invoice!['package']?['name'] ?? '-'}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: mutedColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Payment history
                            Text(
                              'Riwayat Pembayaran',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor),
                            ),
                            const SizedBox(height: 10),
                            if (_payments.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: bgAlt,
                                  borderRadius: AppRadius.mdAll,
                                  border: Border.all(color: borderColor),
                                ),
                                child: AppWidgets.emptyState(
                                  icon: Icons.payment_outlined,
                                  title: 'Belum ada pembayaran',
                                  subtitle: 'Belum ada pembayaran untuk invoice ini.',
                                ),
                              )
                            else
                              ...(_payments as List).map((payment) =>
                                  _buildPaymentCard(payment)),

                            const SizedBox(height: 24),

                            // Actions
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.arrow_back, size: 16),
                                    label: const Text('Kembali'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if ((_invoice!['status'] ?? 'pending') == 'pending')
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // Navigate to invoice detail page which has payment flow
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.payment, size: 18),
                                      label: const Text('Bayar Sekarang'),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: mutedColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);
    final surfaceColor = ThemeHelper.surface(context);
    final borderColor = ThemeHelper.border(context);

    final amount = payment['amount'] ?? 0;
    final status = (payment['status'] ?? 'pending').toLowerCase();
    final isSuccess = status == 'success' || status == 'paid' || status == 'verified';
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: borderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isSuccess
                        ? Icons.check_circle_outlined
                        : isPending
                            ? Icons.hourglass_empty
                            : Icons.cancel_outlined,
                    size: 18,
                    color: isSuccess
                        ? AppColors.success
                        : isPending
                            ? AppColors.primary
                            : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    payment['payment_method']?.toString().replaceAll('_', ' ') ??
                        'Pembayaran',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor),
                  ),
                ],
              ),
              AppWidgets.statusBadge(
                (payment['status'] ?? 'pending').toString().toUpperCase(),
                isSuccess
                    ? AppColors.success
                    : isPending
                        ? AppColors.primary
                        : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Nominal',
              CurrencyHelper.formatRupiah(amount)),
          if (payment['paid_at'] != null)
            _buildInfoRow('Waktu',
                '${payment['paid_at']}'),
          if (payment['notes'] != null &&
              payment['notes'].toString().isNotEmpty)
            _buildInfoRow('Catatan', payment['notes']),
          if (payment['proof_url'] != null)
            Row(
              children: [
                const Icon(Icons.photo, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Bukti tersedia',
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    final s = (status ?? 'pending').toLowerCase();
    if (s == 'paid') return AppColors.success;
    if (s == 'pending') return AppColors.primary;
    if (s == 'failed' || s == 'rejected') return AppColors.error;
    if (s == 'cancelled' || s == 'expired') return AppColors.textMuted;
    return AppColors.primary;
  }
}
