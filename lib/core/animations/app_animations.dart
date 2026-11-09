import 'package:flutter/material.dart';

/// Central token registry for the Full Animation Spec.
/// Acts as the single source of truth for durations, curves, and accessibility rules.
class AppAnimations {
// --- Durations ---
  static const Duration tabTransition = Duration(milliseconds: 300);
  static const Duration sheetMorph = Duration(milliseconds: 350);
  static const Duration staggerDelay = Duration(milliseconds: 80);
  static const Duration dashboardEntrance = Duration(milliseconds: 800);
  static const Duration buttonScale = Duration(milliseconds: 120);
  static const Duration countUp = Duration(milliseconds: 900);
  static const Duration savePop = Duration(milliseconds: 600);
  static const Duration goalReached = Duration(milliseconds: 1200);
  static const Duration prCelebration = Duration(milliseconds: 1500);
  static const Duration streakBounce = Duration(milliseconds: 700);
  static const Duration validationShake = Duration(milliseconds: 300);
  static const Duration deleteSwipe = Duration(milliseconds: 250);
  static const Duration undoSnackbar = Duration(seconds: 4);

// --- Curves ---
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve easeInOutSine = Curves.easeInOutSine;

  /// Helper to check if system accessibility settings request reduced motion / disabled animations.
  /// Complies with: "honor MediaQuery.disableAnimations (reduced motion)".
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// Safe wrapper for animations that respects reduced-motion accessibility preferences.
  static Duration getDuration(BuildContext context, Duration standardDuration) {
    if (shouldReduceMotion(context)) {
      return Duration.zero;
    }
    return standardDuration;
  }
}
