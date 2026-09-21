import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _addressController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final api = ApiService();
      final response = await api.registerParent(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (response['success'] == true) {
        setState(() {
          _isSuccess = true;
          _isSubmitting = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? tr('Registrasi gagal. Silakan coba lagi.');
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = tr('Tidak dapat terhubung ke server. Silakan coba lagi.');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: ThemeHelper.successBg(context),
                    borderRadius: AppRadius.xlAll,
                  ),
                  child: const Icon(Icons.check_circle, size: 36, color: AppColors.success),
                ),
                const SizedBox(height: 24),
                Text(tr('Registrasi Berhasil!'), style: AppTypography.h1.copyWith(color: ThemeHelper.text(context))),
                const SizedBox(height: 10),
                Text(
                  tr('Akun Anda telah dibuat dan menunggu persetujuan admin. Anda akan dapat login setelah akun disetujui.'),
                  style: AppTypography.bodySmall.copyWith(color: ThemeHelper.textSecondary(context)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(tr('Kembali ke Login')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr('Daftar Akun Orang Tua'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(tr('Buat akun untuk memantau si kecil'), style: AppTypography.bodySmall.copyWith(color: ThemeHelper.textSecondary(context))),
              const SizedBox(height: 24),

              // Error
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

              // Name
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Nama Lengkap *')),
                validator: (v) => v == null || v.isEmpty ? tr('Nama tidak boleh kosong') : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Email *')),
                validator: (v) {
                  if (v == null || v.isEmpty) return tr('Email tidak boleh kosong');
                  final emailRegex = RegExp(r'^[\w-\.]+@[\w-]+\.[a-zA-Z]{2,}$');
                  if (!emailRegex.hasMatch(v)) return tr('Email tidak valid');
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: tr('Nomor HP')),
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: tr('Password *'),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    tooltip: _obscurePassword ? tr('Password tersembunyi') : tr('Password terlihat'),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return tr('Password tidak boleh kosong');
                  if (v.length < 8) return tr('Password minimal 8 karakter');
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: tr('Konfirmasi Password *'),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    tooltip: _obscureConfirm ? tr('Password tersembunyi') : tr('Password terlihat'),
                  ),
                ),
                validator: (v) {
                  if (v != _passwordController.text) return tr('Password tidak cocok');
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: tr('Alamat (opsional)')),
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleRegister,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(tr('Daftar'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tr('Sudah punya akun? '), style: TextStyle(fontSize: 13, color: ThemeHelper.textMuted(context))),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(tr('Masuk'), style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
