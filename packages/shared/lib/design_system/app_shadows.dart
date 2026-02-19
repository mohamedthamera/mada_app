import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  static final card = [
    BoxShadow(
      color: AppColors.background.withValues(alpha: 0.5),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
