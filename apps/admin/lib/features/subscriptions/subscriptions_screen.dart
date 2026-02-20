import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'presentation/admin_subscriptions_providers.dart';
import '../../core/constants/admin_breakpoints.dart';
import '../../core/widgets/admin_widgets.dart';
import 'admin_generate_codes.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(adminSubscriptionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: adminAppBarLeading(context),
        title: const Text('الاشتراكات'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(adminSubscriptionsProvider),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          AdminBreakpoints.isMobile(context) ? AppSpacing.md : AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminGenerateCodes(),
            const SizedBox(height: AppSpacing.xl),
            AdminSectionHeader(
              title: 'قائمة المستخدمين المشتركين',
              subtitle: 'المستخدمون الذين لديهم اشتراك فعّال في المنصة',
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 600,
              child: subscriptionsAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return AdminCard(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.subscriptions_outlined,
                              size: 64,
                              color: AppColors.textMuted.withValues(alpha:0.6),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'لا يوجد مستخدمون مشتركون بعد',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'ستظهر هنا قائمة المستخدمين عند تفعيل اشتراكهم (كود أو بوابة دفع)',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return AdminCard(
                    padding: EdgeInsets.zero,
                    child: DataTable2(
                      columnSpacing: AppSpacing.lg,
                      horizontalMargin: AppSpacing.lg,
                      minWidth: 700,
                      columns: const [
                        DataColumn2(
                          label: Text('الاسم'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: Text('البريد'),
                          size: ColumnSize.L,
                        ),
                        DataColumn2(
                          label: Text('نوع الاشتراك'),
                          size: ColumnSize.S,
                        ),
                        DataColumn2(
                          label: Text('المصدر'),
                          size: ColumnSize.S,
                        ),
                        DataColumn2(
                          label: Text('تاريخ التفعيل'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: Text('تاريخ الإنشاء'),
                          size: ColumnSize.M,
                        ),
                      ],
                      rows: list
                          .map(
                            (row) => DataRow2(
                              cells: [
                                DataCell(Text(
                                  (row['name'] as String?) ?? '—',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                )),
                                DataCell(Text(
                                  (row['email'] as String?) ?? '—',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                )),
                                DataCell(_TypeChip(
                                  isLifetime: row['isLifetime'] == true,
                                )),
                                DataCell(Text(
                                  (row['source'] as String?) ?? '—',
                                  style: const TextStyle(fontSize: 12),
                                )),
                                DataCell(Text(_formatDate(row['activatedAt'] as DateTime?))),
                                DataCell(Text(_formatDate(row['createdAt'] as DateTime?))),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'تعذر تحميل الاشتراكات',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                        child: Text(
                          '$e',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(adminSubscriptionsProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 20),
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

  static String _shortId(String? id) {
    if (id == null || id.length < 8) return '—';
    return '${id.substring(0, 8)}...';
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.isLifetime});

  final bool isLifetime;

  @override
  Widget build(BuildContext context) {
    final text = isLifetime ? 'مدى الحياة' : 'عادي';
    final bg = isLifetime
        ? AppColors.primary.withValues(alpha: 0.2)
        : AppColors.textMuted.withValues(alpha: 0.2);
    final fg = isLifetime ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
