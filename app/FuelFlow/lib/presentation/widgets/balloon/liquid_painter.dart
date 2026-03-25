import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

/// Custom painter for the liquid/wave effect inside the balloon
/// Creates a dynamic, animated liquid surface with multiple wave layers
class LiquidPainter extends CustomPainter {
  /// Current fill percentage (0.0 - 1.0)
  final double fillPercentage;

  /// Current wave animation value (0.0 - 1.0, cycles continuously)
  final double waveAnimation;

  /// The color of the liquid
  final Color liquidColor;

  /// Secondary color for gradient effect
  final Color liquidColorSecondary;

  /// Number of wave layers for depth effect
  final int waveLayers;

  LiquidPainter({
    required this.fillPercentage,
    required this.waveAnimation,
    required this.liquidColor,
    required this.liquidColorSecondary,
    this.waveLayers = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0) return;

    final width = size.width;
    final height = size.height;

    // Calculate the base water level (from bottom)
    final baseWaterLevel = height * (1 - fillPercentage);

    // Draw multiple wave layers for depth effect
    for (int layer = waveLayers - 1; layer >= 0; layer--) {
      _drawWaveLayer(
        canvas,
        size,
        baseWaterLevel,
        layer,
      );
    }
  }

  void _drawWaveLayer(
    Canvas canvas,
    Size size,
    double baseWaterLevel,
    int layerIndex,
  ) {
    final width = size.width;
    final height = size.height;

    // Each layer has different properties for depth effect
    final layerOffset = layerIndex * 0.15;
    final opacity = 1.0 - (layerIndex * 0.25);
    final waveHeight = AppConstants.waveAmplitude * (1 - layerIndex * 0.2);
    final phaseOffset = layerIndex * (math.pi / 3);

    // Create gradient paint
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          liquidColor.withOpacity(opacity * 0.9),
          liquidColorSecondary.withOpacity(opacity),
        ],
      ).createShader(Rect.fromLTWH(0, baseWaterLevel, width, height - baseWaterLevel));

    // Create wave path
    final path = Path();

    // Start from bottom-left
    path.moveTo(0, height);

    // Draw the wave at the top of the liquid
    for (double x = 0; x <= width; x++) {
      // Multiple sine waves combined for organic look
      final primaryWave = math.sin(
        (x / width * 2 * math.pi) + (waveAnimation * 2 * math.pi) + phaseOffset,
      );
      final secondaryWave = math.sin(
        (x / width * 4 * math.pi) + (waveAnimation * 2 * math.pi * 1.5) + phaseOffset,
      ) * 0.5;

      final combinedWave = (primaryWave + secondaryWave) * waveHeight;
      final y = baseWaterLevel + combinedWave + (layerOffset * 10);

      if (x == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Close the path along the bottom
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    // Draw the wave
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidPainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.waveAnimation != waveAnimation ||
        oldDelegate.liquidColor != liquidColor ||
        oldDelegate.liquidColorSecondary != liquidColorSecondary;
  }
}

/// Painter for the balloon container outline with glow effect
class BalloonOutlinePainter extends CustomPainter {
  final Color glowColor;
  final double glowIntensity;
  final double strokeWidth;

  BalloonOutlinePainter({
    required this.glowColor,
    this.glowIntensity = 1.0,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;

    // Draw outer glow layers
    for (int i = 3; i >= 0; i--) {
      final glowRadius = radius + (i * 4);
      final glowOpacity = (0.15 - (i * 0.03)) * glowIntensity;

      final glowPaint = Paint()
        ..color = glowColor.withOpacity(glowOpacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(center, glowRadius, glowPaint);
    }

    // Draw main outline
    final outlinePaint = Paint()
      ..color = glowColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, outlinePaint);

    // Draw inner subtle highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius - 2, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant BalloonOutlinePainter oldDelegate) {
    return oldDelegate.glowColor != glowColor ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Painter for bubble effects inside the liquid
class BubblePainter extends CustomPainter {
  final double fillPercentage;
  final double animationValue;
  final Color bubbleColor;
  final List<_Bubble> bubbles;

  BubblePainter({
    required this.fillPercentage,
    required this.animationValue,
    required this.bubbleColor,
    required this.bubbles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0.05) return;

    final baseWaterLevel = size.height * (1 - fillPercentage);

    for (final bubble in bubbles) {
      // Calculate bubble position based on animation
      final progress = (animationValue + bubble.phaseOffset) % 1.0;
      final startY = size.height - 10;
      final endY = baseWaterLevel + 20;
      final y = startY - (startY - endY) * progress;

      // Only draw bubbles that are in the liquid
      if (y > baseWaterLevel && y < size.height) {
        final x = bubble.xPosition * size.width;
        final currentRadius = bubble.radius * (1 - progress * 0.3);
        final opacity = (1 - progress) * 0.6;

        final paint = Paint()
          ..color = bubbleColor.withOpacity(opacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), currentRadius, paint);

        // Add highlight to bubble
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(opacity * 0.5)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(x - currentRadius * 0.3, y - currentRadius * 0.3),
          currentRadius * 0.3,
          highlightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.animationValue != animationValue;
  }
}

/// Internal bubble data class
class _Bubble {
  final double xPosition; // 0.0 - 1.0
  final double radius;
  final double phaseOffset; // 0.0 - 1.0

  const _Bubble({
    required this.xPosition,
    required this.radius,
    required this.phaseOffset,
  });
}

/// Generates random bubbles for the effect
List<_Bubble> generateBubbles(int count) {
  final random = math.Random(42); // Fixed seed for consistent bubbles
  return List.generate(count, (index) {
    return _Bubble(
      xPosition: 0.1 + random.nextDouble() * 0.8,
      radius: 2 + random.nextDouble() * 4,
      phaseOffset: random.nextDouble(),
    );
  });
}
