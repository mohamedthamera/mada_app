import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.emoji,
    this.size = 48,
  });

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }
}

