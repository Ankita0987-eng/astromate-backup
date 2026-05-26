import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Cosmic palette
  static const Color cosmicBlack = Color(0xFF0A0A12);
  static const Color deepSpace = Color(0xFF12121F);
  static const Color nebulaPurple = Color(0xFF6B4EFF);
  static const Color stellarPink = Color(0xFFFF6B9D);
  static const Color auroraBlue = Color(0xFF4ECDC4);
  static const Color starGold = Color(0xFFFFD93D);
  static const Color moonSilver = Color(0xFFB8B8D1);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  static const LinearGradient cosmicGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [nebulaPurple, stellarPink, auroraBlue],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF6B9D), Color(0xFF6B4EFF)],
  );

  // Light mode
  static const Color lightBackground = Color(0xFFF5F3FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF5B3FD4);
}
