import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'admin_breakpoints.dart';

/// ثوابت تصميم لوحة الإدارة — توحيد المسافات والعروض
class AdminConstants {
  AdminConstants._();

  /// عرض الشريط الجانبي (ديسكتوب)
  static const double sidebarWidth = 260.0;

  /// أقصى عرض للمحتوى (ديسكتوب) لتحسين القراءة
  static const double contentMaxWidth = 1400.0;

  /// هامش أفقي للصفحة
  static double pagePaddingHorizontal(BuildContext context) {
    return MediaQuery.sizeOf(context).width < AdminBreakpoints.mobileBreakpoint
        ? AppSpacing.md
        : AppSpacing.xl;
  }

  /// هامش عمودي للصفحة
  static double pagePaddingVertical(BuildContext context) {
    return MediaQuery.sizeOf(context).width < AdminBreakpoints.mobileBreakpoint
        ? AppSpacing.md
        : AppSpacing.xl;
  }

  /// هامش الصفحة الموحّد
  static EdgeInsets pagePadding(BuildContext context) {
    final h = pagePaddingHorizontal(context);
    final v = pagePaddingVertical(context);
    return EdgeInsets.fromLTRB(h, v, h, v);
  }

  /// المسافة بين عنوان القسم والمحتوى
  static const double sectionToContentSpacing = 16.0;
}
