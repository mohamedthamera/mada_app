import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../constants/admin_breakpoints.dart';

/// يوفر للم شاشات الأدمن إمكانية فتح الدرج على الموبايل
class AdminDrawerScope extends InheritedWidget {
  const AdminDrawerScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static AdminDrawerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdminDrawerScope>();
  }

  @override
  bool updateShouldNotify(AdminDrawerScope oldWidget) =>
      oldWidget.openDrawer != openDrawer;
}

/// زر القائمة لفتح الدرج (يُعرض على الموبايل فقط)
Widget adminAppBarLeading(BuildContext context) {
  final scope = AdminDrawerScope.maybeOf(context);
  if (scope == null || !AdminBreakpoints.isMobile(context)) return const SizedBox.shrink();
  return IconButton(
    icon: const Icon(Icons.menu_rounded),
    onPressed: scope.openDrawer,
    tooltip: 'القائمة',
  );
}

class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border.withValues(alpha:0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
