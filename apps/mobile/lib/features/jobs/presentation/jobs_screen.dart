import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../../core/widgets/widgets.dart';
import '../data/job.dart';
import 'jobs_providers.dart';
import 'widgets/job_card.dart';
import '../../subscription/presentation/subscription_providers.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  String _query = '';
  String _typeFilter = 'الكل';

  static const _typeFilters = ['الكل', 'دوام كامل', 'دوام جزئي', 'تدريب'];

  bool _matchesFilter(Job job) {
    if (_typeFilter == 'الكل') return true;
    return job.jobTypeLabel == _typeFilter;
  }

  bool _matchesSearch(Job job) {
    if (_query.isEmpty) return true;
    final q = _query.trim().toLowerCase();
    return job.titleAr.toLowerCase().contains(q) ||
        job.companyName.toLowerCase().contains(q) ||
        job.location.toLowerCase().contains(q);
  }

  void _showJobDetail(BuildContext context, Job job) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.work_outline_rounded,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(job.titleAr, style: AppTextStyle.headline),
                          const SizedBox(height: 4),
                          AppText(
                            job.companyName,
                            style: AppTextStyle.body,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.border.withValues(alpha:0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('معلومات الوظيفة', [
                        _detailRow(Icons.location_on_outlined, 'الموقع', job.location),
                        _detailRow(Icons.schedule_outlined, 'نوع الوظيفة', job.jobTypeLabel),
                        if ((job.workModeLabel ?? '').isNotEmpty)
                          _detailRow(Icons.apartment_outlined, 'طبيعة الدوام', job.workModeLabel!),
                        if ((job.salary ?? '').isNotEmpty)
                          _detailRow(Icons.payments_outlined, 'الراتب', job.salary!),
                        if ((job.workDays ?? '').isNotEmpty)
                          _detailRow(Icons.calendar_today_outlined, 'أيام العمل', job.workDays!),
                      ]),
                      _buildDetailSection('الوصف', [
                        AppText(
                          job.descriptionAr,
                          style: AppTextStyle.body,
                          color: AppColors.textSecondary,
                        ),
                      ]),
                      if ((job.requirements ?? '').isNotEmpty)
                        _buildDetailSection('المتطلبات والخبرات', [
                          AppText(
                            job.requirements!,
                            style: AppTextStyle.body,
                            color: AppColors.textSecondary,
                          ),
                        ]),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppText(title, style: AppTextStyle.title),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary.withValues(alpha:0.8)),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 100,
            child: AppText(
              '$label:',
              style: AppTextStyle.body,
              color: AppColors.textMuted,
            ),
          ),
          Expanded(
            child: AppText(value, style: AppTextStyle.body),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppText(
              'صفحة الوظائف للمشتركين',
              style: AppTextStyle.title,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              'اشترك الآن لتصفح الفرص الوظيفية والتقديم عليها',
              style: AppTextStyle.body,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.go('/subscription'),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('الذهاب للاشتراك'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('الوظائف', style: AppTextStyle.title),
        ),
        body: ref.watch(jobsProvider).when(
              data: (jobs) {
                final hasSubAsync = ref.watch(hasActiveSubscriptionProvider);
                return hasSubAsync.when(
                  data: (hasSub) {
                    if (!hasSub) return _buildLockedView(context);
                    final filtered = jobs
                        .where(_matchesFilter)
                        .where(_matchesSearch)
                        .toList();
                    return ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha:0.15),
                                AppColors.primary.withValues(alpha:0.06),
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha:0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha:0.2),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: const Icon(
                                  Icons.work_outline_rounded,
                                  size: 28,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const AppText(
                                      'تصفح الفرص الوظيفية',
                                      style: AppTextStyle.title,
                                    ),
                                    const SizedBox(height: 4),
                                    AppText(
                                      '${jobs.length} فرصة متاحة',
                                      style: AppTextStyle.body,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        InputField(
                          hintText: 'ابحث بالوظيفة أو الشركة أو المدينة...',
                          prefixIcon: Icons.search_rounded,
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _typeFilters
                              .map(
                                (t) => FilterChip(
                                  label: Text(t),
                                  selected: _typeFilter == t,
                                  onSelected: (_) =>
                                      setState(() => _typeFilter = t),
                                  selectedColor: AppColors.primary.withValues(alpha:0.2),
                                  checkmarkColor: AppColors.primary,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (filtered.isEmpty)
                          AppCard(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 48,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    AppText(
                                      'لا توجد نتائج تطابق البحث',
                                      style: AppTextStyle.body,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ...filtered.map(
                            (job) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: JobCard(
                                job: job,
                                onTap: () => _showJobDetail(context, job),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _buildLockedView(context),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        'تعذر تحميل الوظائف',
                        style: AppTextStyle.body,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('$e'),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
