import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'presentation/admin_analytics_providers.dart';
import '../../core/widgets/admin_widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التحليلات')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ref.watch(adminCountsProvider).when(
                data: (counts) => Column(
                  children: [
                    AdminSectionHeader(
                      title: 'نظرة تحليلية',
                      trailing: Text(
                        'آخر 30 يوماً',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AdminCard(
                            child: Column(
                              children: [
                                const Text('عدد الدورات'),
                                Text('${counts['courses']}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AdminCard(
                            child: Column(
                              children: [
                                const Text('عدد المستخدمين'),
                                Text('${counts['users']}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AdminCard(
                            child: Column(
                              children: [
                                const Text('الاشتراكات'),
                                Text('${counts['enrollments']}'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: ref.watch(adminEnrollmentsPerDayProvider).when(
                            data: (perDay) {
                              if (perDay.isEmpty || perDay.every((v) => v == 0)) {
                                return AdminCard(
                                  child: Center(
                                    child: Text(
                                      'لا توجد اشتراكات في آخر 30 يوماً',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                );
                              }
                              final spots = perDay
                                  .asMap()
                                  .entries
                                  .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                                  .toList();
                              return AdminCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الاشتراكات خلال آخر 30 يوماً',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: LineChart(
                                          LineChartData(
                                            titlesData: const FlTitlesData(show: false),
                                            borderData: FlBorderData(show: false),
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: spots,
                                                isCurved: true,
                                                barWidth: 2,
                                                dotData: const FlDotData(show: false),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loading: () => const AdminCard(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => AdminCard(
                              child: Center(child: Text('خطأ: $e')),
                            ),
                          ),
                    ),
                  ],
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('تعذر تحميل التحليلات: $e')),
              ),
        ),
      ),
    );
  }
}

