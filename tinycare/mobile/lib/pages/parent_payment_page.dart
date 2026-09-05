import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';

/// Parent payment submission page.
/// Mirrors web parent payment flow: select invoice, choose method, submit
/// proof (upload) or initiate payment, then show submission status.
class ParentPaymentPage extends StatefulWidget {
  final int invoiceId;
  final String invoiceNumber;
  final int amount;

  const ParentPaymentPage({
    super.key,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.amount,
  });

  @override
  State<ParentPaymentPage> createState() => _ParentPaymentPageState();
}

class _ParentPaymentPageState extends State<ParentPaymentPage> {
  final ApiService _api = ApiService();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;
  String? _success;
  String? _fileLocalPath;
  String _selectedMethod = 'bank_transfer';

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.amount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _fileLocalPath = image.path;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
      _success = null;
    });

    try {
      String? filePath;
      if (_fileLocalPath != null && Platform.isAndroid) {
        filePath = _fileLocalPath;
      }

      final response = await _api.submitPayment(
        widget.invoiceId,
        filePath ?? '',
        amount: _amountController.text.trim().isNotEmpty
            ? _amountController.text.trim()
            : null,
        paymentMethod: _selectedMethod.isNotEmpty ? _selectedMethod : null,
      );

      if (!mounted) return;
      if (response['success'] == true) {
        setState(() {
          _success = response['message'] ??
              'Pembayaran berhasil dikirim. Menunggu verifikasi admin.';
          _isSubmitting = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Gagal mengirim pembayaran.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal mengirim pembayaran. Silakan coba lagi.';
        _isSubmitting = false;
      });
    }
  }

  Widget _methodChip(String value, String label) {
    final selected = _selectedMethod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedMethod = value),
        selectedColor: AppColors.primary,
        backgroundColor: ThemeHelper.surface(context),
        side: BorderSide(color: ThemeHelper.border(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeHelper.bgAlt(context),
                borderRadius: AppRadius.lgAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice ${widget.invoiceNumber}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jumlah pembayaran',
                        style: TextStyle(fontSize: 13, color: mutedColor),
                      ),
                      Text(
                        CurrencyHelper.formatRupiah(widget.amount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metode pembayaran
            Text(
              'Metode Pembayaran',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _methodChip('bank_transfer', 'Transfer Bank'),
                _methodChip('cash', 'Tunai'),
                _methodChip('other', 'Lainnya'),
              ],
            ),
            const SizedBox(height: 24),

            // Nominal (opsional untuk beberapa metode)
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal Pembayaran',
                hintText: 'Isi jika perlu',
              ),
            ),
            const SizedBox(height: 16),

            // Bukti pembayaran
            Text(
              'Bukti Pembayaran (Opsional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickProofImage,
              borderRadius: AppRadius.mdAll,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ThemeHelper.bgAlt(context),
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: ThemeHelper.border(context)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.upload_file, size: 32, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(
                      _fileLocalPath != null
                          ? 'Foto terpilih'
                          : 'Pilih foto bukti transfer',
                      style: TextStyle(fontSize: 13, color: mutedColor),
                    ),
                    if (_fileLocalPath != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() => _fileLocalPath = null);
                          },
                          child: const Text('Hapus'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Catatan
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                hintText: 'Opsional',
              ),
            ),
            const SizedBox(height: 28),

            // Error / success
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeHelper.errorBg(context),
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ]
            else if (_success != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeHelper.successBg(context),
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _success!,
                        style: const TextStyle(color: AppColors.success, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Kirim Pembayaran',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


