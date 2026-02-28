import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui_system/app_theme.dart';
import '../ui_system/app_typography.dart';
import '../core/constants/admin_breakpoints.dart';
import '../core/widgets/admin_widgets.dart';

final GlobalKey<ScaffoldState> _shellScaffoldKey = GlobalKey<ScaffoldState>();

class AdminShellLayout extends StatelessWidget {
  const AdminShellLayout({super.key, required this.child});

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
  ];

  static const _iconsSelected = [
    Icons.dashboard_rounded,
    Icons.menu_book_rounded,
    Icons.people_rounded,
    Icons.work_rounded,
    Icons.auto_stories_rounded,
    Icons.analytics_rounded,
    Icons.subscriptions_rounded,
    Icons.image_rounded,
    Icons.card_giftcard_rounded,
  ];

  Widget _buildNavItem(BuildContext context, int i, int currentIndex, VoidCallback? onTap) {
    final selected = currentIndex == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onTap?.call();
            context.go(_routes[i]);
          },
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space16, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? _iconsSelected[i] : _icons[i],
                  size: 22,
                  color: selected ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: AdminTheme.space12),
                Expanded(
                  child: Text(
                    _labels[i],
                    style: AdminTypography.bodyMedium(selected ? Colors.white : Colors.white70).copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, int currentIndex, VoidCallback? onNavTap) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AdminTheme.primaryDark,
            AdminTheme.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AdminTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AdminTheme.space24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space16),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: AdminTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'لوحة الإدارة',
                          style: AdminTypography.titleSmall(Colors.white),
                        ),
                        Text(
                          'Mada',
                          style: AdminTypography.bodySmall(Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AdminTheme.space24),
            const Divider(height: 1, color: Colors.white24),
            const SizedBox(height: AdminTheme.space12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space12, vertical: AdminTheme.space8),
                children: List.generate(_routes.length, (i) => _buildNavItem(context, i, currentIndex, onNavTap)),
              ),
            ),
          ],
        ),
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
        key: isMobile ? _shellScaffoldKey : null,
        backgroundColor: AdminTheme.background,
        drawer: isMobile
            ? Drawer(
                backgroundColor: AdminTheme.surface,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AdminTheme.space24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space16),
                        child: Row(
                          children: [
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                color: AdminTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                              ),
                              child: const Icon(Icons.school_rounded, color: AdminTheme.primary, size: 24),
                            ),
                            const SizedBox(width: AdminTheme.space12),
                            Text('لوحة الإدارة', style: AdminTypography.titleSmall(AdminTheme.textPrimary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AdminTheme.space16),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          children: List.generate(
                            _routes.length,
                            (i) => _buildNavItem(context, i, currentIndex, () => Navigator.of(context).pop()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        body: isMobile
            ? AdminDrawerScope(
                openDrawer: () => _shellScaffoldKey.currentState?.openDrawer(),
                child: ColoredBox(color: AdminTheme.background, child: child),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSidebar(context, currentIndex, null),
                  Expanded(child: ColoredBox(color: AdminTheme.background, child: child)),
                ],
              ),
      ),
    );
  }
}
