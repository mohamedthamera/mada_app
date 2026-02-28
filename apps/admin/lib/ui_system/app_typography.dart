import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Admin typography using Inter for UI; supports RTL Arabic.
class AdminTypography {
  AdminTypography._();

  static String get fontFamily => 'Inter';
  static String get fontFamilyArabic => 'Cairo';

  static TextTheme textTheme(Color textColor) {
    return TextTheme(
      displayLarge: displayLarge(textColor),
      displayMedium: displayMedium(textColor),
      displaySmall: displaySmall(textColor),
      headlineLarge: headlineLarge(textColor),
      headlineMedium: headlineMedium(textColor),
      headlineSmall: headlineSmall(textColor),
      titleLarge: titleLarge(textColor),
      titleMedium: titleMedium(textColor),
      titleSmall: titleSmall(textColor),
      bodyLarge: bodyLarge(textColor),
      bodyMedium: bodyMedium(textColor),
      bodySmall: bodySmall(textColor),
      labelLarge: labelLarge(textColor),
      labelMedium: labelMedium(textColor),
      labelSmall: labelSmall(textColor),
    );
  }

  static TextStyle displayLarge(Color color) =>
      GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: color);
  static TextStyle displayMedium(Color color) =>
      GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: color);
  static TextStyle displaySmall(Color color) =>
      GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: color);

  static TextStyle headlineLarge(Color color) =>
      GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: color);
  static TextStyle headlineMedium(Color color) =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: color);
  static TextStyle headlineSmall(Color color) =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: color);

  static TextStyle titleLarge(Color color) =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: color);
  static TextStyle titleMedium(Color color) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: color);
  static TextStyle titleSmall(Color color) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: color);

  static TextStyle bodyLarge(Color color) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: color);
  static TextStyle bodyMedium(Color color) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: color);
  static TextStyle bodySmall(Color color) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  static TextStyle labelLarge(Color color) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: color);
  static TextStyle labelMedium(Color color) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: color);
  static TextStyle labelSmall(Color color) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: color);

  /// For Arabic titles in RTL layout
  static TextStyle titleLargeAr(Color color) =>
      GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600, color: color);
  static TextStyle bodyMediumAr(Color color) =>
      GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w400, color: color);
}
