import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import 'liquid_painter.dart';

/// LiquidBalloonWidget - The core visual component of FuelFlow
/// 
/// A custom animated widget that displays a circular "stomach balloon"
/// filled with liquid that represents the user's current energy level.
/// 
/// Features:
/// - Animated liquid with wave effect
/// - Color transitions based on fill percentage
/// - Neon glow effects
/// - Bubble animations
/// - Smooth fill level transitions
class LiquidBalloonWidget extends StatefulWidget {
  /// Current fill percentage (0-100)
  final double fillPercentage;

  /// Size of the balloon
  final double size;

  /// Optional callback when balloon is tapped
  final VoidCallback? onTap;

  /// Whether to show bubbles
  final bool showBubbles;

  /// Whether to animate the waves
  final bool animateWaves;

  const LiquidBalloonWidget({
    super.key,
    required this.fillPercentage,
    this.size = AppConstants.balloonDefaultSize,
    this.onTap,
    this.showBubbles = true,
    this.animateWaves = true,
  });

  @override
  State<LiquidBalloonWidget> createState() => _LiquidBalloonWidgetState();
}

class _LiquidBalloonWidgetState extends State<LiquidBalloonWidget>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _waveController;
  late AnimationController _fillController;
  late AnimationController _bubbleController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _waveAnimation;
  late Animation<double> _fillAnimation;
  late Animation<double> _bubbleAnimation;
  late Animation<double> _pulseAnimation;

  // Bubble data
  late List<dynamic> _bubbles;

  // Track the previous fill for smooth transitions
  double _previousFill = 50.0;

  @override
  void initState() {
    super.initState();

    // Wave animation - continuous loop
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppConstants.waveAnimationCycleMs),
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_waveController);

    if (widget.animateWaves) {
      _waveController.repeat();
    }

    // Fill level animation - for smooth transitions
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppConstants.balloonAnimationDurationMs),
    );
    _fillAnimation = Tween<double>(
      begin: _previousFill,
      end: widget.fillPercentage,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeOutCubic,
    ));

    // Bubble animation - slower loop
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _bubbleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_bubbleController);

    if (widget.showBubbles) {
      _bubbleController.repeat();
    }

    // Pulse animation for critical state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Generate bubbles
    _bubbles = generateBubbles(8);

    // Start fill animation
    _fillController.forward();

    // Check if we need pulse animation
    _updatePulseAnimation();
  }

  @override
  void didUpdateWidget(LiquidBalloonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate fill changes
    if (oldWidget.fillPercentage != widget.fillPercentage) {
      _previousFill = _fillAnimation.value;
      _fillAnimation = Tween<double>(
        begin: _previousFill,
        end: widget.fillPercentage,
      ).animate(CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeOutCubic,
      ));
      _fillController.forward(from: 0);
    }

    // Update pulse animation based on critical state
    _updatePulseAnimation();

    // Handle wave animation toggle
    if (widget.animateWaves && !_waveController.isAnimating) {
      _waveController.repeat();
    } else if (!widget.animateWaves && _waveController.isAnimating) {
      _waveController.stop();
    }
  }

  void _updatePulseAnimation() {
    final isCritical = widget.fillPercentage <= AppConstants.criticalThreshold &&
        widget.fillPercentage > 0;

    if (isCritical && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isCritical && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    _bubbleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _waveAnimation,
        _fillAnimation,
        _bubbleAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        final currentFill = _fillAnimation.value.clamp(0.0, 100.0);
        final fillFraction = currentFill / 100.0;

        // Get colors based on current fill
        final primaryColor = AppColors.getFuelColor(currentFill);
        final secondaryColor = _getSecondaryColor(currentFill);
        final glowColor = AppColors.getGlowColor(currentFill);

        // Apply pulse scale for critical state
        final scale = widget.fillPercentage <= AppConstants.criticalThreshold &&
                widget.fillPercentage > 0
            ? _pulseAnimation.value
            : 1.0;

        return GestureDetector(
          onTap: widget.onTap,
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow effect
                  _buildGlowEffect(glowColor),

                  // Main balloon container with liquid
                  ClipOval(
                    child: Container(
                      width: widget.size - 20,
                      height: widget.size - 20,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        children: [
                          // Liquid fill
                          CustomPaint(
                            size: Size(widget.size - 20, widget.size - 20),
                            painter: LiquidPainter(
                              fillPercentage: fillFraction,
                              waveAnimation: _waveAnimation.value,
                              liquidColor: primaryColor,
                              liquidColorSecondary: secondaryColor,
                            ),
                          ),

                          // Bubbles
                          if (widget.showBubbles && fillFraction > 0.05)
                            CustomPaint(
                              size: Size(widget.size - 20, widget.size - 20),
                              painter: BubblePainter(
                                fillPercentage: fillFraction,
                                animationValue: _bubbleAnimation.value,
                                bubbleColor: Colors.white,
                                bubbles: _bubbles,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Balloon outline with glow
                  CustomPaint(
                    size: Size(widget.size - 16, widget.size - 16),
                    painter: BalloonOutlinePainter(
                      glowColor: glowColor,
                      glowIntensity: _getGlowIntensity(currentFill),
                    ),
                  ),

                  // Center percentage text
                  _buildPercentageText(currentFill),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowEffect(Color glowColor) {
    return Container(
      width: widget.size + 40,
      height: widget.size + 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.3),
            blurRadius: AppConstants.glowBlurRadius,
            spreadRadius: AppConstants.glowSpreadRadius,
          ),
          BoxShadow(
            color: glowColor.withOpacity(0.15),
            blurRadius: AppConstants.glowBlurRadius * 2,
            spreadRadius: AppConstants.glowSpreadRadius * 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageText(double percentage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${percentage.toInt()}',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            shadows: [
              Shadow(
                color: AppColors.getGlowColor(percentage).withOpacity(0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        Text(
          '%',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getSecondaryColor(double percentage) {
    if (percentage > 60) return const Color(0xFF00CC52);
    if (percentage > 30) return const Color(0xFFFFBB00);
    return const Color(0xFFCC0030);
  }

  double _getGlowIntensity(double percentage) {
    // Increase glow intensity as fuel gets lower (more urgent)
    if (percentage <= 30) return 1.5;
    if (percentage <= 60) return 1.0;
    return 0.8;
  }
}
