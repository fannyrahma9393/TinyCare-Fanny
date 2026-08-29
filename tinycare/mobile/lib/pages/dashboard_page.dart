import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          _ChildrenTab(),
          _InvoicesTab(),
          _ActivitiesTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
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
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: mutedColor,
            selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.child_care_outlined),
                activeIcon: Icon(Icons.child_care),
                label: 'Anak',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Tagihan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_stories_outlined),
                activeIcon: Icon(Icons.auto_stories),
                label: 'Aktivitas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
        );
        },
      ),
    );
  }
}

// ==================== HOME TAB ====================
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.getDashboard();
      if (response['success'] == true) {
        setState(() {
          _dashboardData = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Gagal memuat dashboard';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Tidak dapat terhubung ke server. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              final auth = context.read<AuthProvider>();
              auth.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _loadDashboard)
              : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    final auth = context.watch<AuthProvider>();
    final children = _dashboardData?['children'] ?? [];
    final pendingInvoices = _dashboardData?['pending_invoices'] ?? [];
    final announcements = _dashboardData?['announcements'] ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
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
                    'Halo, ${auth.user?['name']?.split(' ').first ?? 'Orang Tua'} 👋',
                    style: AppTypography.h1.copyWith(color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 4),
              Text(
                'Pantau perkembangan si kecil dengan mudah.',
                style: TextStyle(fontSize: 14, color: ThemeHelper.textSecondary(context), height: 1.5),
              ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary Cards
            Row(
              children: [
                _buildSummaryCard('Anak', '${children.length}', AppColors.primary),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  'Tagihan',
                  '${pendingInvoices.length}',
                  pendingInvoices.isNotEmpty ? AppColors.warning : ThemeHelper.textMuted(context),
                ),
                const SizedBox(width: 12),
                _buildSummaryCard('Pengumuman', '${announcements.length}', AppColors.info),
              ],
            ),
            const SizedBox(height: 28),

            // Children Section
            if (children.isNotEmpty) ...[
              Builder(
                builder: (context) => Text('Anak Saya', style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
              ),
              const SizedBox(height: 14),
              ...List.generate(children.length, (i) {
                return _buildChildCard(children[i]);
              }),
              const SizedBox(height: 28),
            ],

            // Quick Actions
            Builder(
              builder: (context) => Text('Menu', style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
            ),
            const SizedBox(height: 14),
            _buildQuickActionsGrid(),
            const SizedBox(height: 28),

            // Pending Invoices
            if (pendingInvoices.isNotEmpty) ...[
              Builder(
                builder: (context) => Text('Invoice Pending', style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
              ),
              const SizedBox(height: 14),
              ...List.generate(pendingInvoices.length, (i) {
                return _buildPendingInvoiceCard(pendingInvoices[i]);
              }),
              const SizedBox(height: 28),
            ],

            // Announcements
            if (announcements.isNotEmpty) ...[
              Builder(
                builder: (context) => Text('Pengumuman', style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
              ),
              const SizedBox(height: 14),
              ...List.generate(
                announcements.length > 3 ? 3 : announcements.length,
                (i) => _buildAnnouncementCard(announcements[i]),
              ),
            ],

            // Empty state
            if (children.isEmpty && pendingInvoices.isEmpty && announcements.isEmpty)
              AppWidgets.emptyState(
                icon: Icons.dashboard_outlined,
                title: 'Belum ada data',
                subtitle: 'Data akan muncul ketika sudah tersedia di sistem.',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Builder(
        builder: (context) {
          final surfaceColor = ThemeHelper.surface(context);
          final borderColor = ThemeHelper.border(context);
          final labelColor = ThemeHelper.textMuted(context);
          return Container(
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
                Text(label.toUpperCase(), style: AppTypography.label.copyWith(color: labelColor)),
                const SizedBox(height: 8),
                Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: valueColor, height: 1)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChildCard(dynamic child) {
    final packages = child['child_packages'] ?? [];
    final activePackage = packages.isNotEmpty ? packages.first['package'] : null;

    return GestureDetector(
      onTap: () {
        final parentState = context.findAncestorStateOfType<_DashboardPageState>();
        parentState?.setState(() => parentState._currentIndex = 1);
      },
      child: Builder(
        builder: (context) {
          final surfaceColor = ThemeHelper.surface(context);
          final borderColor = ThemeHelper.border(context);
          final textColor = ThemeHelper.text(context);
          final mutedColor = ThemeHelper.textMuted(context);
          final successBgColor = ThemeHelper.successBg(context);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: borderColor),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: AppColors.primaryLighter, borderRadius: AppRadius.mdAll),
                      child: Center(
                        child: Text(
                          (child['name'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(child['name'] ?? '-', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 2),
                          Text(child['gender'] == 'male' ? 'Laki-laki' : 'Perempuan', style: TextStyle(fontSize: 12, color: mutedColor)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: mutedColor),
                  ],
                ),
                if (activePackage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: successBgColor, borderRadius: AppRadius.smAll),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activePackage['name'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                        const SizedBox(height: 2),
                        Text(CurrencyHelper.formatRupiah(activePackage['price']), style: TextStyle(fontSize: 12, color: mutedColor)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      _ActionItem('Hari Ini', Icons.auto_stories, '/daily-stories'),
      _ActionItem('Absensi', Icons.calendar_today, '/attendance'),
      _ActionItem('Perkembangan', Icons.trending_up, '/development'),
      _ActionItem('Tagihan', Icons.receipt_long, '/invoices'),
      _ActionItem('Pengumuman', Icons.campaign, '/announcements'),
      _ActionItem('Acara', Icons.event, '/events'),
      _ActionItem('Feedback', Icons.rate_review, '/feedback'),
      _ActionItem('Profil', Icons.person, '/profile'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: action.route != null ? () => Navigator.pushNamed(context, action.route!) : null,
          child: Builder(
            builder: (context) {
              final surfaceColor = ThemeHelper.surface(context);
              final borderColor = ThemeHelper.border(context);
              final labelColor = ThemeHelper.textSecondary(context);
              return Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.icon, color: AppColors.primary, size: 22),
                    const SizedBox(height: 6),
                    Text(action.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: labelColor), textAlign: TextAlign.center),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPendingInvoiceCard(dynamic inv) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/invoices'),
      child: Builder(
        builder: (context) {
          final warningBgColor = ThemeHelper.warningBg(context);
          final mutedColor = ThemeHelper.textMuted(context);
          final textColor = ThemeHelper.text(context);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: warningBgColor,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.15)),
            ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: AppRadius.smAll),
              child: const Icon(Icons.receipt, color: AppColors.warning, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv['invoice_number'] ?? '-', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 2),
                  Text('${inv['child']?['name'] ?? ''} · Jatuh tempo: ${inv['due_date'] ?? '-'}', style: TextStyle(fontSize: 12, color: mutedColor)),
                ],
              ),
            ),
            Text(CurrencyHelper.formatRupiah(inv['total']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.warning)),
          ],
        ),
        );
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(dynamic ann) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/announcements'),
      child: Builder(
        builder: (context) {
          final surfaceColor = ThemeHelper.surface(context);
          final borderColor = ThemeHelper.border(context);
          final textColor = ThemeHelper.text(context);
          final textSecColor = ThemeHelper.textSecondary(context);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
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
                Text(ann['title'] ?? '-', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 6),
                Text(ann['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: textSecColor, height: 1.5)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==================== CHILDREN TAB ====================
class _ChildrenTab extends StatefulWidget {
  const _ChildrenTab();

  @override
  State<_ChildrenTab> createState() => _ChildrenTabState();
}

class _ChildrenTabState extends State<_ChildrenTab> {
  final ApiService _api = ApiService();
  List<dynamic> _children = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final children = await _api.getChildren();
      setState(() { _children = children; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat data anak.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anak Saya')),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _loadChildren)
              : _children.isEmpty
                  ? AppWidgets.emptyState(icon: Icons.child_care, title: 'Belum ada anak terdaftar')
                  : RefreshIndicator(
                      onRefresh: _loadChildren,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _children.length,
                        itemBuilder: (context, index) => _buildChildCard(_children[index]),
                      ),
                    ),
    );
  }

  Widget _buildChildCard(dynamic child) {
    final packages = child['child_packages'] ?? [];
    final activePackage = packages.isNotEmpty ? packages.first['package'] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: ThemeHelper.border(context)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: AppColors.primaryLighter, borderRadius: AppRadius.mdAll),
                  child: Center(
                    child: Text(
                      (child['name'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child['name'] ?? '-', style: AppTypography.h2.copyWith(color: ThemeHelper.text(context))),
                      const SizedBox(height: 4),
                      Text('${child['gender'] == 'male' ? 'Laki-laki' : 'Perempuan'} · ${child['birth_date'] ?? '-'}', style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: ThemeHelper.bgAlt(context), borderRadius: AppRadius.mdAll),
              child: Column(
                children: [
                  AppWidgets.infoRow('Status', child['status'] == 'active' ? 'Aktif' : 'Nonaktif'),
                  AppWidgets.infoRow('Paket Aktif', activePackage?['name'] ?? 'Belum ada paket'),
                  if (activePackage != null)
                    AppWidgets.infoRow('Harga', CurrencyHelper.formatRupiah(activePackage['price'])),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/daily-stories'),
                    icon: const Icon(Icons.auto_stories, size: 16),
                    label: const Text('Hari Ini', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/attendance'),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Absensi', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/development'),
                    icon: const Icon(Icons.trending_up, size: 16),
                    label: const Text('Perkembangan', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== INVOICES TAB ====================
class _InvoicesTab extends StatefulWidget {
  const _InvoicesTab();

  @override
  State<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<_InvoicesTab> {
  final ApiService _api = ApiService();
  List<dynamic> _invoices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final invoices = await _api.getInvoices();
      setState(() { _invoices = invoices; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat tagihan.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tagihan')),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _loadInvoices)
              : _invoices.isEmpty
                  ? AppWidgets.emptyState(icon: Icons.receipt_long, title: 'Belum ada tagihan')
                  : RefreshIndicator(
                      onRefresh: _loadInvoices,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _invoices.length,
                        itemBuilder: (context, index) => _buildInvoiceCard(_invoices[index]),
                      ),
                    ),
    );
  }

  Widget _buildInvoiceCard(dynamic inv) {
    final status = inv['status'] ?? 'pending';
    final color = status == 'paid' ? AppColors.success : status == 'pending' ? AppColors.warning : AppColors.error;
    final label = status == 'paid' ? 'Lunas' : status == 'pending' ? 'Menunggu' : status == 'failed' ? 'Gagal' : status;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/invoices'),
      child: Container(
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
                Flexible(child: Text(inv['invoice_number'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                AppWidgets.statusBadge(label, color),
              ],
            ),
            const SizedBox(height: 12),
            AppWidgets.infoRow('Anak', inv['child']?['name'] ?? '-'),
            AppWidgets.infoRow('Total', CurrencyHelper.formatRupiah(inv['total']), isTotal: true),
          ],
        ),
      ),
    );
  }
}

// ==================== ACTIVITIES TAB ====================
class _ActivitiesTab extends StatefulWidget {
  const _ActivitiesTab();

  @override
  State<_ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<_ActivitiesTab> {
  final ApiService _api = ApiService();
  List<dynamic> _children = [];
  List<dynamic> _stories = [];
  int? _selectedChildId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final children = await _api.getChildren();
      _children = children;
      if (children.isNotEmpty) {
        _selectedChildId = children[0]['id'];
        await _loadStories(_selectedChildId!);
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Gagal memuat data.'; _isLoading = false; });
    }
  }

  Future<void> _loadStories(int childId) async {
    try {
      final stories = await _api.getDailyStories(childId);
      setState(() { _stories = stories; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat cerita.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivitas Hari Ini')),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: () { setState(() { _isLoading = true; _error = null; }); _loadData(); })
              : _children.isEmpty
                  ? AppWidgets.emptyState(icon: Icons.auto_stories, title: 'Belum ada data anak')
                  : RefreshIndicator(
                      onRefresh: () async { if (_selectedChildId != null) await _loadStories(_selectedChildId!); },
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_children.length > 1)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(color: ThemeHelper.surface(context), borderRadius: AppRadius.mdAll, border: Border.all(color: ThemeHelper.border(context))),
                                child: DropdownButton<int>(
                                  value: _selectedChildId,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: _children.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c['id'], child: Text(c['name'] ?? '-'))).toList(),
                                  onChanged: (id) { if (id != null) { setState(() { _selectedChildId = id; _isLoading = true; }); _loadStories(id); } },
                                ),
                              ),
                            if (_stories.isEmpty)
                              AppWidgets.emptyState(icon: Icons.auto_stories, title: 'Belum ada cerita hari ini')
                            else
                              ..._stories.map((story) => _buildStoryCard(story)),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildStoryCard(dynamic story) {
    final moodIcons = {'bahagia': '😊', 'biasa': '😐', 'sedih': '😢', 'sakit': '🤒', 'rewel': '😫'};
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.primaryLighter, borderRadius: AppRadius.smAll),
                child: Center(
                  child: Text(
                    (story['child']?['name'] ?? '?')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(story['child']?['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(story['date'] ?? '-', style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                  ],
                ),
              ),
              Text(moodIcons[story['mood']] ?? '😐', style: const TextStyle(fontSize: 28)),
            ],
          ),
          if (story['summary'] != null) ...[
            const SizedBox(height: 16),
            Text(story['summary'], style: const TextStyle(fontSize: 14, height: 1.6)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _buildInfoChip('Makan', '${story['meal_rating'] ?? '-'}', Icons.restaurant),
              const SizedBox(width: 8),
              _buildInfoChip('Tidur', '${story['sleep_hours'] ?? '-'} jam', Icons.bedtime),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: ThemeHelper.bgAlt(context), borderRadius: AppRadius.smAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ThemeHelper.textMuted(context)),
          const SizedBox(width: 6),
          Text('$label: $value', style: TextStyle(fontSize: 12, color: ThemeHelper.textSecondary(context), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ==================== PROFILE TAB ====================
class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _api.getMe();
      if (response['success'] == true) {
        setState(() { _profileData = response['data']; _isLoading = false; });
      } else {
        setState(() { _error = 'Gagal memuat profil.'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Gagal memuat profil.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              auth.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _loadProfile)
              : _buildProfile(auth),
    );
  }

  Widget _buildProfile(AuthProvider auth) {
    final user = _profileData ?? auth.user;
    final initial = (user?['name'] ?? 'U')[0].toUpperCase();
    final role = user?['role'] ?? '';
    final roleLabel = role == 'admin_master' ? 'Admin Master' : role == 'admin' ? 'Admin' : 'Orang Tua';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Profile Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: ThemeHelper.surface(context),
              borderRadius: AppRadius.xlAll,
              border: Border.all(color: ThemeHelper.border(context)),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: AppColors.primaryLighter, shape: BoxShape.circle),
                  child: Center(
                    child: Text(initial, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(user?['name'] ?? '-', style: AppTypography.h2.copyWith(color: ThemeHelper.text(context)), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(user?['email'] ?? '-', style: AppTypography.bodySmall.copyWith(color: ThemeHelper.textSecondary(context)), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                AppWidgets.statusBadge(roleLabel, AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Account Info
          Container(
            width: double.infinity,
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
                Text('Informasi Akun', style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
                const SizedBox(height: 16),
                AppWidgets.infoRow('Nama', user?['name'] ?? '-'),
                AppWidgets.infoRow('Email', user?['email'] ?? '-'),
                AppWidgets.infoRow('Role', roleLabel),
                AppWidgets.infoRow('Status', user?['status'] == 'active' ? 'Aktif' : user?['status'] ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                auth.logout();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Keluar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final String? route;
  _ActionItem(this.label, this.icon, this.route);
}
