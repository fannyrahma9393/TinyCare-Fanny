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
      backgroundColor: AppColors.bg,
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
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
                  const Text(
                    'Kelola TinyCare dengan mudah.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
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
                _buildQuickStat(context, 'Total Absensi', '$todayAttendance', AppColors.textSecondary, Icons.calendar_today, '/attendance'),
              ],
            ),
            if (totalRevenue > 0) ...[
              const SizedBox(height: 10),
              _buildRevenueCard(CurrencyHelper.formatRupiah(totalRevenue)),
            ],
            const SizedBox(height: 28),

            // Quick Actions (Compact)
            const Text('Akses Cepat', style: AppTypography.h3),
            const SizedBox(height: 14),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value, Color color, IconData icon, String route) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(label.toUpperCase(), style: AppTypography.label),
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

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, action.route),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(action.icon, color: AppColors.primary, size: 24),
                  const SizedBox(height: 8),
                  Text(action.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
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
          AppWidgets.sectionHeader('Pengguna & Keluarga'),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': 'Pengguna', 'icon': Icons.people_outline, 'route': '/users', 'subtitle': 'Kelola semua pengguna'},
            {'label': 'Orang Tua', 'icon': Icons.family_restroom_outlined, 'route': '/parents', 'subtitle': 'Data orang tua'},
            {'label': 'Anak', 'icon': Icons.child_care_outlined, 'route': '/children', 'subtitle': 'Data anak terdaftar'},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader('Operasional'),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': 'Absensi', 'icon': Icons.calendar_today_outlined, 'route': '/attendance', 'subtitle': 'Kelola kehadiran'},
            {'label': 'Hari Ini', 'icon': Icons.auto_stories_outlined, 'route': '/daily-stories', 'subtitle': 'Cerita harian'},
            {'label': 'Perkembangan', 'icon': Icons.trending_up_outlined, 'route': '/development', 'subtitle': 'Data perkembangan'},
            {'label': 'Aktivitas', 'icon': Icons.emoji_events_outlined, 'route': '/activities', 'subtitle': 'Jadwal aktivitas'},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader('Komunikasi'),
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
          AppWidgets.sectionHeader('Keuangan'),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': 'Invoice', 'icon': Icons.receipt_long_outlined, 'route': '/invoices', 'subtitle': 'Kelola tagihan'},
            {'label': 'Pembayaran', 'icon': Icons.payment_outlined, 'route': '/payments', 'subtitle': 'Verifikasi pembayaran'},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader('Produk & Promosi'),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': 'Paket', 'icon': Icons.inventory_2_outlined, 'route': '/packages', 'subtitle': 'Paket langganan'},
            {'label': 'Voucher', 'icon': Icons.card_giftcard_outlined, 'route': '/vouchers', 'subtitle': 'Kode diskon'},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader('Laporan'),
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
            AppWidgets.sectionHeader('Pengaturan Admin'),
            const SizedBox(height: 12),
            _buildMenuGroup(context, [
              {'label': 'Kelola Admin', 'icon': Icons.shield_outlined, 'route': '/admin-management', 'subtitle': 'Aktifkan/nonaktifkan admin'},
            ]),
            const SizedBox(height: 24),
          ],

          AppWidgets.sectionHeader('Aplikasi'),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': 'Profil', 'icon': Icons.person_outline, 'route': '/profile', 'subtitle': 'Lihat profil admin'},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader('Tampilan'),
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
                const Text('TinyCare Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(height: 4),
                const Text('v1.0.0', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
    final current = themeProvider.themeMode;

    final options = [
      {'mode': ThemeModeOption.light, 'label': 'Terang', 'icon': Icons.light_mode_outlined},
      {'mode': ThemeModeOption.dark, 'label': 'Gelap', 'icon': Icons.dark_mode_outlined},
      {'mode': ThemeModeOption.system, 'label': 'Sistem', 'icon': Icons.settings_brightness_outlined},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: List.generate(options.length, (index) {
          final opt = options[index];
          final isSelected = current == opt['mode'];
          final isLast = index == options.length - 1;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: (isSelected ? AppColors.primary : AppColors.bgAlt).withValues(alpha: isSelected ? 0.1 : 1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(opt['icon'] as IconData, color: isSelected ? AppColors.primary : AppColors.textMuted, size: 20),
                ),
                title: Text(opt['label'] as String, style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14,
                  color: isSelected ? AppColors.primary : AppColors.text,
                )),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                    : const Icon(Icons.circle_outlined, color: AppColors.border, size: 20),
                onTap: () => themeProvider.setThemeMode(opt['mode'] as ThemeModeOption),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 72, endIndent: 18, color: AppColors.borderLight),
            ],
          );
        }),
      ),
    );
  }
}

// ==================== SHARED WIDGETS ====================

/// Local helper that wraps AppWidgets.menuGroup with route navigation
Widget _buildMenuGroup(BuildContext context, List<Map<String, dynamic>> items) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      border: Border.all(color: AppColors.border),
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
            ),
            if (!isLast)
              const Divider(height: 1, indent: 72, endIndent: 18, color: AppColors.borderLight),
          ],
        );
      }),
    ),
  );
}
