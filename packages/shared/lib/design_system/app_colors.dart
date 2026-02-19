import 'package:flutter/material.dart';

/// Dark mode fitness color palette. All app colors reference this single source.
class AppColors {
  // Primary / Accent — CTA buttons, active states, progress bars, highlights
  static const primary = Color(0xFF86F71D);
  static const primaryForeground = Color(0xFF15161A);

  // Backgrounds
  static const background = Color(0xFF15161A);
  static const surface = Color(0xFF2D2D31);
  static const card = Color(0xFF2D2D31);

  // Text hierarchy
  static const textPrimary = Color(0xFFDEDEE0);
  static const textSecondary = Color(0xFFB9B9BD);
  static const textMuted = Color(0xFF98968A);

  // UI details
  static const border = Color(0xFF555549);
  static const borderSecondary = Color(0xFF767468);
  static const input = Color(0xFF2D2D31);
  static const ring = Color(0xFF86F71D);

  // Semantic (fitness dark palette–friendly)
  static const success = Color(0xFF86F71D);
  static const warning = Color(0xFF86F71D);
  static const danger = Color(0xFFDC2626);

  // Aliases for theme/component compatibility
  static const accent = primary;
  static const accentForeground = primaryForeground;
  static const secondary = surface;
  static const secondaryForeground = textSecondary;
  static const muted = surface;
  static const mutedForeground = textMuted;
}
