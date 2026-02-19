import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'app_text.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText(title, style: AppTextStyle.title),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: AppText(
              actionLabel!,
              style: AppTextStyle.body,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}

