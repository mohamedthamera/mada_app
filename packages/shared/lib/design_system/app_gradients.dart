import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  static final primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
