import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _api.getAdminDashboard();
      if (response['success'] == true) {
        setState(() { _dashboardData = response['data']; _isLoading = false; });
      } else {
        setState(() { _error = response['message'] ?? 'Gagal memuat dashboard admin'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Tidak dapat memuat dashboard admin.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: _buildAppBar(auth),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _loadDashboard)
              : IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _DashboardHomeTab(
                      dashboardData: _dashboardData,
                      onRefresh: _loadDashboard,
                      auth: auth,
                      onNavigateToData: () => setState(() => _selectedIndex = 1),
                    ),
                    const _DataManagementTab(),
                    const _FinanceTab(),
                    _MenuTab(auth: auth),
                  ],
                ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(AuthProvider auth) {
    return AppBar(
      title: Text(_getAppBarTitle()),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Keluar'),
                content: const Text('Apakah Anda yakin ingin keluar?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              auth.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
      ],
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Manajemen Data';
      case 2: return 'Keuangan';
      case 3: return 'Menu';
      default: return 'Admin Dashboard';
    }
  }

  Widget _buildBottomNav() {
    final surfaceColor = ThemeHelper.surface(context);
    final borderColor = ThemeHelper.border(context);
    final mutedColor = ThemeHelper.textMuted(context);
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: mutedColor,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), activeIcon: Icon(Icons.folder), label: 'Data'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Keuangan'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'Menu'),
          ],
        ),
      ),
    );
  }
}

// ==================== DASHBOARD HOME TAB ====================
class _DashboardHomeTab extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;
  final Future<void> Function() onRefresh;
  final AuthProvider auth;
  final VoidCallback onNavigateToData;

  const _DashboardHomeTab({
    required this.dashboardData,
    required this.onRefresh,
    required this.auth,
    required this.onNavigateToData,
  });

  @override
  Widget build(BuildContext context) {
    final stats = dashboardData?['statistics'] as Map<String, dynamic>? ?? {};
    // Safely parse all stats — backend may return String, int, double, or null
    final totalChildren = CurrencyHelper.parseToInt(stats['total_children']);
    final totalParents = CurrencyHelper.parseToInt(stats['total_parents']);
    final pendingInvoices = CurrencyHelper.parseToInt(stats['pending_invoices']);
    final paidInvoices = CurrencyHelper.parseToInt(stats['paid_invoices']);
    final totalRevenue = CurrencyHelper.parseToDouble(stats['total_revenue']);
    final todayAttendance = CurrencyHelper.parseToInt(stats['today_attendance']);
    final todayPresent = CurrencyHelper.parseToInt(stats['today_present']);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Greeting
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primarySubtle, AppColors.primaryLighter],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.xlAll,
                border: Border.all(color: AppColors.primaryLighter),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, Admin ${auth.user?['name']?.split(' ').first ?? ''} 👋',
                    style: AppTypography.h1.copyWith(color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola TinyCare dengan mudah.',
                    style: TextStyle(fontSize: 14, color: ThemeHelper.textSecondary(context), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Summary Row
            Row(
              children: [
                _buildQuickStat(context, 'Anak', '$totalChildren', AppColors.primary, Icons.child_care, '/children'),
                const SizedBox(width: 10),
                _buildQuickStat(context, 'Orang Tua', '$totalParents', AppColors.info, Icons.people, '/users'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildQuickStat(context, 'Invoice Pending', '$pendingInvoices', AppColors.warning, Icons.receipt_long, '/invoices'),
                const SizedBox(width: 10),
                _buildQuickStat(context, 'Lunas', '$paidInvoices', AppColors.success, Icons.check_circle, '/payments'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildQuickStat(context, 'Hadir Hari Ini', '$todayPresent', AppColors.info, Icons.check_circle_outline, '/attendance'),
                const SizedBox(width: 10),
                _buildQuickStat(context, 'Total Absensi', '$todayAttendance', ThemeHelper.textSecondary(context), Icons.calendar_today, '/attendance'),
              ],
            ),
            if (totalRevenue > 0) ...[
              const SizedBox(height: 10),
              _buildRevenueCard(CurrencyHelper.formatRupiah(totalRevenue)),
            ],
            const SizedBox(height: 28),

            // Quick Actions (Compact)
            Text('Akses Cepat', style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
            const SizedBox(height: 14),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value, Color color, IconData icon, String route) {
    final surfaceColor = ThemeHelper.surface(context);
    final borderColor = ThemeHelper.border(context);
    final labelColor = ThemeHelper.textMuted(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(label.toUpperCase(), style: AppTypography.label.copyWith(color: labelColor)),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color, height: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard(String amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.success, Color(0xFF2D5E47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppRadius.smAll),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Pendapatan', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction('Pengguna', Icons.people_outline, '/users'),
      _QuickAction('Anak', Icons.child_care_outlined, '/children'),
      _QuickAction('Invoice', Icons.receipt_long_outlined, '/invoices'),
      _QuickAction('Laporan', Icons.assessment_outlined, '/reports'),
    ];
    final surfaceColor = ThemeHelper.surface(context);
    final borderColor = ThemeHelper.border(context);
    final labelColor = ThemeHelper.textSecondary(context);

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, action.route),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Icon(action.icon, color: AppColors.primary, size: 24),
                  const SizedBox(height: 8),
                  Text(action.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: labelColor)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  _QuickAction(this.label, this.icon, this.route);
}

// ==================== DATA MANAGEMENT TAB ====================
class _DataManagementTab extends StatelessWidget {
  const _DataManagementTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWidgets.sectionHeader('Pengguna & Keluarga', context: context),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': 'Pengguna', 'icon': Icons.people_outline, 'route': '/users', 'subtitle': 'Kelola semua pengguna'},
            {'label': 'Orang Tua', 'icon': Icons.family_restroom_outlined, 'route': '/parents', 'subtitle': 'Data orang tua'},
            {'label': 'Anak', 'icon': Icons.child_care_outlined, 'route': '/children', 'subtitle': 'Data anak terdaftar'},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader('Operasional', context: context),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': 'Absensi', 'icon': Icons.calendar_today_outlined, 'route': '/attendance', 'subtitle': 'Kelola kehadiran'},
            {'label': 'Hari Ini', 'icon': Icons.auto_stories_outlined, 'route': '/daily-stories', 'subtitle': 'Cerita harian'},
            {'label': 'Perkembangan', 'icon': Icons.trending_up_outlined, 'route': '/development', 'subtitle': 'Data perkembangan'},
            {'label': 'Aktivitas', 'icon': Icons.emoji_events_outlined, 'route': '/activities', 'subtitle': 'Jadwal aktivitas'},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader('Komunikasi', context: context),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': 'Pengumuman', 'icon': Icons.campaign_outlined, 'route': '/announcements', 'subtitle': 'Kelola pengumuman'},
            {'label': 'Acara', 'icon': Icons.event_outlined, 'route': '/events', 'subtitle': 'Jadwal kegiatan'},
            {'label': 'Feedback', 'icon': Icons.rate_review_outlined, 'route': '/feedback', 'subtitle': 'Respons feedback'},
          ]),
        ],
      ),
    );
  }
}

