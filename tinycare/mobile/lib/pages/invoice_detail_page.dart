import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/cached_resource.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../widgets/offline_banner.dart';
import '../l10n/app_strings.dart';

/// Parent invoice detail with payment flow (VA instructions, copy amount,
/// upload payment proof) — mirrors web ParentInvoiceDetail.
class InvoiceDetailPage extends StatefulWidget {
  const InvoiceDetailPage({super.key, required this.invoiceId});

  final int invoiceId;

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage>
    with ResourceBinding {
  final ApiService _api = ApiService();
  final ParentDataRepository _repo = ParentDataRepository();

  /// Cache-first invoice + payment history so the last known state stays
  /// readable when the backend is down.
  late final CachedResource<Map<String, dynamic>> _invoiceRes;
  late final CachedResource<List<dynamic>> _paymentsRes;

  Map<String, dynamic>? get _invoice => _invoiceRes.data;
  List<dynamic> get _payments => _paymentsRes.data ?? const [];

  bool _paying = false;
  Map<String, dynamic>? _paymentInfo;
  bool _showProofForm = false;
  XFile? _proofFile;
  String _proofMethod = 'bank_transfer';
  final TextEditingController _proofNotesController = TextEditingController();
  bool _submittingProof = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _invoiceRes = CachedResource<Map<String, dynamic>>(
      onChanged: onResourceChanged,
      isEmptyData: (data) => data.isEmpty,
    );
    _paymentsRes =
        CachedResource<List<dynamic>>(onChanged: onResourceChanged);
    _loadData();
  }

