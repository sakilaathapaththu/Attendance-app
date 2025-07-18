import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF2E86AB);
  static const Color secondaryColor = Color(0xFF3A9BC1);
  static const Color accentTeal = Color(0xFF4ECDC4);
  static const Color darkBlue = Color(0xFF1A2238);
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color mediumGray = Color(0xFFE9ECEF);
  static const Color darkGray = Color(0xFF6C757D);
  static const Color successGreen = Color(0xFF28A745);
  static const Color warningOrange = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFDC3545);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentTeal, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
