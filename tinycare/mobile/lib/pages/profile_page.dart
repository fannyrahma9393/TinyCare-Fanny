import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/cached_resource.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/offline_banner.dart';
import '../l10n/app_strings.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with ResourceBinding {
  final ParentDataRepository _repo = ParentDataRepository();

  /// Cache-first profile. The API response shape is {success,data,...};
  /// we store that whole envelope in cache so last-known profile remains
  /// available offline. Loading reads the envelope's data for display.
  late final CachedResource<Map<String, dynamic>> _res;
  Map<String, dynamic>? get _profileEnvelope => _res.data;
  Map<String, dynamic>? get _profileData =>
      _profileEnvelope != null ? _profileEnvelope!['data'] as Map<String, dynamic>? : null;

  @override
  void initState() {
    super.initState();
    _res = CachedResource<Map<String, dynamic>>(
      onChanged: onResourceChanged,
      isEmptyData: (data) => data.isEmpty || (data['data'] == null),
    );
    _loadProfile();
  }

  Future<void> _loadProfile() => _repo.loadProfile(_res);


  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Profil')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(tr('Keluar')),
                  content: Text(tr('Apakah Anda yakin ingin keluar?')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Batal'))),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: Text(tr('Keluar')),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(resource: _res, onRetry: _loadProfile),
          Expanded(
            child: _res.isLoading
                ? AppWidgets.loadingIndicator()
                : _res.error != null
                    ? AppWidgets.errorState(
                        message: tr(_res.error!),
                        onRetry: _loadProfile,
                      )
                    : _buildProfile(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final auth = context.watch<AuthProvider>();
    final user = _profileData ?? auth.user;

    if (user == null) {
      return AppWidgets.emptyState(
        icon: Icons.person_outline,
        title: tr('Data profil tidak tersedia'),
      );
    }

    final surfaceColor = ThemeHelper.surface(context);
    final borderColor = ThemeHelper.border(context);
    final textColor = ThemeHelper.text(context);
    final textSecColor = ThemeHelper.textSecondary(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Avatar + Name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: AppRadius.xlAll,
              border: Border.all(color: borderColor),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLighter,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (user['name'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user['name'] ?? '-',
                  style: AppTypography.h2.copyWith(color: textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] ?? '-',
                  style: AppTypography.bodySmall.copyWith(color: textSecColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                AppWidgets.statusBadge(
                  user['role'] == 'parent' ? tr('Orang Tua') : user['role'] ?? '-',
                  AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Account Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: borderColor),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Informasi Akun'), style: AppTypography.h3.copyWith(color: textColor)),
                const SizedBox(height: 16),
                AppWidgets.infoRow(tr('Nama'), user['name'] ?? '-'),
                AppWidgets.infoRow(tr('Email'), user['email'] ?? '-'),
                AppWidgets.infoRow(tr('Nomor HP'), user['phone'] ?? '-'),
                AppWidgets.infoRow(tr('Role'), user['role'] == 'parent' ? tr('Orang Tua') : (user['role'] ?? '-')),
                AppWidgets.infoRow(tr('Status'), user['status'] == 'active' ? tr('Aktif') : (user['status'] ?? '-')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Account Actions
          AppWidgets.menuGroup(
            [
              {
                'label': tr('Ubah Password'),
                'icon': Icons.lock_outline,
                'onTap': () => Navigator.pushNamed(context, '/change-password'),
                'subtitle': tr('Ganti kata sandi akun Anda'),
              },
            ],
            context: context,
          ),
          const SizedBox(height: 16),

          // Theme Toggle
          AppWidgets.sectionHeader(tr('Tampilan'), context: context),
          const SizedBox(height: 12),
          const ThemeSwitcher(),
          const SizedBox(height: 16),

          // App Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Tentang Aplikasi'), style: AppTypography.h3.copyWith(color: textColor)),
                const SizedBox(height: 16),
                AppWidgets.infoRow(tr('Aplikasi'), tr('TinyCare')),
                AppWidgets.infoRow(tr('Versi'), '1.0.0'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
