import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

enum AppTextStyle { headline, title, body, caption }

class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.style = AppTextStyle.body,
    this.color,
    this.align,
    this.maxLines,
  });

  final String text;
  final AppTextStyle style;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    TextStyle? resolved;
    switch (style) {
      case AppTextStyle.headline:
        resolved = theme.displayLarge;
        break;
      case AppTextStyle.title:
        resolved = theme.titleLarge;
        break;
      case AppTextStyle.body:
        resolved = theme.bodyMedium;
        break;
      case AppTextStyle.caption:
        resolved = theme.bodySmall;
        break;
    }
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: resolved?.copyWith(color: color ?? AppColors.textPrimary),
    );
  }
}

