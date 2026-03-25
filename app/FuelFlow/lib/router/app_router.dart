import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/dashboard/dashboard.dart';

/// Route names for navigation
class AppRoutes {
  AppRoutes._();

  static const String dashboard = '/';
  static const String activity = '/activity';
  static const String mealCapture = '/meal-capture';
  static const String mealAnalysis = '/meal-analysis';
  static const String stats = '/stats';
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
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,
    routes: [
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

          // Meal capture - Camera overlay
          GoRoute(
            path: 'meal-capture',
            name: 'meal-capture',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              opaque: false,
              barrierDismissible: false,
              barrierColor: Colors.black87,
              child: const _MealCaptureRouteHandler(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
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

class _MealCaptureRouteHandler extends StatelessWidget {
  const _MealCaptureRouteHandler();

  @override
  Widget build(BuildContext context) {
    // Placeholder for meal capture screen
    // Will be replaced with actual camera implementation
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2A2A3C)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 64,
                  color: const Color(0xFF00F5FF),
                ),
                const SizedBox(height: 16),
                Text(
                  'Snap & Fuel',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Camera integration coming soon',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Tap to close',
                    style: TextStyle(color: const Color(0xFF00F5FF)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
