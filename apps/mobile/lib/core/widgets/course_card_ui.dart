import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'app_card.dart';
import 'app_text.dart';

class CourseCardUi extends StatelessWidget {
  const CourseCardUi({
    super.key,
    required this.title,
    required this.instructor,
    required this.rating,
    required this.lessons,
    required this.hours,
    this.thumbnail,
    this.onTap,
    this.lessonsLabel = 'درس',
  });

  final String title;
  final String instructor;
  final double rating;
  final int lessons;
  final String hours;
  final Widget? thumbnail;
  final VoidCallback? onTap;
  final String lessonsLabel;

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
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  width: 100,
                  height: 76,
                  color: AppColors.primary.withValues(alpha:0.08),
                  child: thumbnail ??
                      const Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      title,
                      style: AppTextStyle.title,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      instructor,
                      style: AppTextStyle.caption,
                      color: AppColors.textSecondary,
                      maxLines: 1,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CourseChip(
                          icon: Icons.star_rounded,
                          label: rating.toStringAsFixed(1),
                          color: AppColors.primary,
                        ),
                        _CourseChip(
                          label: '$lessons $lessonsLabel',
                        ),
                        _CourseChip(label: hours),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
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

class _CourseChip extends StatelessWidget {
  const _CourseChip({
    this.icon,
    required this.label,
    this.color,
  });

  final IconData? icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.textMuted).withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: (color ?? AppColors.textMuted).withValues(alpha:0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color ?? AppColors.textMuted),
            const SizedBox(width: 4),
          ],
          AppText(
            label,
            style: AppTextStyle.caption,
            color: color ?? AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
