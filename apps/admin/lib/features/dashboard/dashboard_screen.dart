import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared/shared.dart';
import '../analytics/presentation/admin_analytics_providers.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../ui_system/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardCountsProvider);
    return Scaffold(
      backgroundColor: AdminTheme.background,
      appBar: AppBar(
        leading: adminAppBarLeading(context),
        title: const Text('نظرة عامة'),
        backgroundColor: AdminTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(adminDashboardCountsProvider),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: AdminPageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionHeader(
              title: 'ملخص الأداء',
              subtitle: 'بيانات حقيقية من المنصة',
              trailing: dashboardAsync.when(
                data: (_) => Text(
                  'آخر تحديث: ${_timeNow()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AdminTheme.textMuted,
                  ),
                ),
                loading: () => Text(
                  'جاري التحميل...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AdminTheme.textMuted,
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: dashboardAsync.when(
                data: (data) {
                  final registered = data['registered_users'] as int? ?? 0;
                  final subscribed = data['subscribed_users'] as int? ?? 0;
                  final courses = data['courses'] as int? ?? 0;
                  final enrollments = data['enrollments'] as int? ?? 0;
                  final rate = data['completion_rate'] as double? ?? 0.0;
                      return LayoutBuilder(
                    builder: (context, constraints) {
                      final crossCount = constraints.maxWidth > 900 ? 5 : (constraints.maxWidth > 700 ? 3 : 2);
                      final cards = [
                        _KpiCard(
                          title: 'المستخدمون المسجلون',
                          value: '$registered',
                          subtitle: 'سجّلوا في التطبيق',
                          icon: Icons.person_add_rounded,
                          color: AdminTheme.primary,
                        ),
                        _KpiCard(
                          title: 'المستخدمون المشتركون',
                          value: '$subscribed',
                          subtitle: 'لديهم اشتراك فعّال',
                          icon: Icons.card_membership_rounded,
                          color: const Color(0xFF6366F1),
                        ),
                        _KpiCard(
                          title: 'الدورات',
                          value: '$courses',
                          subtitle: 'دورات متاحة',
                          icon: Icons.menu_book_rounded,
                          color: const Color(0xFF0EA5E9),
                        ),
                        _KpiCard(
                          title: 'اشتراكات الدورات',
                          value: '$enrollments',
                          subtitle: 'تسجيل في دورات',
                          icon: Icons.school_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        _KpiCard(
                          title: 'معدل الإكمال',
                          value: '${rate.toStringAsFixed(1)}%',
                          subtitle: 'أكملوا دورة بالكامل',
                          icon: Icons.trending_up_rounded,
                          color: AdminTheme.success,
                        ),
                      ];
                      return GridView.count(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: AdminTheme.space24,
                        mainAxisSpacing: AdminTheme.space24,
                        childAspectRatio: 1.35,
                        children: [
                          for (var i = 0; i < cards.length; i++)
                            cards[i].animate(delay: (i * 80).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: AdminTheme.textMuted),
                      const SizedBox(height: AdminTheme.space16),
                      Text(
                        'تعذر تحميل البيانات',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AdminTheme.textSecondary),
                      ),
                      const SizedBox(height: AdminTheme.space8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space24),
                        child: Text(
                          '$e',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminTheme.textMuted),
                        ),
                      ),
                      const SizedBox(height: AdminTheme.space24),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(adminDashboardCountsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(AdminTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AdminTheme.space8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AdminTheme.space8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AdminTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AdminTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AdminTheme.space4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AdminTheme.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
