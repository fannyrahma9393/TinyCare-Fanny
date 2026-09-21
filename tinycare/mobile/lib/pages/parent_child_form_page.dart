import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/api_error.dart';
import '../utils/media_compressor.dart';
import '../l10n/app_strings.dart';

/// Parent: register their own child. Mirrors the web parent "Tambah Anak"
/// form. Photo is compressed before upload.
class ParentChildFormPage extends StatefulWidget {
  const ParentChildFormPage({super.key});

  @override
  State<ParentChildFormPage> createState() => _ParentChildFormPageState();
}

class _ParentChildFormPageState extends State<ParentChildFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _addressController = TextEditingController();
  final _healthController = TextEditingController();
  final _emNameController = TextEditingController();
  final _emPhoneController = TextEditingController();

  String _gender = 'male';
  Uint8List? _photoBytes;
  String? _photoName;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _healthController.dispose();
    _emNameController.dispose();
    _emPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
    );
    if (picked == null) return;

    // Compress before storing so the uploaded photo is small.
    Uint8List? compressed;
    try {
      final result = await MediaCompressor.compress(picked);
      if (result != null) {
        compressed = result.bytes;
        _photoName = result.file.name;
      }
    } catch (_) {
      compressed = null;
    }

    if (compressed == null) {
      // Fall back to raw bytes when compression isn't available (e.g. web).
      compressed = await picked.readAsBytes();
      _photoName = picked.name;
    }

    if (!mounted) return;
    setState(() {
      _photoBytes = compressed;
      _photoName ??= picked.name;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final response = await _api.registerOwnChild(
        name: _nameController.text.trim(),
        gender: _gender,
        birthDate: _birthDateController.text.trim(),
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        healthInfo: _healthController.text.trim().isNotEmpty ? _healthController.text.trim() : null,
        emergencyContactName: _emNameController.text.trim().isNotEmpty ? _emNameController.text.trim() : null,
        emergencyContactPhone: _emPhoneController.text.trim().isNotEmpty ? _emPhoneController.text.trim() : null,
        photoBytes: _photoBytes,
        photoName: _photoName,
      );

      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Anak berhasil ditambahkan.')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = response['message'] ?? tr('Gagal menyimpan data anak.');
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = ApiErrorHandler.getMessage(e);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Tambah Anak'))),
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

              // Photo picker (compressed on upload)
              Center(
                child: InkWell(
                  onTap: _pickPhoto,
                  borderRadius: AppRadius.mdAll,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      color: ThemeHelper.bgAlt(context),
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(color: ThemeHelper.border(context)),
                    ),
                    child: _photoBytes != null
                        ? ClipRRect(
                            borderRadius: AppRadius.mdAll,
                            child: Image.memory(
                              _photoBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo, color: AppColors.primary, size: 28),
                              const SizedBox(height: 6),
                              Text(
                                tr('Unggah Foto'),
                                style: TextStyle(fontSize: 12, color: ThemeHelper.textSecondary(context)),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Nama Anak *')),
                validator: (v) => v == null || v.isEmpty ? tr('Nama tidak boleh kosong') : null,
              ),
              const SizedBox(height: 16),

              Text(tr('Jenis Kelamin'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = 'male'),
                      child: _genderBox(Icons.boy, tr('Laki-laki'), _gender == 'male'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = 'female'),
                      child: _genderBox(Icons.girl, tr('Perempuan'), _gender == 'female'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _birthDateController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: tr('Tanggal Lahir *'),
                  hintText: tr('YYYY-MM-DD'),
                ),
                keyboardType: TextInputType.datetime,
                validator: (v) => v == null || v.trim().isEmpty ? tr('Tanggal lahir tidak boleh kosong') : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: tr('Alamat')),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _healthController,
                decoration: const InputDecoration(labelText: 'Informasi Kesehatan / Alergi'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emNameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Nama Kontak Darurat')),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emPhoneController,
                decoration: InputDecoration(labelText: tr('Telepon Kontak Darurat')),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(tr('Simpan Anak')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderBox(IconData icon, String label, bool selected) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySubtle : ThemeHelper.surface(context),
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: selected ? AppColors.primary : ThemeHelper.border(context),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? AppColors.primary : ThemeHelper.textMuted(context)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : ThemeHelper.textSecondary(context),
          )),
        ],
      ),
    );
  }
}
