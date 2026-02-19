import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../core/widgets/widgets.dart';
import 'community_providers.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('المجتمع', style: AppTextStyle.title),
        ),
        body: ref.watch(discussionsProvider).when(
              data: (items) => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return AppCard(
                    child: Row(
                      children: [
                        const AppIcon(emoji: '💬', size: 44),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(item.title, style: AppTextStyle.body),
                              const SizedBox(height: AppSpacing.xs),
                              AppText(
                                item.body,
                                style: AppTextStyle.caption,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                        AppText(
                          '${item.createdAt.day}/${item.createdAt.month}',
                          style: AppTextStyle.caption,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('تعذر تحميل النقاشات: $e')),
            ),
      ),
    );
  }
}

