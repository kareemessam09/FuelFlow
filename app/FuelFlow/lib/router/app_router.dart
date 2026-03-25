import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/auth/auth_screens.dart';
import '../presentation/screens/dashboard/dashboard.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/meal_capture/meal_capture_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../services/auth_service.dart';

/// Route names for navigation
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String dashboard = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String activity = '/activity';
  static const String mealCapture = '/meal-capture';
  static const String mealAnalysis = '/meal-analysis';
  static const String stats = '/stats';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

/// App router configuration using go_router
/// 
/// Implements a fluid, single-page feel with overlays and sheets
/// rather than full page transitions
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// The main router instance
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    // Auth guard — redirect to login if no token is stored
    // Skip guard for splash screen
    redirect: (context, state) async {
      final isSplash = state.matchedLocation == AppRoutes.splash;
      if (isSplash) return null; // Allow splash to handle its own navigation
      
      final isLoggedIn = AuthService().isAuthenticated;
      final isOnAuth =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!isLoggedIn && !isOnAuth) return AppRoutes.login;
      if (isLoggedIn && isOnAuth) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      // Splash Screen - Entry point
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),

      // Main Dashboard - The anchor screen
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
        routes: [
          // Activity selector - Shown as overlay/bottom sheet
          // This route exists for deep linking support
          GoRoute(
            path: 'activity',
            name: 'activity',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              opaque: false,
              barrierDismissible: true,
              barrierColor: Colors.black54,
              child: const _ActivityRouteHandler(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
            ),
          ),

          // Meal capture
          GoRoute(
            path: 'meal-capture',
            name: 'meal-capture',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const MealCaptureScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
            ),
          ),
          
          // Profile Screen
          GoRoute(
            path: 'profile',
            name: 'profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
            ),
          ),
        ],
      ),

      // Stats screen
      GoRoute(
        path: AppRoutes.stats,
        name: 'stats',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const _StatsPlaceholder(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),

      // Settings screen
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const _SettingsPlaceholder(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),

      // Login screen
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => const MaterialPage(
          child: LoginScreen(),
        ),
      ),

      // Register screen
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => const MaterialPage(
          child: RegisterScreen(),
        ),
      ),
    ],

    // Error handling
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri}'),
        ),
      ),
    ),
  );
}

// Route handlers that can redirect to the actual UI
// These exist for deep linking and back button support

class _ActivityRouteHandler extends StatelessWidget {
  const _ActivityRouteHandler();

  @override
  Widget build(BuildContext context) {
    // This will be shown when navigating directly to /activity
    // In practice, activity selector is shown via bottom sheet from dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.pop();
    });
    return const SizedBox.shrink();
  }
}

// Removed legacy MealCaptureRouteHandler

class _StatsPlaceholder extends StatelessWidget {
  const _StatsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text(
          'Stats coming soon',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text(
          'Settings coming soon',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
