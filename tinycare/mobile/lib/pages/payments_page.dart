import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final ApiService _api = ApiService();
  List<dynamic> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final payments = await _api.getAdminPayments();
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data pembayaran. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyPayment(int paymentId) async {
    try {
      final response = await _api.verifyPayment(paymentId);
      if (response['success'] == true) {
        _showToast('Pembayaran berhasil diverifikasi.');
        _loadPayments();
      } else {
        _showToast(response['message'] ?? 'Gagal memverifikasi.', isError: true);
      }
    } catch (e) {
      _showToast('Gagal memverifikasi pembayaran. Silakan coba lagi.', isError: true);
    }
  }

  Future<void> _rejectPayment(int paymentId) async {
    final reason = await _showRejectDialog();
    if (reason == null) return;

    try {
      final response = await _api.rejectPayment(paymentId, reason: reason);
      if (response['success'] == true) {
        _showToast('Pembayaran ditolak.');
        _loadPayments();
      } else {
        _showToast(response['message'] ?? 'Gagal menolak pembayaran.', isError: true);
      }
    } catch (e) {
      _showToast('Gagal menolak pembayaran. Silakan coba lagi.', isError: true);
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

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Apakah Anda yakin ingin menolak pembayaran ini?'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Alasan penolakan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'verified':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'verified':
        return 'Diverifikasi';
      case 'pending':
        return 'Menunggu';
      case 'rejected':
        return 'Ditolak';
      default:
        return status ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Pembayaran'),
      ),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(
                  message: _error!,
                  onRetry: _loadPayments,
                )
              : _payments.isEmpty
                  ? AppWidgets.emptyState(
                      icon: Icons.payment_outlined,
                      title: 'Belum ada pembayaran',
                      subtitle: 'Pembayaran akan muncul ketika ada transaksi.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPayments,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          return _buildPaymentCard(_payments[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
    final status = payment['status'] ?? 'pending';
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
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
                    // Backend nests: payment.invoice.parent.user.name
                    Text(
                      payment['invoice']?['parent']?['user']?['name'] ?? payment['user']?['name'] ?? '-',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invoice: ${payment['invoice']?['invoice_number'] ?? '-'} · ${payment['invoice']?['child']?['name'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              AppWidgets.statusBadge(_statusLabel(status), _statusColor(status)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Rp ${payment['amount'] ?? 0}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (payment['payment_method'] != null) ...[
                AppWidgets.statusBadge(payment['payment_method'], AppColors.info),
              ],
            ],
          ),
          if (payment['created_at'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(payment['created_at'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyPayment(payment['id']),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Verifikasi', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectPayment(payment['id']),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Tolak', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
