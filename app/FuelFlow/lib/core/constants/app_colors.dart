import 'package:flutter/material.dart';

/// FuelFlow Neon Theme Color Palette
/// A futuristic, cyberpunk-inspired color scheme optimized for dark backgrounds
class AppColors {
  AppColors._();

  // ============================================
  // BASE COLORS
  // ============================================
  
  /// Primary background - Deep charcoal black
  static const Color background = Color(0xFF0D0D12);
  
  /// Secondary background - Slightly lighter for cards/panels
  static const Color surface = Color(0xFF1A1A24);
  
  /// Elevated surface - For floating elements
  static const Color surfaceElevated = Color(0xFF252532);
  
  /// Border color for glass-morphism effects
  static const Color border = Color(0xFF2A2A3C);

  // ============================================
  // FUEL/ENERGY STATE COLORS (The Core)
  // ============================================
  
  /// Optimal state (>60%) - Neon Electric Green
  static const Color fuelOptimal = Color(0xFF00FF66);
  
  /// Warning state (30-60%) - Cyberpunk Yellow
  static const Color fuelWarning = Color(0xFFFFEA00);
  
  /// Critical state (<30%) - Alarm Red
  static const Color fuelCritical = Color(0xFFFF003C);
  
  /// Empty/Depleted state - Faded grey
  static const Color fuelDepleted = Color(0xFF4A4A5C);

  // ============================================
  // GLOW COLORS (For neon effects)
  // ============================================
  
  static const Color glowGreen = Color(0xFF00FF66);
  static const Color glowYellow = Color(0xFFFFEA00);
  static const Color glowRed = Color(0xFFFF003C);
  static const Color glowCyan = Color(0xFF00F5FF);
  static const Color glowPurple = Color(0xFF9D4EDD);

  // ============================================
  // TEXT COLORS
  // ============================================
  
  /// Primary text - High contrast white
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  /// Secondary text - Muted grey
  static const Color textSecondary = Color(0xFFB0B0C0);
  
  /// Tertiary text - Low emphasis
  static const Color textTertiary = Color(0xFF6A6A7C);
  
  /// Accent text - Cyan highlight
  static const Color textAccent = Color(0xFF00F5FF);

  // ============================================
  // ACTIVITY MODE COLORS
  // ============================================
  
  /// Resting mode - Calm blue
  static const Color modeResting = Color(0xFF4A90D9);
  
  /// Coding mode - Electric purple
  static const Color modeCoding = Color(0xFF9D4EDD);
  
  /// Studying mode - Intense orange
  static const Color modeStudying = Color(0xFFFF8C00);
  
  /// Gym Strength - Power red
  static const Color modeGymStrength = Color(0xFFFF4757);
  
  /// Gym Cardio - Energy magenta
  static const Color modeGymCardio = Color(0xFFFF006E);

  // ============================================
  // UI ELEMENT COLORS
  // ============================================
  
  /// Primary accent - Cyan
  static const Color primary = Color(0xFF00F5FF);
  
  /// Secondary accent - Purple
  static const Color secondary = Color(0xFF9D4EDD);
  
  /// Success state
  static const Color success = Color(0xFF00FF66);
  
  /// Error state
  static const Color error = Color(0xFFFF003C);
  
  /// Warning state
  static const Color warning = Color(0xFFFFEA00);

  // ============================================
  // GRADIENT DEFINITIONS
  // ============================================
  
  /// Optimal fuel gradient
  static const LinearGradient fuelOptimalGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF00FF66),
      Color(0xFF00CC52),
    ],
  );
  
  /// Warning fuel gradient
  static const LinearGradient fuelWarningGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFEA00),
      Color(0xFFFFBB00),
    ],
  );
  
  /// Critical fuel gradient
  static const LinearGradient fuelCriticalGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFF003C),
      Color(0xFFCC0030),
    ],
  );

  /// Background gradient for main screen
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D0D12),
      Color(0xFF151520),
      Color(0xFF0D0D12),
    ],
  );

  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Get fuel color based on percentage
  static Color getFuelColor(double percentage) {
    if (percentage > 60) return fuelOptimal;
    if (percentage > 30) return fuelWarning;
    if (percentage > 0) return fuelCritical;
    return fuelDepleted;
  }
  
  /// Get fuel gradient based on percentage
  static LinearGradient getFuelGradient(double percentage) {
    if (percentage > 60) return fuelOptimalGradient;
    if (percentage > 30) return fuelWarningGradient;
    return fuelCriticalGradient;
  }
  
  /// Get glow color based on percentage
  static Color getGlowColor(double percentage) {
    if (percentage > 60) return glowGreen;
    if (percentage > 30) return glowYellow;
    return glowRed;
  }

  /// Get activity mode color
  static Color getActivityModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'resting':
        return modeResting;
      case 'coding':
        return modeCoding;
      case 'studying':
        return modeStudying;
      case 'gym_strength':
      case 'gym (strength)':
        return modeGymStrength;
      case 'gym_cardio':
      case 'gym (cardio)':
        return modeGymCardio;
      default:
        return modeResting;
    }
  }
}
