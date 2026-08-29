import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/children_page.dart';
import 'pages/daily_stories_page.dart';
import 'pages/attendance_page.dart';
import 'pages/development_page.dart';
import 'pages/invoices_page.dart';
import 'pages/announcements_page.dart';
import 'pages/events_page.dart';
import 'pages/feedback_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/register_page.dart';
import 'pages/user_management_page.dart';
import 'pages/admin_management_page.dart';
import 'pages/profile_page.dart';
import 'pages/activities_page.dart';
import 'pages/packages_page.dart';
import 'pages/vouchers_page.dart';
import 'pages/parents_page.dart';
import 'pages/payments_page.dart';
import 'pages/reports_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService().init();

  // Catch Flutter framework errors (synchronous)
  FlutterError.onError = (details) {
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    debugPrint('[FlutterError] ${details.stack}');
  };

  // Show errors visually on screen so they don't cause blank white screens
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.red[50],
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          'Error: ${details.exceptionAsString()}',
          style: const TextStyle(fontSize: 12, color: Colors.red),
        ),
      ),
    );
  };

  // Catch async errors that would otherwise crash silently on web
  runZonedGuarded(
    () {
      runApp(const TinyCareApp());
    },
    (error, stack) {
      debugPrint('[ZoneError] Unhandled error: $error');
      debugPrint('[ZoneError] Stack: $stack');
    },
  );
}

class TinyCareApp extends StatelessWidget {
  const TinyCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'TinyCare',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.flutterThemeMode,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/dashboard': (context) => const _AuthGuard(child: DashboardPage()),
            '/admin-dashboard': (context) => const _AuthGuard(child: AdminDashboardPage()),
            '/children': (context) => const _AuthGuard(child: ChildrenPage()),
            '/daily-stories': (context) => const _AuthGuard(child: DailyStoriesPage()),
            '/attendance': (context) => const _AuthGuard(child: AttendancePage()),
            '/development': (context) => const _AuthGuard(child: DevelopmentPage()),
            '/invoices': (context) => const _AuthGuard(child: InvoicesPage()),
            '/announcements': (context) => const _AuthGuard(child: AnnouncementsPage()),
            '/events': (context) => const _AuthGuard(child: EventsPage()),
            '/feedback': (context) => const _AuthGuard(child: FeedbackPage()),
            '/profile': (context) => const _AuthGuard(child: ProfilePage()),
            '/users': (context) => const _AuthGuard(child: UserManagementPage()),
            '/admin-management': (context) => const _AuthGuard(child: AdminManagementPage()),
            '/activities': (context) => const _AuthGuard(child: ActivitiesPage()),
            '/packages': (context) => const _AuthGuard(child: PackagesPage()),
            '/vouchers': (context) => const _AuthGuard(child: VouchersPage()),
            '/parents': (context) => const _AuthGuard(child: ParentsPage()),
            '/payments': (context) => const _AuthGuard(child: PaymentsPage()),
            '/reports': (context) => const _AuthGuard(child: ReportsPage()),
          },
        ),
      ),
    );
  }
}

/// Widget that guards routes - redirects to login if not authenticated.
/// Also enforces role-based access.
class _AuthGuard extends StatelessWidget {
  final Widget child;
  const _AuthGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (!auth.isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // Role-based route guard
        final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
        final isAdminRoute = currentRoute == '/admin-dashboard';

        if (isAdminRoute && !auth.isAdmin) {
          // Parent trying to access admin route - deny
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (!isAdminRoute && auth.isAdmin && currentRoute == '/dashboard') {
          // Admin trying to access parent dashboard - redirect to admin
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        return child;
      },
    );
  }
}
