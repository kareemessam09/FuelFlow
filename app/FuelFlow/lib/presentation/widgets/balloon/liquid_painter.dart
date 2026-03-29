import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

class LiquidPainter extends CustomPainter {
  final double fillPercentage;
  final double waveAnimation;
  final Color liquidColor;

  LiquidPainter({
    required this.fillPercentage,
    required this.waveAnimation,
    required this.liquidColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0) return;

    final height = size.height;
    final width = size.width;
    final baseWaterLevel = height * (1 - fillPercentage);

    // Save canvas state before clipping
    canvas.save();

    final path = Path();
    path.moveTo(0, height);

    const int segments = 6;
    final segmentWidth = width / segments;
    final phase = waveAnimation * 2 * math.pi;

    final waveHeight = AppConstants.waveAmplitude * 1.15;

    List<double> ys = List.generate(segments + 1, (i) {
      final x = i * segmentWidth;
      final primaryWave = math.sin((x / width * 2 * math.pi) + phase);
      final secondaryWave = math.sin((x / width * 4 * math.pi) + phase * 1.5) * 0.5;
      return baseWaterLevel + (primaryWave + secondaryWave) * waveHeight;
    });

    path.lineTo(0, ys[0]);
    for (int i = 1; i <= segments; i++) {
      final prevX = (i - 1) * segmentWidth;
      final currX = i * segmentWidth;
      final midX = (prevX + currX) / 2;
      path.quadraticBezierTo(prevX, ys[i - 1], midX, (ys[i - 1] + ys[i]) / 2);
      if (i == segments) path.lineTo(currX, ys[i]);
    }
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    final paint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
    
    // Restore canvas state
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LiquidPainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.waveAnimation != waveAnimation ||
        oldDelegate.liquidColor != liquidColor;
  }
}

class BalloonOutlinePainter extends CustomPainter {
  final Color outlineColor;
  final double strokeWidth;

  BalloonOutlinePainter({
    required this.outlineColor,
    this.strokeWidth = 4.0, // Thicker, brutalist border
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;

    // Draw solid hard outline, no glassmorphism or glow
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant BalloonOutlinePainter oldDelegate) {
    return oldDelegate.outlineColor != outlineColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
