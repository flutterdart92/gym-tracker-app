import 'package:flutter/material.dart';

class AppColors {
  // Brand & Action Colors
  static const Color limeAccent = Color(0xFF84CC16); // Progress & PRs
  static const Color indigoPrimary =
      Color(0xFF4F46E5); // Primary buttons & actions

  // Macro Colors
  static const Color proteinIndigo = Color(0xFF4F46E5);
  static const Color carbsAmber = Color(0xFFF59E0B);
  static const Color fatsPink = Color(0xFFEC4899);

  // Dark Hero Surfaces & Backgrounds
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkHeroCard = Color(0xFF1E293B);
  static const Color cardBorder = Color(0xFF334155);

  // Light Mode Cards & Surfaces
  static const Color lightCardBg = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  // Card Shape (compile-time constant)
  static const BorderRadius cardRadius =
      BorderRadius.all(Radius.circular(14.0));
}
