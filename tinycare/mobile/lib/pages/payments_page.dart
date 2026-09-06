import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';

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
  String _filter = '';

  static const _filters = [
    ('', 'Semua'),
    ('pending', 'Menunggu'),
    ('verified', 'Terverifikasi'),
    ('rejected', 'Ditolak'),
  ];

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
      final payments = await _api.getAdminPayments(
        status: _filter.isEmpty ? null : _filter,
      );
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

  void _setFilter(String value) {
    if (_filter == value) return;
    _filter = value;
    _loadPayments();
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

  Future<void> _viewDetail(dynamic payment) async {
    String? proofUrl;
    final hasProof = payment['proof_file'] != null &&
        payment['proof_file'].toString().isNotEmpty;
    if (hasProof) {
      try {
        final res = await _api.showPaymentProof(payment['id']);
        final data = res['data'];
        if (data is Map) proofUrl = data['url']?.toString();
      } catch (_) {}
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeHelper.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildDetailSheet(payment, proofUrl, hasProof),
    );
  }

  Widget _buildDetailSheet(dynamic payment, String? proofUrl, bool hasProof) {
    final status = payment['status'] ?? 'pending';
    final created = payment['created_at']?.toString() ?? '-';
    final notes = payment['notes']?.toString();
    final proofFile = payment['proof_file']?.toString() ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Detail Pembayaran',
                    style: AppTypography.h2.copyWith(color: ThemeHelper.text(context))),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Tutup',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child:
                      _detailTile('No. Invoice', payment['invoice']?['invoice_number']?.toString() ?? '-'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: _detailTile('Anak', payment['invoice']?['child']?['name']?.toString() ?? '-')),
                const SizedBox(width: 8),
                Expanded(child: _detailTile('Orang Tua', payment['invoice']?['parent']?['user']?['name']?.toString() ?? '-')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _detailTile('Metode', (payment['payment_method'] ?? '-').toString())),
                const SizedBox(width: 8),
                Expanded(child: _detailTile('Jumlah', CurrencyHelper.formatRupiah(payment['amount']))),
              ],
            ),
            Row(
              children: [
                Expanded(child: _detailTile('Tanggal', created)),
                const SizedBox(width: 8),
                Expanded(child: _detailTile('Status', _statusLabel(status))),
              ],
            ),
            if (notes != null) ...[
              const SizedBox(height: 8),
              _detailTile('Catatan', notes),
            ],
            if (status == 'rejected' && notes != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeHelper.errorBg(context),
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ALASAN PENOLAKAN',
                        style: AppTypography.label.copyWith(color: AppColors.error)),
                    const SizedBox(height: 4),
                    Text(notes, style: const TextStyle(fontSize: 13, color: AppColors.error)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (hasProof && proofUrl != null) ...[
              Text('BUKTI PEMBAYARAN',
                  style: AppTypography.label.copyWith(color: ThemeHelper.textMuted(context))),
              const SizedBox(height: 8),
              if (_isImageFile(proofFile))
                GestureDetector(
                  onTap: () => _showProofImage(proofUrl),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.lgAll,
                      border: Border.all(color: ThemeHelper.border(context)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      proofUrl,
                      height: 240,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 240,
                          alignment: Alignment.center,
                          color: ThemeHelper.bgAlt(context),
                          child: const CircularProgressIndicator(color: AppColors.primary),
                        );
                      },
                      errorBuilder: (context, error, stack) => Container(
                        height: 240,
                        alignment: Alignment.center,
                        color: ThemeHelper.bgAlt(context),
                        child: Text('Gagal memuat bukti',
                            style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                      ),
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _openUrl(proofUrl),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Buka Bukti (PDF)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
            ] else if (hasProof) ...[
              Text('Bukti sedang dimuat...',
                  style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(String label, String value) {
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
          Text(label.toUpperCase(),
              style: AppTypography.label.copyWith(color: ThemeHelper.textMuted(context))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeHelper.text(context)),
              overflow: TextOverflow.visible),
        ],
      ),
    );
  }

  bool _isImageFile(String file) {
    return RegExp(r'\.(jpg|jpeg|png|webp|gif)$', caseSensitive: false).hasMatch(file);
  }

  Future<void> _openUrl(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppWidgets.showSnackBar(context, 'Tidak dapat membuka dokumen.', isError: true);
    }
  }

  void _showProofImage(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              maxScale: 5,
              child: Image.network(url),
            ),
          ),
        ),
      ),
    );
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
        return ThemeHelper.textMuted(context);
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'verified':
        return 'Terverifikasi';
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
      appBar: AppBar(
        title: const Text('Pembayaran'),
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _isLoading
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, 4),
      child: Row(
        children: _filters.map((f) {
          final selected = _filter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _setFilter(f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : ThemeHelper.surface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : ThemeHelper.border(context),
                  ),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : ThemeHelper.textSecondary(context),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
                      payment['invoice']?['parent']?['user']?['name'] ?? payment['user']?['name'] ?? '-',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ThemeHelper.text(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invoice: ${payment['invoice']?['invoice_number'] ?? '-'} · ${payment['invoice']?['child']?['name'] ?? ''}',
                      style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context)),
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
                CurrencyHelper.formatRupiah(payment['amount']),
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
                Icon(Icons.calendar_today, size: 12, color: ThemeHelper.textMuted(context)),
                const SizedBox(width: 6),
                Text(payment['created_at'], style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context))),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _viewDetail(payment),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.info,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: Text('Detail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 4),
            Divider(color: ThemeHelper.border(context)),
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