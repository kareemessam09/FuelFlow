import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../services/auth_service.dart';
import '../../widgets/common/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _submitting = false;

  static const _pages = [
    _OnboardingPageData(
      icon: Icons.monitor_heart_outlined,
      title: 'See Your Energy Clearly',
      description:
          'FuelFlow turns meals, activity, and insulin context into one clean fuel view you can understand quickly.',
      accent: AppColors.primary,
      imageUrl:
          'https://images.pexels.com/photos/40568/medical-appointment-doctor-healthcare-40568.jpeg?auto=compress&cs=tinysrgb&w=1200',
    ),
    _OnboardingPageData(
      icon: Icons.restaurant_menu_outlined,
      title: 'Log Meals Fast',
      description:
          'Capture food details in seconds and keep a history that helps you spot personal glucose patterns over time.',
      accent: AppColors.primaryBlue,
      imageUrl:
          'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=1200',
    ),
    _OnboardingPageData(
      icon: Icons.notifications_active_outlined,
      title: 'Get Timely Nudges',
      description:
          'Receive smart reminders before your energy drops too low so you can act early and avoid crashes.',
      accent: AppColors.accent,
      imageUrl:
          'https://images.pexels.com/photos/267394/pexels-photo-267394.jpeg?auto=compress&cs=tinysrgb&w=1200',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await AuthService().markOnboardingCompleted();
    if (!mounted) return;
    final isLoggedIn = AuthService().isAuthenticated;
    context.go(isLoggedIn ? '/' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Row(
                  children: [
                    Text(
                      'FuelFlow',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const Spacer(),
                    if (!isLastPage)
                      TextActionButton(
                        label: 'Skip',
                        onPressed: _finish,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _OnboardingSlide(page: page);
                  },
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: 'Onboarding progress step ${_currentPage + 1} of ${_pages.length}',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: isLastPage ? 'Finish onboarding' : 'Go to next onboarding page',
                child: BrutalButton(
                  label: isLastPage ? 'Get Started' : 'Next',
                  isLoading: _submitting,
                  onPressed: () async {
                    if (isLastPage) {
                      await _finish();
                      return;
                    }
                    await _pageController.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingPageData page;

  const _OnboardingSlide({required this.page});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          borderRadius: 28,
          borderColor: AppColors.border,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    page.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.surface,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          color: page.accent,
                          strokeWidth: 2.4,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: Icon(
                        page.icon,
                        color: page.accent,
                        size: 52,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: page.accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  page.icon,
                  size: 38,
                  color: page.accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                page.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                      fontSize: 16,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final String imageUrl;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.imageUrl,
  });
}
