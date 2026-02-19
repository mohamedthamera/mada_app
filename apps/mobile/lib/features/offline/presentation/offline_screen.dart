import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../../core/widgets/widgets.dart';
import '../data/offline_repository.dart';

class OfflineScreen extends ConsumerStatefulWidget {
  const OfflineScreen({super.key});

  @override
  ConsumerState<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends ConsumerState<OfflineScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.read(offlineRepositoryProvider);
    final downloads = repo.getDownloadedLessons();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('التنزيلات', style: AppTextStyle.title),
        ),
        body: ListView(
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
                      Icons.offline_bolt_rounded,
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
                          'مشاهدة بدون إنترنت',
                          style: AppTextStyle.title,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          downloads.isEmpty
                              ? 'لم تنزّل أي درس بعد. انزل دروساً من داخل الدرس ثم ارجع هنا.'
                              : 'لديك ${downloads.length} درس منزل. اضغط على أي درس للمشاهدة دون اتصال.',
                          style: AppTextStyle.caption,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (downloads.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
                  child: Column(
                    children: [
                      Icon(
                        Icons.download_rounded,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const AppText(
                        'لا توجد دروس محملة',
                        style: AppTextStyle.title,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppText(
                        'افتح أي درس من الدورات واضغط "تنزيل الدرس" لتمكين المشاهدة دون اتصال.',
                        style: AppTextStyle.body,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              AppText(
                'الدروس المحملة (${downloads.length})',
                style: AppTextStyle.title,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...downloads.map((lessonId) {
                final courseId = repo.getCourseIdForDownload(lessonId);
                final title = repo.getLessonTitle(lessonId) ?? 'درس منزل';
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: courseId != null
                          ? () => context.go(
                                '/lesson/$lessonId?courseId=$courseId',
                              )
                          : null,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha:0.12),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: const Icon(
                                Icons.play_circle_outline_rounded,
                                size: 28,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(title, style: AppTextStyle.body),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.offline_bolt_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      AppText(
                                        'متاح للمشاهدة بدون إنترنت',
                                        style: AppTextStyle.caption,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              color: AppColors.danger,
                              onPressed: () async {
                                await repo.removeDownload(lessonId);
                                if (mounted) setState(() {});
                              },
                              tooltip: 'حذف التنزيل',
                            ),
                            const Icon(
                              Icons.chevron_left,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
