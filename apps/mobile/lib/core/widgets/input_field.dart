import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class InputField extends StatelessWidget {
  const InputField({
    super.key,
    this.hintText,
    this.prefixIcon,
    this.onChanged,
  });

  final String? hintText;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}

