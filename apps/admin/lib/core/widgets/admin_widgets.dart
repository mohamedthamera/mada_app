import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../constants/admin_breakpoints.dart';
import '../constants/admin_constants.dart';

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

/// تخطيط موحّد لمحتوى الصفحة: هامش + أقصى عرض + محاذاة
class AdminPageBody extends StatelessWidget {
  const AdminPageBody({
    super.key,
    required this.child,
    this.maxWidth = true,
  });

  final Widget child;
  final bool maxWidth;

  @override
  Widget build(BuildContext context) {
    final padding = AdminConstants.pagePadding(context);
    return Padding(
      padding: padding,
      child: (maxWidth && AdminBreakpoints.isDesktop(context))
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AdminConstants.contentMaxWidth),
                child: child,
              ),
            )
          : child,
    );
  }
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
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// قسم منظم في النماذج (عنوان + حقول) لتصميم بسيط وسلس
class AdminFormSection extends StatelessWidget {
  const AdminFormSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    );
  }
}

/// تباعد موحّد بين حقول النماذج
const double adminFormFieldSpacing = 14.0;

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
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminConstants.sectionToContentSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
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
