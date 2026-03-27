import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../core/constants/admin_breakpoints.dart';
import '../../core/constants/admin_constants.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../ui_system/app_theme.dart';

final GlobalKey<ScaffoldState> _adminShellScaffoldKey =
    GlobalKey<ScaffoldState>();

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static const _routes = [
    '/dashboard',
    '/courses',
    '/users',
    '/jobs',
    '/books',
    '/analytics',
    '/subscriptions',
    '/banners',
    '/influencers',
    '/notifications',
  ];

  static const _labels = [
    'نظرة عامة',
    'الدورات',
    'المستخدمون',
    'الوظائف',
    'الكتب',
    'التحليلات',
    'الاشتراكات',
    'البنرات',
    'أكواد المؤثرين',
    'إرسال إشعار',
  ];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.menu_book_outlined,
    Icons.people_outline,
    Icons.work_outline,
    Icons.auto_stories_outlined,
    Icons.analytics_outlined,
    Icons.subscriptions_outlined,
    Icons.image_outlined,
    Icons.card_giftcard_outlined,
    Icons.notifications_outlined,
  ];

  static const _iconsSelected = [
    Icons.dashboard,
    Icons.menu_book,
    Icons.people,
    Icons.work,
    Icons.auto_stories,
    Icons.analytics,
    Icons.subscriptions,
    Icons.image,
    Icons.card_giftcard,
    Icons.notifications,
  ];

  Widget _buildNavList(
    BuildContext context,
    int currentIndex,
    VoidCallback? onNavTap,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      children: List.generate(_routes.length, (i) {
        final selected = currentIndex == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                onNavTap?.call();
                context.go(_routes[i]);
              },
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AdminTheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  border: selected
                      ? Border.all(
                          color: AdminTheme.primary.withValues(alpha: 0.35),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? _iconsSelected[i] : _icons[i],
                      size: 22,
                      color: selected
                          ? AdminTheme.primary
                          : AdminTheme.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _labels[i],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: selected
                              ? AdminTheme.primary
                              : AdminTheme.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSidebarHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AdminTheme.primary,
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AdminTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AdminTheme.primaryForeground,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'لوحة الإدارة',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.textPrimary,
                  ),
                ),
                Text(
                  'Mada',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AdminTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _routes.indexWhere((r) => location.startsWith(r));
    final currentIndex = index == -1 ? 0 : index;
    final isMobile = AdminBreakpoints.isMobile(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: isMobile ? _adminShellScaffoldKey : null,
        backgroundColor: AdminTheme.background,
        drawer: isMobile
            ? Drawer(
                backgroundColor: AdminTheme.surface,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      _buildSidebarHeader(context),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: _buildNavList(
                          context,
                          currentIndex,
                          () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        body: isMobile
            ? AdminDrawerScope(
                openDrawer: () =>
                    _adminShellScaffoldKey.currentState?.openDrawer(),
                child: ColoredBox(color: AdminTheme.background, child: child),
              )
            : Row(
                children: [
                  Container(
                    width: AdminConstants.sidebarWidth,
                    decoration: BoxDecoration(
                      color: AdminTheme.surface,
                      border: Border(
                        left: BorderSide(color: AdminTheme.border, width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(-1, 0),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      right: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          _buildSidebarHeader(context),
                          const SizedBox(height: AppSpacing.lg),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.sm),
                          Expanded(
                            child: _buildNavList(context, currentIndex, null),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: AdminTheme.background,
                      child: child,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
