import 'package:flutter/material.dart';

/// FuelFlow color palette — Clean Clinical Precision with Warm Energy Accents.
class AppColors {
  AppColors._();

  // PRIMARY THEME COLORS
  static const Color primary = Color(0xFFF97316);       // Orange — primary accent
  static const Color secondary = Color(0xFFF97316);     // Same orange for consistency
  static const Color accent = Color(0xFFF97316);        // Orange accent
  static const Color primaryBlue = Color(0xFFF97316);   // Mapped to accent (no blue in new palette)
  static const Color darkBlue = Color(0xFFEA580C);      // Darker orange variant

  // BASE COLORS
  static const Color background = Color(0xFFFAFAFA);    // Off-white
  static const Color surface = Color(0xFFFFFFFF);        // Pure white
  static const Color surfaceElevated = Color(0xFFF4F4F4); // Surface raised
  static const Color border = Color(0xFFE8E8E8);         // Clinical border

  // STATUS COLORS - Fuel Levels
  static const Color fuelOptimal = Color(0xFF16A34A);    // Green — optimal
  static const Color fuelWarning = Color(0xFFFBBF24);    // Amber — warning
  static const Color fuelCritical = Color(0xFFDC2626);   // Red — critical
  static const Color fuelDepleted = Color(0xFFAAAAAA);   // Muted gray

  // SUPPORT COLORS
  static const Color glowGreen = Color(0xFF16A34A);
  static const Color glowYellow = Color(0xFFFBBF24);
  static const Color glowRed = Color(0xFFDC2626);
  static const Color glowCyan = Color(0xFF16A34A);
  static const Color glowPurple = Color(0xFFF97316);

  // TEXT COLORS
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFFAAAAAA);
  static const Color textAccent = Color(0xFFF97316);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ACTIVITY MODE COLORS
  static const Color modeSleeping = Color(0xFFAAAAAA);
  static const Color modeResting = Color(0xFF16A34A);
  static const Color modeCoding = Color(0xFFF97316);
  static const Color modeStudying = Color(0xFFFBBF24);
  static const Color modeGymStrength = Color(0xFFDC2626);
  static const Color modeGymCardio = Color(0xFFDC2626);

  // UI ELEMENT COLORS
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFFF97316);

  // GRADIENTS (minimal — guidelines prefer flat, but kept for compatibility)
  static const LinearGradient fuelOptimalGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
  static const LinearGradient fuelWarningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
  static const LinearGradient fuelCriticalGradient = LinearGradient(
    colors: [Color(0xFFB91C1C), Color(0xFFDC2626)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFAFAFA), Color(0xFFFAFAFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFFB923C)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFFB923C)],
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
    if (percentage > 60) return glowGreen;
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
        return primary;
    }
  }
}
