import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../../core/widgets/widgets.dart';
import '../../offline/data/offline_repository.dart';
import '../data/progress_repository.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  static const _achievements = [
    _Achievement('أول خطوة', 'أكملت 10٪ من شاهداتك الأولى', 10, '🚀'),
    _Achievement('متعطش للتعلم', 'أكملت 25٪ من دروسك', 25, '📚'),
    _Achievement('نصف الطريق', 'وصلت إلى 50٪ من التقدم', 50, '🏃‍♂️'),
    _Achievement('قريب من القمة', 'تجاوزت 75٪ من التقدم', 75, '⛰️'),
    _Achievement('بطل الإنهاء', 'أكملت 100٪ من دروسك', 100, '🏆'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.read(offlineRepositoryProvider);
    final all = offline.getAllProgress();
    final progress = all.isEmpty
        ? 0.0
        : (all.values.reduce((a, b) => a + b) / all.length).clamp(0.0, 100.0);
    final unlockedCount =
        _achievements.where((a) => progress >= a.threshold).length;
    final statsAsync = ref.watch(progressStatsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('التقدم', style: AppTextStyle.title),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              statsAsync.when(
                data: (stats) => _buildStatsCard(context, stats),
                loading: () => _buildStatsCard(
                  context,
                  const ProgressStats(lessonsCompleted: 0, coursesWithProgress: 0),
                ),
                error: (_, __) => _buildStatsCard(
                  context,
                  const ProgressStats(lessonsCompleted: 0, coursesWithProgress: 0),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildProgressHero(context, progress),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'الإنجازات'),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                unlockedCount == 0
                    ? 'ابدأ مشاهدة الدروس لتحصل على أول شارة'
                    : 'لديك $unlockedCount من ${_achievements.length} إنجازات محققة',
                style: AppTextStyle.caption,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              ..._achievements.map((a) => _buildAchievementCard(a, progress)),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, ProgressStats stats) {
    final hasAny = stats.lessonsCompleted > 0 || stats.coursesWithProgress > 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: AppText('ملخص تقدمك', style: AppTextStyle.title),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!hasAny) ...[
            AppText(
              'لم تشاهد أي دروس بعد.',
              style: AppTextStyle.body,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'اذهب إلى الدورات وابدأ بمشاهدة الدروس ليتحقق تقدمك هنا.',
              style: AppTextStyle.caption,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => context.go('/courses'),
              icon: const Icon(Icons.menu_book_rounded, size: 20),
              label: const Text('عرض الدورات'),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    context,
                    value: '${stats.lessonsCompleted}',
                    label: 'دروس مكتملة',
                    icon: Icons.play_circle_filled_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatChip(
                    context,
                    value: '${stats.coursesWithProgress}',
                    label: 'دورات فيها تقدم',
                    icon: Icons.library_books_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              'الدروس المكتملة = دروس شاهدتها بنسبة 100٪. الدورات = عدد الدورات التي بدأت بمشاهدة دروسها.',
              style: AppTextStyle.caption,
              color: AppColors.textMuted,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 2),
          AppText(label, style: AppTextStyle.caption, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildProgressHero(BuildContext context, double progress) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha:0.18),
            AppColors.primary.withValues(alpha:0.08),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha:0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Icons.trending_up_rounded,
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
                      'نسبة التقدم الإجمالية',
                      style: AppTextStyle.title,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      'استمر بالمشاهدة لفتح المزيد من الإنجازات',
                      style: AppTextStyle.caption,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${progress.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.1,
                    ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, right: 4),
                child: AppText(
                  '%',
                  style: AppTextStyle.title,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 10,
              backgroundColor: AppColors.primary.withValues(alpha:0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(_Achievement a, double progress) {
    final unlocked = progress >= a.threshold;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.primary.withValues(alpha:0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: unlocked
              ? AppColors.primary.withValues(alpha:0.35)
              : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          if (unlocked)
            BoxShadow(
              color: AppColors.primary.withValues(alpha:0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.primary.withValues(alpha:0.12)
                  : AppColors.border.withValues(alpha:0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              a.emoji,
              style: TextStyle(
                fontSize: 26,
                color: unlocked ? null : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  a.title,
                  style: AppTextStyle.title,
                  color: unlocked ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(height: 4),
                AppText(
                  a.description,
                  style: AppTextStyle.caption,
                  color: AppColors.textSecondary,
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      AppText(
                        '${a.threshold.toInt()}% للفتح',
                        style: AppTextStyle.caption,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (unlocked)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 28,
            ),
        ],
      ),
    );
  }
}

class _Achievement {
  const _Achievement(this.title, this.description, this.threshold, this.emoji);

  final String title;
  final String description;
  final double threshold;
  final String emoji;
}
