import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/theme/app_theme.dart';
import 'liquid_painter.dart';

/// LiquidBalloonWidget - core visual component with calm, readable motion.
class LiquidBalloonWidget extends StatefulWidget {
  final double fillPercentage;
  final double size;
  final VoidCallback? onTap;

  const LiquidBalloonWidget({
    super.key,
    required this.fillPercentage,
    this.size = AppConstants.balloonDefaultSize,
    this.onTap,
  });

  @override
  State<LiquidBalloonWidget> createState() => _LiquidBalloonWidgetState();
}

class _LiquidBalloonWidgetState extends State<LiquidBalloonWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late AnimationController _criticalPulseController;
  late Animation<double> _criticalPulse;

  late Animation<double> _waveAnimation;
  late Animation<double> _fillAnimation;

  double _previousFill = 50.0;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppConstants.waveAnimationCycleMs),
    )..repeat();
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_waveController);

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

    _criticalPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _criticalPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _criticalPulseController,
        curve: Curves.easeInOut,
      ),
    );

    _fillController.forward();
  }

  @override
  void didUpdateWidget(LiquidBalloonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

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
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    _criticalPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = widget.fillPercentage <= 30.0 && widget.fillPercentage > 0.0;
    if (isCritical) {
      if (!_criticalPulseController.isAnimating) {
        _criticalPulseController.repeat(reverse: true);
      }
    } else if (_criticalPulseController.isAnimating) {
      _criticalPulseController.stop();
      _criticalPulseController.value = 0.0;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _waveAnimation,
        _fillAnimation,
        _criticalPulse,
      ]),
      builder: (context, child) {
        final currentFill = _fillAnimation.value.clamp(0.0, 100.0);
        final fillFraction = currentFill / 100.0;
        final strobeValue = isCritical ? _criticalPulse.value : 0.0;
        final invert = isCritical && strobeValue >= 0.5;

        final backgroundColor = invert ? Colors.white : AppColors.surface;
        final liquidColor = isCritical
            ? (invert ? Colors.black : Colors.white)
            : AppColors.getFuelColor(currentFill);
        final outlineColor = isCritical
            ? (invert ? Colors.black : Colors.white)
            : AppColors.border;
        final textColor = invert ? Colors.black : AppColors.textPrimary;
        final shockColor = isCritical
            ? (invert ? Colors.black.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.22))
            : Colors.transparent;

        return GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isCritical)
                  Container(
                    width: widget.size - 2,
                    height: widget.size - 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: shockColor,
                          blurRadius: 18 + (strobeValue * 16),
                          spreadRadius: 1 + (strobeValue * 3),
                        ),
                      ],
                    ),
                  ),
                // Inner balloon void
                ClipOval(
                  child: Container(
                    width: widget.size - 20,
                    height: widget.size - 20,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      children: [
                        // Isolated repaint boundary for the continuous 60fps wave
                        RepaintBoundary(
                          child: CustomPaint(
                            size: Size(widget.size - 20, widget.size - 20),
                            painter: LiquidPainter(
                              fillPercentage: fillFraction,
                              waveAnimation: _waveAnimation.value,
                              liquidColor: liquidColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Subtle outer ring
                CustomPaint(
                  size: Size(widget.size - 16, widget.size - 16),
                  painter: BalloonOutlinePainter(
                    outlineColor: outlineColor,
                    strokeWidth: 2.0,
                  ),
                ),

                // Absolute-centered numeric percentage
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${currentFill.toInt()}',
                      style: AppTheme.monoStyle.copyWith(
                        color: textColor,
                        fontSize: 72,
                      ),
                    ),
                    Text(
                      '%',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
