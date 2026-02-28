import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'app_typography.dart';

/// Rounded card with soft shadow and padding.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AdminTheme.space24),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AdminTheme.radiusLg),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: child,
    );
  }
}

/// Section header with title and optional actions.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminTheme.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AdminTypography.titleLarge(AdminTheme.textPrimary),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AdminTheme.space4),
                  Text(
                    subtitle!,
                    style: AdminTypography.bodyMedium(AdminTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Primary CTA button.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AdminTheme.primary,
        foregroundColor: AdminTheme.primaryForeground,
        padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space24, vertical: AdminTheme.space12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        ),
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : (icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon!,
                    const SizedBox(width: AdminTheme.space8),
                    Text(label, style: AdminTypography.labelLarge(AdminTheme.primaryForeground)),
                  ],
                )
              : Text(label, style: AdminTypography.labelLarge(AdminTheme.primaryForeground))),
    );
  }
}

/// Secondary / outline button.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminTheme.textSecondary,
        side: const BorderSide(color: AdminTheme.border),
        padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space24, vertical: AdminTheme.space12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        ),
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon!,
                const SizedBox(width: AdminTheme.space8),
                Text(label, style: AdminTypography.labelLarge(AdminTheme.textSecondary)),
              ],
            )
          : Text(label, style: AdminTypography.labelLarge(AdminTheme.textSecondary)),
    );
  }
}

/// Styled text field with label, hint, optional prefix/suffix.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AdminTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.borderFocus, width: 1.5),
        ),
      ),
    );
  }
}

/// Dropdown form field with consistent styling.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AdminTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.border),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

/// Small chip for tags or filters.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onDeleted;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space12, vertical: AdminTheme.space8),
      decoration: BoxDecoration(
        color: selected ? AdminTheme.primary.withValues(alpha: 0.15) : AdminTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: selected ? Border.all(color: AdminTheme.primary.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AdminTypography.labelMedium(selected ? AdminTheme.primary : AdminTheme.textSecondary),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: AdminTheme.space4),
            GestureDetector(
              onTap: onDeleted,
              child: Icon(Icons.close, size: 16, color: AdminTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Status badge (Pending, Completed, etc.).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.status = StatusBadgeType.neutral,
  });

  final String label;
  final StatusBadgeType status;

  static Color _color(StatusBadgeType t) {
    switch (t) {
      case StatusBadgeType.success:
        return AdminTheme.success;
      case StatusBadgeType.warning:
        return AdminTheme.warning;
      case StatusBadgeType.error:
        return AdminTheme.error;
      case StatusBadgeType.neutral:
        return AdminTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space8, vertical: AdminTheme.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
      ),
      child: Text(
        label,
        style: AdminTypography.labelSmall(color),
      ),
    );
  }
}

enum StatusBadgeType { success, warning, error, neutral }

/// Dashed border zone for file upload (modern look).
class AppUploadZone extends StatelessWidget {
  const AppUploadZone({
    super.key,
    required this.onTap,
    this.label = 'اضغط للرفع أو اسحب الملف هنا',
    this.helperText,
    this.icon,
    this.loading = false,
  });

  final VoidCallback onTap;
  final String label;
  final String? helperText;
  final Widget? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AdminTheme.space32, horizontal: AdminTheme.space24),
        decoration: BoxDecoration(
          color: AdminTheme.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          border: Border.all(color: AdminTheme.border, style: BorderStyle.solid, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              icon ?? Icon(Icons.cloud_upload_outlined, size: 40, color: AdminTheme.textMuted),
            const SizedBox(height: AdminTheme.space12),
            Text(
              label,
              style: AdminTypography.bodyMedium(AdminTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (helperText != null) ...[
              const SizedBox(height: AdminTheme.space4),
              Text(
                helperText!,
                style: AdminTypography.bodySmall(AdminTheme.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
