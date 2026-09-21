import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../l10n/app_strings.dart';
import '../widgets/language_switcher.dart';

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
        setState(() { _error = response['message'] ?? tr('Gagal memuat dashboard admin'); _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = tr('Tidak dapat memuat dashboard admin.'); _isLoading = false; });
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
        const LanguageSwitcher(),
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
      case 0: return tr('Dashboard');
      case 1: return tr('Manajemen Data');
      case 2: return tr('Keuangan');
      case 3: return tr('Menu');
      default: return tr('Admin Dashboard');
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
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: tr('Beranda')),
            BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), activeIcon: Icon(Icons.folder), label: tr('Data')),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: tr('Keuangan')),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: tr('Menu')),
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
    // Mirrors the web admin Dashboard stat cards.
    final totalChildren = CurrencyHelper.parseToInt(stats['total_children']);
    final totalParents = CurrencyHelper.parseToInt(stats['total_parents']);
    final pendingParents = CurrencyHelper.parseToInt(stats['pending_parents']);
    final totalChildInformation = CurrencyHelper.parseToInt(stats['total_child_information']);
    final pendingInvoices = CurrencyHelper.parseToInt(stats['pending_invoices']);
    final paidInvoices = CurrencyHelper.parseToInt(stats['paid_invoices']);
    final totalRevenue = CurrencyHelper.parseToDouble(stats['total_revenue']);

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
                    tr('Halo, Admin {{name}} 👋',
                        {'name': auth.user?['name']?.split(' ').first ?? ''}),
                    style: AppTypography.h1.copyWith(color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('Kelola TinyCare dengan mudah.'),
                    style: TextStyle(fontSize: 14, color: ThemeHelper.textSecondary(context), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Summary Row
            Row(
              children: [
                _buildQuickStat(context, tr('Anak'), '$totalChildren', AppColors.primary, Icons.child_care, '/children'),
                const SizedBox(width: 10),
                _buildQuickStat(context, tr('Orang Tua'), '$totalParents', AppColors.info, Icons.people, '/users'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildQuickStat(context, tr('Pengguna Menunggu'), '$pendingParents', AppColors.warning, Icons.pending_actions, '/users'),
                const SizedBox(width: 10),
                _buildQuickStat(context, tr('Informasi Anak'), '$totalChildInformation', AppColors.info, Icons.fact_check_outlined, '/information'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildQuickStat(context, tr('Invoice Pending'), '$pendingInvoices', AppColors.warning, Icons.receipt_long, '/invoices'),
                const SizedBox(width: 10),
                _buildQuickStat(context, tr('Lunas'), '$paidInvoices', AppColors.success, Icons.check_circle, '/payments'),
              ],
            ),
            if (totalRevenue > 0) ...[
              const SizedBox(height: 10),
              _buildRevenueCard(CurrencyHelper.formatRupiah(totalRevenue)),
            ],
            const SizedBox(height: 28),

            // Quick Actions (Compact)
            Text(tr('Akses Cepat'), style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
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
              Text(tr('Total Pendapatan'), style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
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
      _QuickAction(tr('Pengguna'), Icons.people_outline, '/users'),
      _QuickAction(tr('Anak'), Icons.child_care_outlined, '/children'),
      _QuickAction(tr('Invoice'), Icons.receipt_long_outlined, '/invoices'),
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
          AppWidgets.sectionHeader(tr('Pengguna & Keluarga'), context: context),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': tr('Pengguna'), 'icon': Icons.people_outline, 'route': '/users', 'subtitle': tr('Kelola semua pengguna')},
            {'label': tr('Orang Tua'), 'icon': Icons.family_restroom_outlined, 'route': '/parents', 'subtitle': tr('Data orang tua')},
            {'label': tr('Anak'), 'icon': Icons.child_care_outlined, 'route': '/children', 'subtitle': tr('Data anak terdaftar')},
            {'label': tr('Informasi Anak'), 'icon': Icons.fact_check_outlined, 'route': '/information', 'subtitle': 'Catatan/informasi khusus'},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader(tr('Operasional'), context: context),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': tr('Hari Ini'), 'icon': Icons.auto_stories_outlined, 'route': '/daily-stories', 'subtitle': tr('Cerita harian')},
            {'label': tr('Perkembangan'), 'icon': Icons.trending_up_outlined, 'route': '/development', 'subtitle': tr('Data perkembangan')},
            {'label': tr('Aktivitas'), 'icon': Icons.emoji_events_outlined, 'route': '/activities', 'subtitle': tr('Jadwal aktivitas')},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader(tr('Komunikasi'), context: context),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': tr('Pengumuman'), 'icon': Icons.campaign_outlined, 'route': '/announcements', 'subtitle': tr('Kelola pengumuman')},
            {'label': tr('Feedback'), 'icon': Icons.rate_review_outlined, 'route': '/feedback', 'subtitle': tr('Respons feedback')},
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
          AppWidgets.sectionHeader(tr('Keuangan'), context: context),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': tr('Invoice'), 'icon': Icons.receipt_long_outlined, 'route': '/invoices', 'subtitle': tr('Kelola tagihan')},
            {'label': tr('Pembayaran'), 'icon': Icons.payment_outlined, 'route': '/payments', 'subtitle': tr('Verifikasi pembayaran')},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader(tr('Produk & Promosi'), context: context),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': tr('Paket'), 'icon': Icons.inventory_2_outlined, 'route': '/packages', 'subtitle': tr('Paket langganan')},
            {'label': tr('Voucher'), 'icon': Icons.card_giftcard_outlined, 'route': '/vouchers', 'subtitle': tr('Kode diskon')},
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
            AppWidgets.sectionHeader(tr('Pengaturan Admin'), context: context),
            const SizedBox(height: 12),
            _buildMenuGroup(context, [
              {'label': tr('Kelola Admin'), 'icon': Icons.shield_outlined, 'route': '/admin-management', 'subtitle': 'Aktifkan/nonaktifkan admin'},
            ]),
            const SizedBox(height: 24),
          ],

          AppWidgets.sectionHeader(tr('Aplikasi'), context: context),
          const SizedBox(height: 12),
          _buildMenuGroup(context, [
            {'label': tr('Profil'), 'icon': Icons.person_outline, 'route': '/profile', 'subtitle': tr('Lihat profil admin')},
          ]),
          const SizedBox(height: 24),

          AppWidgets.sectionHeader(tr('Tampilan'), context: context),
          const SizedBox(height: 12),
          const ThemeSwitcher(),
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
                  child: Center(
                    child: Text(tr('TC'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) => Text(tr('TinyCare Admin'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
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
