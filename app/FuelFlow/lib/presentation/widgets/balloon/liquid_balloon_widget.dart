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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _waveAnimation,
        _fillAnimation,
      ]),
      builder: (context, child) {
        final currentFill = _fillAnimation.value.clamp(0.0, 100.0);
        final fillFraction = currentFill / 100.0;

        Color backgroundColor = AppColors.surface;
        Color liquidColor = AppColors.getFuelColor(currentFill);
        Color outlineColor = AppColors.border;
        Color textColor = AppColors.textPrimary;

        return GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
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
