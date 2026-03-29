import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/auth/auth_screens.dart';
import '../presentation/screens/dashboard/dashboard.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/meal_capture/meal_capture_screen.dart';
import '../presentation/screens/meals/meals_screen.dart';
import '../presentation/screens/analytics/analytics_screen.dart';
import '../presentation/screens/favorites/favorites_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../services/auth_service.dart';

/// Route names for navigation
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String dashboard = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String mealCapture = '/meal-capture';
  static const String meals = '/meals';
  static const String analytics = '/analytics';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

/// App router configuration using go_router
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// The main router instance
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final isSplash = state.matchedLocation == AppRoutes.splash;
      if (isSplash) return null;
      
      final isLoggedIn = AuthService().isAuthenticated;
      final isOnboardingRoute = state.matchedLocation == AppRoutes.onboarding;
      final isOnAuth =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isOnboardingDone = AuthService().isOnboardingCompleted;

      if (!isOnboardingDone && !isOnboardingRoute) return AppRoutes.onboarding;
      if (isOnboardingDone && isOnboardingRoute) {
        return isLoggedIn ? AppRoutes.dashboard : AppRoutes.login;
      }

      if (!isLoggedIn && !isOnAuth) return AppRoutes.login;
      if (isLoggedIn && isOnAuth) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Main Dashboard
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Meal Capture
      GoRoute(
        path: AppRoutes.mealCapture,
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

      // Meals History
      GoRoute(
        path: AppRoutes.meals,
        name: 'meals',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MealsScreen(),
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

      // Analytics
      GoRoute(
        path: AppRoutes.analytics,
        name: 'analytics',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AnalyticsScreen(),
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

      // Favorites
      GoRoute(
        path: AppRoutes.favorites,
        name: 'favorites',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FavoritesScreen(),
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

      // Profile
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileScreen(),
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

      // Settings
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
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

      // Login
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => const MaterialPage(
          child: LoginScreen(),
        ),
      ),

      // Register
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => const MaterialPage(
          child: RegisterScreen(),
        ),
      ),
    ],

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
