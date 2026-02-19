import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'app_text.dart';

enum AppButtonVariant { primary, secondary, outline }
enum AppButtonSize { md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.lg,
    this.icon,
    this.fullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool fullWidth;
  /// لون خلفية مخصص (يتجاوز الـ variant عند التعيين)
  final Color? backgroundColor;
  /// لون النص/الأيقونة (يتجاوز الافتراضي عند التعيين)
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final height = size == AppButtonSize.lg ? 52.0 : 44.0;
    final radius = BorderRadius.circular(AppRadius.lg);
    final isOutline = variant == AppButtonVariant.outline;
    final gradient = backgroundColor == null && variant == AppButtonVariant.primary
        ? AppGradients.primary
        : null;
    final bgColor = backgroundColor ??
        (variant == AppButtonVariant.secondary ? AppColors.surface : Colors.transparent);
    final textColor = foregroundColor ??
        (isOutline ? AppColors.primary : (gradient != null ? AppColors.primaryForeground : AppColors.textPrimary));

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? bgColor : null,
              borderRadius: radius,
              border: isOutline
                  ? Border.all(color: AppColors.primary, width: 1)
                  : null,
              boxShadow: variant == AppButtonVariant.primary
                  ? AppShadows.card
                  : null,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  AppText(
                    label,
                    style: AppTextStyle.body,
                    color: textColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

