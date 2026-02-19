import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text.dart';
import '../../data/job.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  final Job job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  size: 26,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      job.titleAr,
                      style: AppTextStyle.title,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      job.companyName,
                      style: AppTextStyle.caption,
                      color: AppColors.textSecondary,
                      maxLines: 1,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _InfoChip(
                          icon: Icons.location_on_outlined,
                          label: job.location,
                        ),
                        _InfoChip(
                          label: job.jobTypeLabel,
                          isType: true,
                        ),
                        if (job.workModeLabel != null)
                          _InfoChip(
                            label: job.workModeLabel!,
                            isType: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_left,
                color: AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    this.icon,
    required this.label,
    this.isType = false,
  });

  final IconData? icon;
  final String label;
  final bool isType;

  @override
  Widget build(BuildContext context) {
    if (isType) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: AppColors.primary.withValues(alpha:0.2),
            width: 1,
          ),
        ),
        child: AppText(
          label,
          style: AppTextStyle.caption,
          color: AppColors.primary,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: AppText(
            label,
            style: AppTextStyle.caption,
            color: AppColors.textMuted,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
