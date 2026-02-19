import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static const _routes = [
    '/dashboard',
    '/courses',
    '/users',
    '/jobs',
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
    Icons.analytics_outlined,
    Icons.subscriptions_outlined,
    Icons.image_outlined,
    Icons.card_giftcard_outlined,
  ];

  static const _iconsSelected = [
    Icons.dashboard,
    Icons.menu_book,
    Icons.people,
    Icons.work,
    Icons.analytics,
    Icons.subscriptions,
    Icons.image,
    Icons.card_giftcard,
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _routes.indexWhere((r) => location.startsWith(r));
    final currentIndex = index == -1 ? 0 : index;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  left: BorderSide(color: AppColors.border.withValues(alpha:0.5), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.15),
                    blurRadius: 8,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: SafeArea(
                right: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha:0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.school_rounded, color: AppColors.primaryForeground, size: 26),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'لوحة الإدارة',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Everest',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        children: List.generate(_routes.length, (i) {
                          final selected = currentIndex == i;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => context.go(_routes[i]),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary.withValues(alpha:0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    border: selected
                                        ? Border.all(color: AppColors.primary.withValues(alpha:0.4), width: 1)
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        selected ? _iconsSelected[i] : _icons[i],
                                        size: 22,
                                        color: selected ? AppColors.primary : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Text(
                                          _labels[i],
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: selected ? AppColors.primary : AppColors.textSecondary,
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
                        }),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
