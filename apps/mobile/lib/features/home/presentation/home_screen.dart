import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../progress/data/progress_repository.dart';
import '../../../app/di.dart';
import '../../courses/presentation/course_providers.dart';
import '../../courses/presentation/course_card.dart';
import '../../../core/widgets/widgets.dart';
import 'widgets/home_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId != null) {
      ref.read(progressRepositoryProvider).syncAll(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = const [
      {'name': 'تسويق', 'count': '+65', 'icon': '📈'},
      {'name': 'تصميم', 'count': '+85', 'icon': '🎨'},
      {'name': 'برمجة', 'count': '+150', 'icon': '💻'},
      {'name': 'لغات', 'count': '+110', 'icon': '🌍'},
      {'name': 'أعمال', 'count': '+95', 'icon': '💼'},
      {'name': 'ذكاء اصطناعي', 'count': '+45', 'icon': '🤖'},
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 10),
            const HomeBanner(),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'الدورات المميزة',
              actionLabel: 'عرض الكل',
              onAction: () => context.go('/courses'),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 220,
              child: ref.watch(coursesProvider).when(
                data: (courses) {
                  final featured = courses.take(6).toList();
                  if (featured.isEmpty) {
                    return Center(
                      child: Text(
                        'لا توجد دورات مميزة حالياً',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: featured.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      return CourseCard(course: featured[index]);
                    },
                  );
                },
                loading: () => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (_, __) => Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, __) => Center(
                  child: Text(
                    'تعذر تحميل الدورات المميزة',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'الفئات',
              actionLabel: 'عرض الكل',
              onAction: () => context.go('/courses'),
            ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              children: categories
                  .map(
                    (c) => AppCard(
                      child: InkWell(
                        onTap: () => context.go('/courses'),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(emoji: c['icon']!, size: 40),
                            const SizedBox(height: AppSpacing.xs),
                            AppText(c['name']!, style: AppTextStyle.body),
                            const SizedBox(height: 2),
                            AppText(c['count']!,
                                style: AppTextStyle.caption,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'استكمل التعلم'),
            const SizedBox(height: AppSpacing.md),
            ref.watch(coursesProvider).when(
                  data: (courses) {
                    final list = courses.take(2).toList();
                    return Column(
                      children: list
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: AppCard(
                                  child: InkWell(
                                    onTap: () =>
                                        context.go('/courses/${c.id}'),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                    child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(c.titleAr,
                                            style: AppTextStyle.title),
                                        const SizedBox(height: AppSpacing.xs),
                                        AppText('د. محمد أحمد',
                                            style: AppTextStyle.caption,
                                            color: AppColors.textSecondary),
                                        const SizedBox(height: AppSpacing.sm),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(AppRadius.sm),
                                          child: LinearProgressIndicator(
                                            value: 1.0,
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Container(
                                    height: 56,
                                    width: 56,
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.primary,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: const Icon(Icons.laptop,
                                        color: AppColors.primaryForeground),
                                  ),
                                ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('تعذر تحميل الدورات: $e'),
                ),
          ],
        ),
      ),
    );
  }
}

