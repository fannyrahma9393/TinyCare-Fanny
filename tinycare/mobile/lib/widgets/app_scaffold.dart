import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Bottom navigation shell for the app.
/// Shows different nav items based on user role.
class AppScaffold extends StatefulWidget {
  final int initialIndex;
  
  const AppScaffold({super.key, this.initialIndex = 0});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: isAdmin ? _adminPages : _parentPages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted,
            selectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            items: isAdmin ? _adminNavItems : _parentNavItems,
          ),
        ),
      ),
    );
  }

  List<Widget> get _parentPages => const [
    _PlaceholderPage(icon: Icons.home, label: 'Beranda'),  // Dashboard handled by parent
    _PlaceholderPage(icon: Icons.child_care, label: 'Anak'),
    _PlaceholderPage(icon: Icons.receipt_long, label: 'Tagihan'),
    _PlaceholderPage(icon: Icons.person, label: 'Profil'),
  ];

  List<Widget> get _adminPages => const [
    _PlaceholderPage(icon: Icons.dashboard, label: 'Dashboard'),
    _PlaceholderPage(icon: Icons.child_care, label: 'Anak'),
    _PlaceholderPage(icon: Icons.receipt_long, label: 'Invoice'),
    _PlaceholderPage(icon: Icons.person, label: 'Profil'),
  ];

  List<BottomNavigationBarItem> get _parentNavItems => const [
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
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];

  List<BottomNavigationBarItem> get _adminNavItems => const [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.child_care_outlined),
      activeIcon: Icon(Icons.child_care),
      label: 'Anak',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      activeIcon: Icon(Icons.receipt_long),
      label: 'Invoice',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];
}

/// Placeholder page - actual pages will be integrated via routes
class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _PlaceholderPage({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(label, style: AppTypography.h3),
        ],
      ),
    );
  }
}