// ==================== FINANCE TAB ====================
class _FinanceTab extends StatelessWidget {
  const _FinanceTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWidgets.sectionHeader('Keuangan', context: context),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': 'Invoice', 'icon': Icons.receipt_long_outlined, 'route': '/invoices', 'subtitle': 'Kelola tagihan'},
            {'label': 'Pembayaran', 'icon': Icons.payment_outlined, 'route': '/payments', 'subtitle': 'Verifikasi pembayaran'},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader('Produk & Promosi', context: context),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': 'Paket', 'icon': Icons.inventory_2_outlined, 'route': '/packages', 'subtitle': 'Paket langganan'},
            {'label': 'Voucher', 'icon': Icons.card_giftcard_outlined, 'route': '/vouchers', 'subtitle': 'Kode diskon'},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader('Laporan', context: context),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': 'Laporan', 'icon': Icons.assessment_outlined, 'route': '/reports', 'subtitle': 'Laporan mingguan & bulanan'},
          ]),
        ],
      ),
    );
  }
}

// ==================== MENU TAB ====================
class _MenuTab extends StatelessWidget {
  final AuthProvider auth;
  const _MenuTab({required this.auth});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (auth.isAdminMaster) ...[
            AppWidgets.sectionHeader('Pengaturan Admin', context: context),
            const SizedBox(height: 12),
            _buildMenuGroup(context, [
              {'label': 'Kelola Admin', 'icon': Icons.shield_outlined, 'route': '/admin-management', 'subtitle': 'Aktifkan/nonaktifkan admin'},
            ]),
            const SizedBox(height: 24),
          ],

          AppWidgets.sectionHeader('Aplikasi', context: context),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': 'Profil', 'icon': Icons.person_outline, 'route': '/profile', 'subtitle': 'Lihat profil admin'},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader('Tampilan', context: context),
          const SizedBox(height: 12),
          _ThemeSwitcher(),
          const SizedBox(height: 32),

          Center(
            child: Column(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: const Center(
                    child: Text('TC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) => Text('TinyCare Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) => Text('v1.0.0', style: TextStyle(fontSize: 12, color: ThemeHelper.textMuted(context))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== THEME SWITCHER ====================
class _ThemeSwitcher extends StatelessWidget {
  const _ThemeSwitcher();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = ThemeHelper.surface(context);
    final borderColor = ThemeHelper.border(context);
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: borderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mode Tampilan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'Mode Gelap' : 'Mode Terang',
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              themeProvider.setThemeMode(
                isDark ? ThemeModeOption.light : ThemeModeOption.dark,
              );
            },
            child: Container(
              width: 52, height: 28,
              decoration: BoxDecoration(
                color: isDark ? AppColors.primary : ThemeHelper.border(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22, height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SHARED WIDGETS ====================

/// Local helper that wraps AppWidgets.menuGroup with route navigation
Widget _buildMenuGroup(BuildContext context, List<Map<String, dynamic>> items) {
  final surfaceColor = ThemeHelper.surface(context);
  final borderColor = ThemeHelper.border(context);
  final borderLightColor = ThemeHelper.borderLight(context);
  return Container(
    decoration: BoxDecoration(
      color: surfaceColor,
      borderRadius: AppRadius.lgAll,
      border: Border.all(color: borderColor),
      boxShadow: AppColors.cardShadow,
    ),
    child: Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isLast = index == items.length - 1;
        final route = item['route'] as String;
        return Column(
          children: [
            AppWidgets.menuItem(
              label: item['label'] as String,
              icon: item['icon'] as IconData,
              onTap: () => Navigator.pushNamed(context, route),
              subtitle: item['subtitle'] as String?,
              context: context,
            ),
            if (!isLast)
              Divider(height: 1, indent: 72, endIndent: 18, color: borderLightColor),
          ],
        );
      }),
    ),
  );
}
