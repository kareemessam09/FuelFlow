import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../router/app_router.dart';
import '../../../services/auth_service.dart';
import '../../blocs/auth/auth.dart';

/// SplashScreen - Simple startup screen while session state is checked
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _minimumDisplayTime = Duration(milliseconds: 900);
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    await Future<void>.delayed(_minimumDisplayTime);
    if (!mounted || _navigated) return;

    final authBloc = context.read<AuthBloc>();
    var authState = authBloc.state;

    if (authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading) {
      authState = await authBloc.stream.firstWhere(
        (state) =>
            state.status == AuthStatus.authenticated ||
            state.status == AuthStatus.unauthenticated ||
            state.status == AuthStatus.error,
      );
    }

    if (!mounted || _navigated) return;
    _navigated = true;

    if (!AuthService().isOnboardingCompleted) {
      context.go(AppRoutes.onboarding);
      return;
    }

    if (authState.status == AuthStatus.authenticated) {
      context.go(AppRoutes.dashboard);
      return;
    }

    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Image.asset(
                  'assets/images/fuelflow_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'FuelFlow',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Preparing your dashboard...',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
