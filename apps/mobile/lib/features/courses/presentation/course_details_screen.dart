import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:go_router/go_router.dart';
import 'course_providers.dart';
import 'lesson_providers.dart';
import '../../subscription/presentation/subscription_providers.dart';
import '../../../app/di.dart';
import '../../../core/widgets/widgets.dart';

class CourseDetailsScreen extends ConsumerWidget {
  const CourseDetailsScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(supabaseClientProvider).auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/login?redirect=${Uri.encodeComponent('/courses/$courseId')}');
        }
      });
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: ref.watch(courseProvider(courseId)).when(
              data: (course) {
                final hasSubAsync = ref.watch(hasActiveSubscriptionProvider);
                return hasSubAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  // في حالة فشل التحقق من الاشتراك نعتبر المستخدم غير مشترك
                  // لكن نبقي تفاصيل الدورة والدروس ظاهرة.
                  error: (e, _) =>
                      _buildCourseContent(context, ref, course, false),
                  // دائماً نعرض صفحة تفاصيل الدورة مع قائمة الدروس،
                  // لكنّ فتح الدرس نفسه يُقفل قبل الاشتراك.
                  data: (hasSub) =>
                      _buildCourseContent(context, ref, course, hasSub),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('تعذر تحميل الدورة: $e')),
            ),
      ),
    );
  }

  Widget _buildCourseContent(
    BuildContext context,
    WidgetRef ref,
    Course course,
    bool hasSub,
  ) {
    return ListView(
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                course.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surface,
                  child: const Icon(Icons.image_not_supported, size: 48),
                ),
              ),
            ),
            // تدرج أسفل الصورة لتحسين قراءة النص
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: Material(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(20),
                child: IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/courses');
                    }
                  },
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha:0.95),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 4),
                    AppText(
                      course.ratingAvg.toStringAsFixed(1),
                      style: AppTextStyle.body,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(course.titleAr, style: AppTextStyle.headline),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _DetailChip(
                    icon: Icons.star_rounded,
                    label: '${course.ratingAvg.toStringAsFixed(1)} (${course.ratingCount} تقييم)',
                  ),
                  _DetailChip(
                    icon: Icons.bar_chart_rounded,
                    label: course.level,
                  ),
                  ref.watch(lessonsProvider(courseId)).when(
                    data: (lessons) {
                      final totalSec = lessons.fold<int>(0, (s, l) => s + l.durationSec);
                      final hours = totalSec ~/ 3600;
                      final minutes = (totalSec % 3600) ~/ 60;
                      final durationLabel = hours > 0
                          ? '$hours ساعة ${minutes > 0 ? 'و $minutes دقيقة' : ''}'.trim()
                          : '$minutes دقيقة';
                      return _DetailChip(
                        icon: Icons.schedule_rounded,
                        label: durationLabel,
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  ref.watch(courseEnrollmentsCountProvider(courseId)).when(
                    data: (count) => _DetailChip(
                      icon: Icons.people_rounded,
                      label: '$count طالب',
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppText(
                course.descAr,
                style: AppTextStyle.body,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'ما الذي ستتعلمه'),
              const SizedBox(height: AppSpacing.sm),
              ..._buildWhatYouWillLearn(course.descAr),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'محتوى الدورة'),
              const SizedBox(height: AppSpacing.sm),
              ref.watch(lessonsProvider(courseId)).when(
                    data: (lessons) => AppText(
                      '${lessons.length} درس',
                      style: AppTextStyle.caption,
                      color: AppColors.textSecondary,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
              const SizedBox(height: AppSpacing.sm),
              if (!hasSub)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha:0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.primary.withValues(alpha:0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppText(
                          'الدروس المجانية متاحة للجميع. اشترك لفتح باقي الدروس.',
                          style: AppTextStyle.caption,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ref.watch(lessonsProvider(courseId)).when(
                    data: (lessons) => Column(
                      children: lessons.map((lesson) {
                        final canOpen = hasSub || lesson.isFree;
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppShadows.card,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: canOpen
                                    ? AppColors.primary.withValues(alpha:0.12)
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: lesson.textFileUrls.isNotEmpty
                                  ? Icon(
                                      lesson.videoUrl.isNotEmpty 
                                          ? Icons.library_books_rounded 
                                          : Icons.description_rounded,
                                      color: canOpen ? AppColors.primary : AppColors.textMuted,
                                      size: 22,
                                    )
                                  : Icon(
                                      canOpen ? Icons.play_arrow_rounded : Icons.lock_rounded,
                                      color: canOpen ? AppColors.primary : AppColors.textMuted,
                                      size: 22,
                                    ),
                            ),
                            title: AppText(
                              lesson.titleAr,
                              style: AppTextStyle.body,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  if (lesson.videoUrl.isNotEmpty) ...[
                                    AppText(
                                      '${lesson.durationSec ~/ 60} دقيقة',
                                      style: AppTextStyle.caption,
                                      color: AppColors.textSecondary,
                                    ),
                                    if (lesson.textFileUrls.isNotEmpty) ...[
                                      const SizedBox(width: AppSpacing.sm),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: AppColors.textMuted,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                    ],
                                  ],
                                  if (lesson.textFileUrls.isNotEmpty)
                                    AppText(
                                      '${lesson.textFileUrls.length} ملف نصي',
                                      style: AppTextStyle.caption,
                                      color: AppColors.textSecondary,
                                    ),
                                ],
                              ),
                            ),
                            trailing: lesson.isFree
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha:0.12),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: const AppText('مجاني', style: AppTextStyle.caption),
                                  )
                                : (!canOpen
                                    ? const Icon(Icons.chevron_left, color: AppColors.textMuted, size: 22)
                                    : const Icon(Icons.chevron_left, color: AppColors.primary, size: 22)),
                            onTap: () => canOpen
                                ? context.go('/lesson/${lesson.id}?courseId=$courseId')
                                : context.go('/subscription'),
                          ),
                        );
                      }).toList(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('تعذر تحميل الدروس: $e'),
                  ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({this.icon, required this.label});

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.primary.withValues(alpha:0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
          ],
          AppText(label, style: AppTextStyle.caption),
        ],
      ),
    );
  }
}

List<Widget> _buildWhatYouWillLearn(String descAr) {
  // تقسيم الوصف إلى نقاط بسيطة إن أمكن، وإلا عرض نقاط ثابتة
  final parts = descAr.split('،').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  final items = parts.isNotEmpty
      ? parts.take(4).toList()
      : [
          'فهم أساسيات محتوى هذه الدورة.',
          'اكتساب المهارات العملية من خلال الدروس.',
          'تتبع تقدمك حتى إكمال الدورة.',
        ];
  return items
      .map(
        (text) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppText(
                  text,
                  style: AppTextStyle.body,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      )
      .toList();
}

