import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/children_page.dart';
import 'pages/daily_stories_page.dart';
import 'pages/development_page.dart';
import 'pages/invoices_page.dart';
import 'pages/announcements_page.dart';
import 'pages/announcement_detail_page.dart';
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
import 'pages/child_information_page.dart';
import 'pages/parent_information_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/notifications_page.dart';
import 'pages/change_password_page.dart';
import 'pages/invoice_detail_page.dart';
import 'widgets/parent_scaffold.dart';

/// Global navigator key so FCM notification taps can route navigation even
/// when a widget context is unavailable (background/terminated launches).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService().init();

  // Initialize Firebase Messaging (guarded: never crashes if not configured).
  FcmService.instance.initialize();

  // Foreground push -> clear in-app feedback via SnackBar.
  FcmService.instance.onForegroundMessage = (notification) {
    final messenger = navigatorKey.currentState?.context;
    if (messenger == null) return;
    ScaffoldMessenger.of(messenger).showSnackBar(
      SnackBar(
        content: Text(
          '${notification.title}\n${notification.body}',
          style: const TextStyle(height: 1.3),
        ),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  };

  // Notification tap -> route to the relevant page.
  FcmService.instance.onNotificationTap = (notification) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    // Announcement pushes carry announcement_id -> open the exact announcement
    // instead of the plain list. Auth-guarded: not-logged-in users are sent
    // to login first.
    if (notification.type == 'announcement' &&
        notification.announcementId != null) {
      nav.push(MaterialPageRoute(
        builder: (_) => _AuthGuard(
          child: AnnouncementDetailPage(
            announcementId: notification.announcementId!,
          ),
        ),
      ));
      return;
    }

    // Invoice/payment notifications (invoice_created, payment_verified,
    // payment_rejected) carry invoice_id -> open the invoice detail directly.
    if (notification.canOpenInvoiceDetail) {
      nav.push(MaterialPageRoute(
        builder: (_) => _AuthGuard(
          child: InvoiceDetailPage(invoiceId: notification.invoiceId!),
        ),
      ));
      return;
    }

    nav.pushNamed(notification.resolveRoute());
  };

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
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.flutterThemeMode,
          home: const _InitialRoute(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/reset-password': (context) => const ResetPasswordPage(),
            '/notifications': (context) => const _AuthGuard(child: NotificationsPage()),
            '/change-password': (context) => const _AuthGuard(child: ChangePasswordPage()),
            '/dashboard': (context) => const _AuthGuard(child: AdminDashboardPage()),
            '/parent': (context) => const _AuthGuard(child: ParentScaffold()),
            '/children': (context) => const _AuthGuard(child: ChildrenPage()),
            '/daily-stories': (context) => const _AuthGuard(child: DailyStoriesPage()),
            '/development': (context) => const _AuthGuard(child: DevelopmentPage()),
            '/invoices': (context) => const _AuthGuard(child: InvoicesPage()),
            '/announcements': (context) => const _AuthGuard(child: AnnouncementsPage()),
            '/feedback': (context) => const _AuthGuard(child: FeedbackPage()),
            '/profile': (context) => const _AuthGuard(child: ProfilePage()),
            '/users': (context) => const _AuthGuard(child: UserManagementPage()),
            '/admin-management': (context) => const _AuthGuard(child: AdminManagementPage()),
            '/activities': (context) => const _AuthGuard(child: ActivitiesPage()),
            '/parent/information': (context) => const _AuthGuard(child: ParentInformationPage()),
            '/information': (context) => const _AuthGuard(child: ChildInformationPage()),
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

/// Widget that routes the user to the correct first page on app open.
/// While AuthProvider.init() is running it shows a loading spinner; once
/// resolved it redirects to the role-appropriate dashboard when logged in,
/// or to the login page when not. This lets a previously-logged-in user skip
/// the login screen and land straight on their dashboard.
class _InitialRoute extends StatelessWidget {
  const _InitialRoute();

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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (!auth.isLoggedIn) {
            Navigator.pushReplacementNamed(context, '/login');
          } else if (auth.isAdmin) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/parent');
          }
        });
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      },
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
        final isAdminRoute = currentRoute == '/dashboard';
        final isParentRoute = currentRoute == '/parent';

        // Routes that are admin-only in the web app (AdminRoute wrapper).
        // Any logged-in parent reaching one of these is redirected, mirroring
        // web's behaviour (non-admin -> /parent, i.e. the parent dashboard).
        const adminOnlyRoutes = {
          '/users',
          '/packages',
          '/vouchers',
          '/payments',
          '/parents',
          '/admin-management',
          '/reports',
        };

        // Routes that are parent-only in the web app (ParentRoute wrapper).
        // Any logged-in admin reaching one of these is redirected to admin dashboard.
        const parentOnlyRoutes = {
          '/parent',
          '/parent/children',
          '/parent/activities',
          '/parent/development',
          '/parent/announcements',
          '/parent/information',
          '/parent/feedback',
          '/parent/invoices',
          '/parent/profile',
        };

        if (adminOnlyRoutes.contains(currentRoute) && !auth.isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/parent');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (parentOnlyRoutes.contains(currentRoute) && auth.isAdmin) {
          // Admin trying to access parent route - redirect to admin
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (isAdminRoute && !auth.isAdmin) {
          // Parent trying to access admin route - redirect to parent
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/parent');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (isParentRoute && auth.isAdmin) {
          // Admin trying to access parent dashboard - redirect to admin
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/dashboard');
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
