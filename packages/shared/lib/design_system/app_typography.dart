import 'package:flutter/material.dart';

class AppTypography {
  static const fontFamilyArabic = 'Cairo';
  static const fontFamilyEnglish = 'Inter';

  static TextTheme textTheme(Color color) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 26,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: color,
        fontFamily: fontFamilyArabic,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: color,
        fontFamily: fontFamilyArabic,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: color,
        fontFamily: fontFamilyArabic,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: color,
        fontFamily: fontFamilyArabic,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: color,
        fontFamily: fontFamilyArabic,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: color,
        fontFamily: fontFamilyArabic,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: color,
        fontFamily: fontFamilyArabic,
      ),
    );
  }
}

