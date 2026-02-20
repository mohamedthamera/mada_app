import 'package:flutter/material.dart';

class AdminBreakpoints {
  /// أقل من هذا العرض: عرض موبايل (قائمة جانبية drawer)
  static const mobileBreakpoint = 800.0;

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mobileBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= mobileBreakpoint;
  }
}

