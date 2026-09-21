import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

/// Bottom navigation shell for the app.
///
/// IMPORTANT (parity with web):
/// - This scaffold is used only as a convenience wrapper in a few parent-facing
///   tabs. The real app navigation is route-based (main.dart routes).
/// - Do not keep this as the primary navigation model if it duplicates or
///   conflicts with the route pages. Prefer navigating to the real pages.
///
/// Current behaviour:
/// - Parent: Beranda / Anak / Tagihan / Profil
/// - Admin:  Dashboard / Anak / Invoice / Profil
///
/// Keep this minimal. If a section should show a real page (e.g. parent
/// dashboard, children list, invoices, profile), that page should be reached
/// via routes, not via IndexedStack placeholders.
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

    // NOTE: placeholders are kept intentionally minimal.
    // If a tab should show a full page, navigate to the route instead.
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: isAdmin ? _adminPages : _parentPages,
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final surfaceColor = ThemeHelper.surface(context);
          final borderColor = ThemeHelper.border(context);
          return Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                top: BorderSide(color: borderColor, width: 1),
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
                unselectedItemColor: ThemeHelper.textMuted(context),
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
          );
        },
      ),
    );
  }

  List<Widget> get _parentPages => [
    _NavigatePage(route: '/dashboard', label: tr('Beranda')),
    _NavigatePage(route: '/children', label: tr('Anak')),
    _NavigatePage(route: '/invoices', label: tr('Tagihan')),
    _NavigatePage(route: '/profile', label: tr('Profil')),
  ];

  List<Widget> get _adminPages => [
    _NavigatePage(route: '/admin-dashboard', label: tr('Dashboard')),
    _NavigatePage(route: '/children', label: tr('Anak')),
    _NavigatePage(route: '/invoices', label: tr('Invoice')),
    _NavigatePage(route: '/profile', label: tr('Profil')),
  ];

  List<BottomNavigationBarItem> get _parentNavItems => [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: tr('Beranda'),
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.child_care_outlined),
      activeIcon: Icon(Icons.child_care),
      label: tr('Anak'),
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      activeIcon: Icon(Icons.receipt_long),
      label: tr('Tagihan'),
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: tr('Profil'),
    ),
  ];

  List<BottomNavigationBarItem> get _adminNavItems => [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: tr('Dashboard'),
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.child_care_outlined),
      activeIcon: Icon(Icons.child_care),
      label: tr('Anak'),
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      activeIcon: Icon(Icons.receipt_long),
      label: tr('Invoice'),
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: tr('Profil'),
    ),
  ];
}

/// Minimal page that navigates to the real route.
class _NavigatePage extends StatelessWidget {
  final String route;
  final String label;

  const _NavigatePage({required this.route, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.open_in_browser,
              size: 48,
              color: ThemeHelper.textMuted(context),
            ),
            const SizedBox(height: 12),
            Text(
              tr('Buka {{label}}', {'label': label}),
              style: AppTypography.h3.copyWith(color: ThemeHelper.text(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, route);
              },
              child: Text(tr('Buka Halaman')),
            ),
          ],
        ),
      ),
    );
  }
}
