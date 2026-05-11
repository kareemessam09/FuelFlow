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
          // Blurred energy orb - top right
          Positioned(
            top: -80,
            right: -80,
            child: _EnergyOrb(
              size: 280,
              color: AppColors.primaryBlue.withValues(alpha: 0.18),
            ),
          ),
          // Blurred energy orb - bottom left
          Positioned(
            bottom: -100,
            left: -100,
            child: _EnergyOrb(
              size: 320,
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),

          // Main content
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
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.30),
                                      AppColors.primary.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Logo container
                            Container(
                              width: 72,
                              height: 72,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
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
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: const Text(
                        'FuelFlow',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track your energy, fuel your day',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
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

/// Oversized radial gradient circle for ambient background glow
class _EnergyOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _EnergyOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
