import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../blocs/auth/auth.dart';

/// SplashScreen - Initial loading screen with branding animation
/// 
/// Shows the FuelFlow logo with a fuel gauge animation while:
/// - Checking authentication status
/// - Loading cached user data
/// - Initializing services
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fuelFillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _fuelFillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.9, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Navigate after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateBasedOnAuth();
      }
    });
  }

  void _navigateBasedOnAuth() {
    final authState = context.read<AuthBloc>().state;
    
    if (authState.status == AuthStatus.authenticated) {
      context.go('/');
    } else if (authState.status == AuthStatus.unauthenticated) {
      context.go('/login');
    } else {
      // Still checking, wait a bit more
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _navigateBasedOnAuth();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with fade and scale animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildLogo(),
                  ),
                ),
                const SizedBox(height: 48),
                // Fuel gauge loading indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildFuelGauge(),
                ),
                const SizedBox(height: 24),
                // Tagline
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'FUEL YOUR FOCUS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Tracking energy, meals, and activity...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Fuel drop icon
        Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // App name
        Text(
          'FUELFLOW',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFuelGauge() {
    return AnimatedBuilder(
      animation: _fuelFillAnimation,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _fuelFillAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
