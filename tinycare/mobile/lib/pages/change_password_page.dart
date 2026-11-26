import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';


class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final response = await _api.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
        newPasswordConfirmation: _confirmController.text,
      );

      if (response['success'] == true) {
        if (!mounted) return;
        AppWidgets.showSnackBar(context, response['message'] ?? tr('Password berhasil diubah.'));
        Navigator.pop(context);
      } else {
        setState(() {
          _error = response['message'] ?? tr('Gagal mengubah password.');
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = tr(ParentDataRepository.writeFailureMessage(e));
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Ubah Password'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('Ganti password untuk mengamankan akun Anda.'),
                style: AppTypography.bodySmall.copyWith(color: ThemeHelper.textSecondary(context)),
              ),
              const SizedBox(height: 24),

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
                controller: _currentController,
                obscureText: _obscureCurrent,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: tr('Password Saat Ini *'),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    tooltip: _obscureCurrent ? tr('Password tersembunyi') : tr('Password terlihat'),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? tr('Password saat ini tidak boleh kosong') : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _newController,
                obscureText: _obscureNew,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: tr('Password Baru *'),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    tooltip: _obscureNew ? tr('Password tersembunyi') : tr('Password terlihat'),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return tr('Password baru tidak boleh kosong');
                  if (v.length < 8) return tr('Password minimal 8 karakter');
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSubmit(),
                decoration: InputDecoration(
                  labelText: tr('Konfirmasi Password Baru *'),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    tooltip: _obscureConfirm ? tr('Password tersembunyi') : tr('Password terlihat'),
                  ),
                ),
                validator: (v) {
                  if (v != _newController.text) return tr('Password tidak cocok');
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(tr('Simpan Password'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}