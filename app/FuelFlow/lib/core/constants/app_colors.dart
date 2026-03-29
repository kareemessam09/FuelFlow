import 'package:flutter/material.dart';

/// FuelFlow color palette based on the requested brand colors.
class AppColors {
  AppColors._();

  // PRIMARY THEME COLORS
  static const Color primary = Color(0xFFB21235);      // Deep Red
  static const Color secondary = Color(0xFFFFF66B);    // Bright Yellow
  static const Color accent = Color(0xFFFF5672);       // Pink/Coral
  static const Color primaryBlue = Color(0xFF149BCC);  // Cyan
  static const Color darkBlue = Color(0xFF0985B2);     // Teal

  // BASE COLORS
  static const Color background = Color(0xFF101722);
  static const Color surface = Color(0xFF192231);
  static const Color surfaceElevated = Color(0xFF243044);
  static const Color border = Color(0xFF32445E);

  // STATUS COLORS - Fuel Levels
  static const Color fuelOptimal = Color(0xFF149BCC);  // Cyan - High energy
  static const Color fuelWarning = Color(0xFFFFF66B);  // Yellow - Medium
  static const Color fuelCritical = Color(0xFFB21235); // Deep Red - Low
  static const Color fuelDepleted = Color(0xFF6E7681); // Gray - Empty

  // SUPPORT COLORS
  static const Color glowGreen = Color(0xFF149BCC);
  static const Color glowYellow = Color(0xFFFFF66B);
  static const Color glowRed = Color(0xFFB21235);
  static const Color glowCyan = Color(0xFF149BCC);
  static const Color glowPurple = Color(0xFFFF5672);

  // TEXT COLORS
  static const Color textPrimary = Color(0xFFF4F7FB);
  static const Color textSecondary = Color(0xFFB6C0CF);
  static const Color textTertiary = Color(0xFF8D9CB0);
  static const Color textAccent = Color(0xFFFFF66B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ACTIVITY MODE COLORS
  static const Color modeSleeping = Color(0xFF6E7681);
  static const Color modeResting = Color(0xFF0985B2);
  static const Color modeCoding = Color(0xFF149BCC);
  static const Color modeStudying = Color(0xFFFFF66B);
  static const Color modeGymStrength = Color(0xFFFF5672);
  static const Color modeGymCardio = Color(0xFFB21235);

  // UI ELEMENT COLORS
  static const Color success = Color(0xFF149BCC);
  static const Color error = Color(0xFFB21235);
  static const Color warning = Color(0xFFFFF66B);
  static const Color info = Color(0xFF0985B2);

  // GRADIENTS
  static const LinearGradient fuelOptimalGradient = LinearGradient(
    colors: [Color(0xFF0985B2), Color(0xFF149BCC)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
  static const LinearGradient fuelWarningGradient = LinearGradient(
    colors: [Color(0xFFFF5672), Color(0xFFFFF66B)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
  static const LinearGradient fuelCriticalGradient = LinearGradient(
    colors: [Color(0xFF8B0000), Color(0xFFB21235)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D1117), Color(0xFF161B22)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFB21235), Color(0xFFFF5672)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF0985B2), Color(0xFF149BCC)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // HELPER METHODS
  static Color getFuelColor(double percentage) {
    if (percentage > 60) return fuelOptimal;
    if (percentage > 30) return fuelWarning;
    return fuelCritical;
  }
  
  static LinearGradient getFuelGradient(double percentage) {
    if (percentage > 60) return fuelOptimalGradient;
    if (percentage > 30) return fuelWarningGradient;
    return fuelCriticalGradient;
  }
  
  static Color getGlowColor(double percentage) {
    if (percentage > 60) return glowCyan;
    if (percentage > 30) return glowYellow;
    return glowRed;
  }

  static Color getActivityModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'sleeping':
        return modeSleeping;
      case 'resting':
        return modeResting;
      case 'coding':
        return modeCoding;
      case 'studying':
        return modeStudying;
      case 'gymstrength':
      case 'gym (strength)':
        return modeGymStrength;
      case 'gymcardio':
      case 'gym (cardio)':
        return modeGymCardio;
      default:
        return primaryBlue;
    }
  }
}
