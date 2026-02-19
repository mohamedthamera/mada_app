import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../core/widgets/widgets.dart';
import 'notifications_providers.dart';
import '../../../app/di.dart';
import '../../../core/notifications/fcm_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseUpdates = ref.watch(courseUpdatesProvider);
    final marketingUpdates = ref.watch(marketingUpdatesProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('الإشعارات', style: AppTextStyle.title),
        ),
        body: ref.watch(notificationsProvider).when(
              data: (items) => ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      AppCard(
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const AppText('إشعارات الدورات الجديدة',
                                  style: AppTextStyle.body),
                              value: courseUpdates,
                              onChanged: (value) async {
                                ref.read(courseUpdatesProvider.notifier).state =
                                    value;
                                if (value) {
                                  await FcmService()
                                      .subscribeToTopic('course_updates');
                                } else {
                                  await FcmService()
                                      .unsubscribeFromTopic('course_updates');
                                }
                              },
                            ),
                            SwitchListTile(
                              title: const AppText('عروض وتسويق',
                                  style: AppTextStyle.body),
                              value: marketingUpdates,
                              onChanged: (value) async {
                                ref.read(marketingUpdatesProvider.notifier).state =
                                    value;
                                if (value) {
                                  await FcmService()
                                      .subscribeToTopic('marketing');
                                } else {
                                  await FcmService()
                                      .unsubscribeFromTopic('marketing');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (items.isEmpty)
                        const Center(
                          child: AppText('لا توجد إشعارات',
                              style: AppTextStyle.body),
                        )
                      else
                        ...items.map(
                          (item) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: AppCard(
                              child: Row(
                                children: [
                                  const AppIcon(emoji: '🔔', size: 44),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(item.title,
                                            style: AppTextStyle.body),
                                        const SizedBox(height: AppSpacing.xs),
                                        AppText(
                                          item.body,
                                          style: AppTextStyle.caption,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (item.readAt == null)
                                    Container(
                                      height: 8,
                                      width: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.danger,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('تعذر تحميل الإشعارات: $e')),
            ),
      ),
    );
  }
}

