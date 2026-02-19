import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../../core/widgets/widgets.dart';
import 'course_providers.dart';
import '../../subscription/presentation/subscription_providers.dart';

class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({super.key});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  String _sort = 'new';
  String _query = '';
  String _categoryFilter = 'الكل';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: AppText(t.courses, style: AppTextStyle.title),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) => setState(() => _sort = value),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rating', child: Text('الأعلى تقييماً')),
                PopupMenuItem(value: 'new', child: Text('الأحدث')),
              ],
            ),
          ],
        ),
        body: ref.watch(coursesProvider).when(
              data: (courses) {
                final hasSubAsync = ref.watch(hasActiveSubscriptionProvider);
                final filtered = courses
                    .where(
                      (c) =>
                          c.titleAr.contains(_query) ||
                          c.titleEn.toLowerCase().contains(_query.toLowerCase()),
                    )
                    .where((c) {
                      if (_categoryFilter == 'الكل') return true;
                      final cat = _categoryFilter;
                      return c.titleAr.contains(cat) ||
                          c.descAr.contains(cat);
                    })
                    .toList();
                if (_sort == 'rating') {
                  filtered.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
                }
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
                              Icons.menu_book_rounded,
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
                                  'استكشف الدورات',
                                  style: AppTextStyle.title,
                                ),
                                const SizedBox(height: 4),
                                AppText(
                                  '${courses.length} دورة متاحة',
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
                      hintText: 'ابحث عن دورة...',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AppText(
                      'أقسام الدورات',
                      style: AppTextStyle.title,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('الكل'),
                          _buildCategoryChip('تسويق'),
                          _buildCategoryChip('تصميم'),
                          _buildCategoryChip('برمجة'),
                          _buildCategoryChip('لغات'),
                          _buildCategoryChip('أعمال'),
                          _buildCategoryChip('ذكاء اصطناعي'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl * 1.5,
                          horizontal: AppSpacing.lg,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 56,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppText(
                              'لا توجد دورات تطابق البحث',
                              style: AppTextStyle.body,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      )
                    else
                      hasSubAsync.when(
                        data: (hasSub) => Column(
                          children: filtered
                              .map(
                                (course) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: Stack(
                                    children: [
                                      Opacity(
                                        opacity: hasSub ? 1 : 0.6,
                                        child: CourseCardUi(
                                          title: course.titleAr,
                                          instructor: 'مدرب المادة',
                                          rating: course.ratingAvg,
                                          lessons: course.ratingCount,
                                          hours: 'المستوى: ${course.level}',
                                          lessonsLabel: 'تقييم',
                                          thumbnail: Image.network(
                                            course.thumbnailUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              color: AppColors.surface,
                                              child: const Icon(
                                                  Icons.image_not_supported),
                                            ),
                                          ),
                                          // دائماً ننتقل إلى صفحة تفاصيل الدورة،
                                          // وقفل الدروس يتم داخل صفحة التفاصيل.
                                          onTap: () =>
                                              context.go('/courses/${course.id}'),
                                        ),
                                      ),
                                      if (!hasSub)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.sm),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.lock,
                                                    size: 14,
                                                    color: Colors.white),
                                                SizedBox(width: 4),
                                                AppText(
                                                  'اشترك لفتح الدورة',
                                                  style: AppTextStyle.caption,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        loading: () => Column(
                          children: filtered
                              .map(
                                (course) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: CourseCardUi(
                                    title: course.titleAr,
                                    instructor: 'مدرب المادة',
                                    rating: course.ratingAvg,
                                    lessons: course.ratingCount,
                                    hours: 'المستوى: ${course.level}',
                                    lessonsLabel: 'تقييم',
                                    thumbnail: Image.network(
                                      course.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.surface,
                                        child: const Icon(
                                            Icons.image_not_supported),
                                      ),
                                    ),
                                    onTap: () =>
                                        context.go('/courses/${course.id}'),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        error: (_, __) => Column(
                          children: filtered
                              .map(
                                (course) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: CourseCardUi(
                                    title: course.titleAr,
                                    instructor: 'مدرب المادة',
                                    rating: course.ratingAvg,
                                    lessons: course.ratingCount,
                                    hours: 'المستوى: ${course.level}',
                                    lessonsLabel: 'تقييم',
                                    thumbnail: Image.network(
                                      course.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.surface,
                                        child: const Icon(
                                            Icons.image_not_supported),
                                      ),
                                    ),
                                    onTap: () =>
                                        context.go('/courses/${course.id}'),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppText(
                        'تعذر تحميل الدورات',
                        style: AppTextStyle.body,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppText(
                        '$e',
                        style: AppTextStyle.caption,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    return _categoryChip(
      label: label,
      selected: _categoryFilter == label,
      onTap: () => setState(() => _categoryFilter = label),
    );
  }
}

Widget _categoryChip({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(left: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha:0.2),
      checkmarkColor: AppColors.primary,
    ),
  );
}

