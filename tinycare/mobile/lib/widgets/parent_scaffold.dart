import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../pages/dashboard_page.dart';
import '../pages/activities_page.dart';
import '../pages/activities_detail_page.dart';
import '../pages/development_page.dart';
import '../pages/development_detail_page.dart';
import '../pages/announcements_page.dart';
import '../pages/feedback_page.dart';
import '../pages/invoices_page.dart';
import '../pages/parent_information_page.dart';
import '../pages/profile_page.dart';
import '../pages/child_detail_page.dart';
import 'child_photo.dart';

/// Parent scaffold with bottom navigation bar matching web ParentLayout sidebar.
/// Bottom nav: Beranda, Anak, Aktivitas, Tagihan, Lainnya
class ParentScaffold extends StatefulWidget {
  const ParentScaffold({super.key});

  @override
  State<ParentScaffold> createState() => _ParentScaffoldState();
}

class _ParentScaffoldState extends State<ParentScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const _ParentChildrenPage(),
    const ActivitiesPage(),
    const InvoicesPage(),
    const _ParentMorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: ThemeHelper.textMuted(context),
        selectedFontSize: 11,
        unselectedFontSize: 11,
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
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Aktivitas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Tagihan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            activeIcon: Icon(Icons.more_horiz),
            label: 'Lainnya',
          ),
        ],
      ),
    );
  }
}

/// Children list page for parent (mirrors web ParentChildren)
class _ParentChildrenPage extends StatefulWidget {
  const _ParentChildrenPage();

  @override
  State<_ParentChildrenPage> createState() => _ParentChildrenPageState();
}

class _ParentChildrenPageState extends State<_ParentChildrenPage> {
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
                  ? AppWidgets.emptyState(
                      icon: Icons.child_care,
                      title: 'Belum ada data anak',
                      subtitle: 'Data akan muncul ketika anak sudah terdaftar di daycare.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadChildren,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _children.length,
                        itemBuilder: (context, index) => _buildChildCard(_children[index]),
                      ),
                    ),
    );
  }

  Widget _buildChildCard(dynamic child) {
    final packages = child['child_packages'] ?? [];
    final activePackage = packages.isNotEmpty ? packages.first['package'] : null;
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChildDetailPage(childId: child['id'])),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeHelper.surface(context),
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: ThemeHelper.border(context)),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                ChildPhoto(child: child, width: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child['name'] ?? '-', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(height: 2),
                      Text(
                        '${child['gender'] == 'male' ? 'Laki-laki' : 'Perempuan'} · ${child['birth_date'] ?? '-'}',
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
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
                decoration: BoxDecoration(
                  color: ThemeHelper.successBg(context),
                  borderRadius: AppRadius.smAll,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activePackage['name'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                    const SizedBox(height: 2),
                    Text('Berlaku s/d ${activePackage['end_date'] ?? '-'}', style: TextStyle(fontSize: 12, color: mutedColor)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ActivitiesDetailPage(childId: child['id']),
                    )),
                    icon: const Icon(Icons.emoji_events_outlined, size: 16),
                    label: const Text('Aktivitas', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DevelopmentDetailPage(childId: child['id']),
                    )),
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

/// More menu page for parent (mirrors remaining web sidebar items)
class _ParentMorePage extends StatelessWidget {
  const _ParentMorePage();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ThemeHelper.surface(context),
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: ThemeHelper.border(context)),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLighter,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (auth.user?['name'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.user?['name'] ?? '-', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(height: 2),
                      Text(auth.user?['email'] ?? '', style: TextStyle(fontSize: 12, color: mutedColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Menu items
          AppWidgets.menuGroup([
            {
              'label': 'Perkembangan',
              'icon': Icons.trending_up,
              'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevelopmentPage())),
            },
            {
              'label': 'Pengumuman',
              'icon': Icons.campaign_outlined,
              'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsPage())),
            },
            {
              'label': 'Informasi',
              'icon': Icons.info_outline,
              'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentInformationPage())),
            },
            {
              'label': 'Feedback',
              'icon': Icons.rate_review_outlined,
              'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackPage())),
            },
            {
              'label': 'Profil',
              'icon': Icons.person_outline,
              'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
            },
          ], context: context),

          const SizedBox(height: 16),

          // Theme switcher
          const ThemeSwitcher(),

          const SizedBox(height: 16),

          // Logout
          AppWidgets.menuGroup([
            {
              'label': 'Keluar',
              'icon': Icons.logout,
              'iconColor': AppColors.error,
              'onTap': () async {
                final confirm = await AppWidgets.confirmDialog(
                  context,
                  title: 'Keluar',
                  content: 'Apakah Anda yakin ingin keluar?',
                  confirmLabel: 'Keluar',
                  confirmColor: AppColors.error,
                );
                if (confirm && context.mounted) {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                }
              },
            },
          ], context: context),

          const SizedBox(height: 24),

          // App version
          Center(
            child: Text('TinyCare v1.0.0', style: TextStyle(fontSize: 12, color: mutedColor)),
          ),
        ],
      ),
    );
  }
}