  @override
  void dispose() {
    _proofNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _repo.loadInvoiceDetail(widget.invoiceId, _invoiceRes),
      _repo.loadInvoicePayments(widget.invoiceId, _paymentsRes),
    ]);
  }

  /// Start a payment. A failed attempt never reports success: when the backend
  /// is unreachable the parent is told the request was not sent.
  Future<void> _handleInitiatePayment() async {
    setState(() => _paying = true);
    try {
      final data = await _api.initiatePayment('${widget.invoiceId}');
      if (!mounted) return;
      setState(() => _paymentInfo = data);
    } catch (e) {
      if (!mounted) return;
      _showToast(
        tr(ParentDataRepository.writeFailureMessage(e)),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _pickProof() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _proofFile = picked);
  }

  /// Upload the payment proof. Success is only ever shown after the backend
  /// confirmed the upload; offline the parent gets "data belum dikirim".
  Future<void> _handleSubmitProof() async {
    if (_proofFile == null) {
      _showToast(tr('Pilih bukti pembayaran terlebih dahulu.'), isError: true);
      return;
    }
    setState(() => _submittingProof = true);
    try {
      final response = await _repo.submitPaymentProof(
        invoiceId: widget.invoiceId,
        filePath: _proofFile!.path,
        amount: (_invoice?['total'] ?? 0).toString(),
        paymentMethod: _proofMethod,
      );
      if (!mounted) return;
      if (response['success'] == true) {
        _showToast(tr('Bukti pembayaran berhasil dikirim! Menunggu verifikasi admin.'));
        setState(() => _showProofForm = false);
        _proofFile = null;
        _proofNotesController.clear();
        await _loadData();
      } else {
        _showToast(response['message'] ?? tr('Gagal mengirim bukti pembayaran.'), isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showToast(
        tr(ParentDataRepository.writeFailureMessage(e)),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _submittingProof = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
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
      appBar: AppBar(title: Text(tr('Detail Tagihan'))),
      body: Column(
        children: [
          OfflineBanner(resource: _invoiceRes, onRetry: _loadData),
          Expanded(
            child: _invoiceRes.isLoading
                ? AppWidgets.loadingIndicator()
                : _invoiceRes.error != null
                    ? AppWidgets.errorState(
                        message: tr(_invoiceRes.error!),
                        onRetry: _loadData,
                      )
                    : _invoice == null
                        ? AppWidgets.emptyState(icon: Icons.receipt_long, title: tr('Invoice tidak ditemukan.'))
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppColors.primary,
                            child: ListView(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              children: _buildBody(),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody() {
    final invoice = _invoice!;
    final status = invoice['status'] ?? 'pending';
    final isPaid = status == 'paid';
    final hasPendingPayment = _payments.any((p) => p['status'] == 'pending');
    final pendingNoProof = _payments.any(
      (p) => p['status'] == 'pending' && (p['proof_file'] == null || p['proof_file'].toString().isEmpty),
    );

    final statusLabel = status == 'paid'
        ? tr('Lunas')
        : status == 'pending'
            ? tr('Menunggu Pembayaran')
            : status == 'failed'
                ? tr('Gagal')
                : status == 'expired'
                    ? tr('Kedaluwarsa')
                    : status.toUpperCase();
    final statusColor = isPaid
        ? AppColors.success
        : status == 'pending'
            ? AppColors.warning
            : AppColors.error;

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice['invoice_number'] ?? '-',
                    style: AppTypography.h1.copyWith(color: ThemeHelper.text(context))),
                const SizedBox(height: 4),
                Text('${invoice['child']?['name'] ?? '-'} · ${invoice['package']?['name'] ?? '-'}',
                    style: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary(context))),
              ],
            ),
          ),
          AppWidgets.statusBadge(statusLabel, statusColor),
        ],
      ),
      const SizedBox(height: 20),

      // Invoice Details
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeHelper.surface(context),
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: ThemeHelper.border(context)),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            AppWidgets.infoRow(tr('Anak'), invoice['child']?['name'] ?? '-'),
            AppWidgets.infoRow(tr('Paket'), invoice['package']?['name'] ?? '-'),
            AppWidgets.infoRow(tr('Subtotal'), CurrencyHelper.formatRupiah(invoice['subtotal'])),
            if (CurrencyHelper.parseToDouble(invoice['discount']) > 0)
              AppWidgets.infoRow(tr('Diskon'), '- ${CurrencyHelper.formatRupiah(invoice['discount'])}'),
            AppWidgets.infoRow(tr('Total'), CurrencyHelper.formatRupiah(invoice['total']), isTotal: true),
            Divider(height: 24, color: ThemeHelper.border(context)),
            AppWidgets.infoRow(tr('Jatuh Tempo'), invoice['due_date'] ?? '-'),
            if (invoice['notes'] != null) AppWidgets.infoRow(tr('Catatan'), invoice['notes']),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Payment Section
      Container(
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
            Text(tr('Pembayaran'),
                style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
            const SizedBox(height: 14),
            if (isPaid)
              _buildPaidSection()
            else if (_paymentInfo != null)
              _buildPaymentInfoSection(status: status)
            else
              _buildPayButton(hasPendingPayment: hasPendingPayment, pendingNoProof: pendingNoProof),
            if (_showProofForm) ...[
              const SizedBox(height: 16),
              _buildProofForm(),
            ],
          ],
        ),
      ),

      // Payment history
      if (_payments.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ThemeHelper.surface(context),
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: ThemeHelper.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('Riwayat Pembayaran & Bukti'),
                  style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
              const SizedBox(height: 12),
              ..._payments.map<Widget>((p) => _buildPaymentHistoryTile(p)),
            ],
          ),
        ),
      ],
    ];
  }

  Widget _buildPaidSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeHelper.successBg(context),
            borderRadius: AppRadius.lgAll,
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 32),
              const SizedBox(height: 8),
              Text(tr('Pembayaran Berhasil'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
              const SizedBox(height: 4),
              Text(tr('Invoice ini sudah lunas.'),
                  style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._payments.where((p) => p['status'] == 'verified').map<Widget>((p) {
          final paidAt = p['paid_at'] ?? p['verified_at'] ?? '-';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeHelper.bgAlt(context),
              borderRadius: AppRadius.mdAll,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Dibayar pada: {{paidAt}}', {'paidAt': paidAt}),
                    style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context))),
                const SizedBox(height: 2),
                Text(tr('Metode: {{method}}', {
                  'method': p['payment_method'] ?? tr('Bank Transfer'),
                }),
                    style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context))),
              ],
            ),
);
          }),
      ],
    );
  }

  Widget _buildPaymentInfoSection({String? status}) {
    final info = _paymentInfo!;
    final totalWithCode = CurrencyHelper.parseToDouble(info['total_with_code'] ?? info['amount']);
    final baseAmount = CurrencyHelper.parseToDouble(info['amount']);
    final instructions = info['instructions'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeHelper.infoBg(context),
            borderRadius: AppRadius.lgAll,
          ),
          child: Column(
            children: [
              Text(tr('Virtual Account'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.info)),
              const SizedBox(height: 6),
              Text('${info['va_number'] ?? '-'}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2, fontFamily: 'monospace')),
              Text('${info['bank_name'] ?? '-'} · ${info['account_name'] ?? '-'}',
                  style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(tr('Transfer sebesar:'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
        const SizedBox(height: 6),
        Row(
          children: [
            Flexible(
              child: Text(CurrencyHelper.formatRupiah(totalWithCode),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _copyToClipboard(totalWithCode.toStringAsFixed(0)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(_copied ? '✓' : tr('Salin'), style: const TextStyle(fontSize: 11)),
            ),
          ],
        ),
        if ((totalWithCode - baseAmount) > 0)
          Text(
              tr('Termasuk digit unik: +{{code}}', {
                'code': (totalWithCode - baseAmount).toStringAsFixed(0),
              }),
              style: TextStyle(fontSize: 11, color: ThemeHelper.textMuted(context))),
        const SizedBox(height: 14),
        if (instructions is Map && instructions.isNotEmpty) ...[
          Text(tr('Cara Pembayaran:'),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
          const SizedBox(height: 8),
          ...instructions.entries.map<Widget>((e) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ThemeHelper.bgAlt(context),
              borderRadius: AppRadius.mdAll,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.key.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ThemeHelper.textMuted(context))),
                const SizedBox(height: 2),
                Text(e.value.toString(),
                    style: TextStyle(fontSize: 12, color: ThemeHelper.textSecondary(context))),
              ],
            ),
          )),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () => setState(() => _showProofForm = !_showProofForm),
            child: Text(_showProofForm ? tr('Tutup') : tr('Kirim Bukti Pembayaran'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton({required bool hasPendingPayment, required bool pendingNoProof}) {
    final showProofToggle = pendingNoProof;
    return Column(
      children: [
        Text(
          pendingNoProof
              ? tr('Pembayaran sudah dibuat namun belum ada bukti. Silakan kirim bukti pembayaran di bawah.')
              : hasPendingPayment
                  ? tr('Pembayaran sedang menunggu verifikasi admin.')
                  : tr('Klik tombol di bawah untuk memulai pembayaran.'),
          style: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary(context)),
          textAlign: TextAlign.center,
        ),
        if (showProofToggle) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => setState(() => _showProofForm = !_showProofForm),
              child: Text(_showProofForm ? tr('Tutup') : tr('Kirim Bukti Pembayaran'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ] else if (!hasPendingPayment) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _paying ? null : _handleInitiatePayment,
              child: _paying
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(tr('Bayar Sekarang'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProofForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.bgAlt(context),
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Upload Bukti Pembayaran'),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
          const SizedBox(height: 12),
          Text(tr('Metode Pembayaran'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ThemeHelper.textSecondary(context))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _proofMethod,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: ThemeHelper.surface(context),
              border: OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: ThemeHelper.border(context))),
            ),
            items: [
              DropdownMenuItem(value: 'bank_transfer', child: Text(tr('Bank Transfer'))),
              DropdownMenuItem(value: 'ewallet', child: Text(tr('E-Wallet'))),
              DropdownMenuItem(value: 'cash', child: Text(tr('Tunai'))),
            ],
            onChanged: (v) => setState(() => _proofMethod = v ?? 'bank_transfer'),
          ),
          const SizedBox(height: 12),
          Text(tr('Bukti Pembayaran *'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ThemeHelper.textSecondary(context))),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickProof,
            borderRadius: AppRadius.mdAll,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ThemeHelper.surface(context),
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: ThemeHelper.border(context)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _proofFile?.name ?? tr('Pilih gambar bukti transfer'),
                      style: TextStyle(fontSize: 13, color: _proofFile != null ? ThemeHelper.text(context) : ThemeHelper.textMuted(context)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _proofNotesController,
            decoration: InputDecoration(
              labelText: tr('Catatan (opsional)'),
              hintText: tr('Contoh: Transfer via BCA mobile'),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _submittingProof ? null : _handleSubmitProof,
              child: _submittingProof
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(tr('Kirim Bukti'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryTile(dynamic p) {
    final pStatus = p['status'] ?? '';
    final statusLabel = pStatus == 'verified'
        ? tr('Lunas')
        : pStatus == 'pending'
            ? tr('Menunggu Verifikasi')
            : tr('Ditolak');
    final statusColor = pStatus == 'verified'
        ? AppColors.success
        : pStatus == 'pending'
            ? AppColors.warning
            : AppColors.error;
    final createdAt = p['created_at'] ?? '-';
    final notes = p['notes']?.toString();
    final proofFile = p['proof_file']?.toString() ?? '';
    final proofUrl = p['proof_url']?.toString();
    final hasProof = proofFile.isNotEmpty && proofUrl != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeHelper.bgAlt(context),
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(CurrencyHelper.formatRupiah(p['amount']),
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: ThemeHelper.text(context))),
                    const SizedBox(height: 2),
                    Text(
                        '${p['payment_method'] != null ? tr(p['payment_method'].toString()) : tr('Bank Transfer')} · ${_shortDate(createdAt)}',
                        style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context))),
                    if (notes != null) ...[
                      const SizedBox(height: 2),
                      Text(tr('Catatan: {{notes}}', {'notes': notes}),
                          style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context))),
                    ],
                  ],
                ),
              ),
              AppWidgets.statusBadge(statusLabel, statusColor),
            ],
          ),
          if (hasProof) ...[
            const SizedBox(height: 10),
            Text(tr('BUKTI PEMBAYARAN'),
                style: AppTypography.label.copyWith(color: ThemeHelper.textMuted(context))),
            const SizedBox(height: 6),
            if (_isImageFile(proofFile))
              GestureDetector(
                onTap: () => _showProofImage(proofUrl),
                child: ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: Image.network(
                    proofUrl,
                    width: 132,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      width: 132,
                      height: 96,
                      color: ThemeHelper.surface(context),
                      alignment: Alignment.center,
                      child: Text(tr('Gagal dimuat'),
                          style: TextStyle(fontSize: 11, color: ThemeHelper.textMuted(context))),
                    ),
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _openUrl(proofUrl),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.info,
                  side: BorderSide(color: AppColors.info.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: Text(tr('Lihat Bukti (PDF)'), style: const TextStyle(fontSize: 12)),
              ),
          ],
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
      _showToast(tr('Tidak dapat membuka dokumen.'), isError: true);
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

  String _shortDate(dynamic value) {
    if (value == null) return '-';
    final s = value.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}