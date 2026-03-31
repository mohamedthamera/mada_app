import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppButton extends StatelessWidget {
  const WhatsAppButton({
    super.key,
    required this.phoneNumber,
    required this.message,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String phoneNumber;
  final String message;
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  factory WhatsAppButton.applyJob({
    Key? key,
    required String phoneNumber,
    required String message,
    String label = 'تقديم الآن',
  }) {
    return WhatsAppButton(
      key: key,
      phoneNumber: phoneNumber,
      message: message,
      label: label,
      icon: Icons.send_rounded,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.primaryForeground,
    );
  }

  factory WhatsAppButton.requestCv({
    Key? key,
    required String phoneNumber,
    required String jobTitle,
  }) {
    final message = 'مرحباً، أود طلب إنشاء سيرة ذاتية للوظيفة: $jobTitle';
    return WhatsAppButton(
      key: key,
      phoneNumber: phoneNumber,
      message: message,
      label: 'طلب إنشاء CV',
      icon: Icons.description_rounded,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.primaryForeground,
    );
  }

  factory WhatsAppButton.globalRequestCv({
    Key? key,
    required String phoneNumber,
    String message = 'مرحباً، أود طلب إنشاء سيرة ذاتية',
  }) {
    return WhatsAppButton(
      key: key,
      phoneNumber: phoneNumber,
      message: message,
      label: 'طلب إنشاء CV',
      icon: Icons.chat_rounded,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.primaryForeground,
    );
  }

  String get _whatsAppUrl {
    final encodedMessage = Uri.encodeComponent(message);
    return 'https://wa.me/$phoneNumber?text=$encodedMessage';
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final url = _whatsAppUrl;
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر فتح واتساب. تأكد من تثبيت التطبيق'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => _launchWhatsApp(context),
      icon: Icon(icon ?? Icons.chat_rounded),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.green.shade600,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}
