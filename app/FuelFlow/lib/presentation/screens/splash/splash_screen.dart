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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minimumDisplayTime = Duration(milliseconds: 1400);
  bool _navigated = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _resolveRoute();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
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
      body: Stack(
        children: [
          Column(
            children: [
              const Spacer(flex: 3),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing logo
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow ring
                            Transform.scale(
                              scale: _pulseAnim.value,
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                            // Logo container
                            Container(
                              width: 72,
                              height: 72,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Image.asset(
                                'assets/images/fuelflow_icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // App name
                    Text(
                      'FuelFlow',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track your energy, fuel your day',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),

              // Slim loading bar at the bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: SizedBox(
                  width: 48,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

