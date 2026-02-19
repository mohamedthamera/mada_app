import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/widgets.dart';

class ContactUsScreen extends ConsumerWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('تواصل معنا', style: AppTextStyle.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              AppCard(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha:0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.contact_support_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AppText(
                      'نحن هنا لمساعدتك',
                      style: AppTextStyle.headline,
                      align: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const AppText(
                      'يسعدنا التواصل معك والإجابة على جميع استفساراتك',
                      style: AppTextStyle.body,
                      color: AppColors.textSecondary,
                      align: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Social Media Section
              const AppText(
                'وسائل التواصل',
                style: AppTextStyle.title,
              ),
              const SizedBox(height: AppSpacing.md),
              
              _buildContactCard(
                icon: Icons.facebook,
                title: 'فيسبوك',
                subtitle: 'facebook.com/everestapp',
                color: const Color(0xFF1877F2),
                onTap: () async {
                  final Uri url = Uri.parse('https://www.facebook.com/everestapp');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              _buildContactCard(
                icon: Icons.camera_alt,
                title: 'انستغرام',
                subtitle: '@everestapp',
                color: const Color(0xFFE4405F),
                onTap: () async {
                  final Uri url = Uri.parse('https://www.instagram.com/everestapp');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              _buildContactCard(
                icon: Icons.email_rounded,
                title: 'البريد الإلكتروني',
                subtitle: 'support@everestapp.com',
                color: Colors.blue,
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'support@everestapp.com',
                    query: 'subject=استفسار عن تطبيق Everest',
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                },
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Additional Info Section
              _buildInfoCard(
                icon: Icons.location_on_rounded,
                title: 'معلومات إضافية',
                items: [
                  '📍 العنوان: العراق - بغداد',
                  '⏱️ وقت الرد المتوقع: عادة نرد خلال 24 ساعة خلال أيام العمل',
                  '📞 ساعات العمل: من السبت إلى الخميس، 9 صباحاً - 5 مساءً',
                ],
                iconColor: Colors.red,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Tips Section
              _buildInfoCard(
                icon: Icons.lightbulb_outline_rounded,
                title: 'نصائح للتواصل الفعال',
                items: [
                  '• كن واضحاً في رسالتك',
                  '• اذكر تفاصيل استفسارك بدقة',
                  '• أرفق صوراً إذا كان الاستفسار يتطلب ذلك',
                  '• استخدم اللغة العربية أو الإنجليزية',
                ],
                iconColor: Colors.amber,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Important Notice Card
              AppCard(
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha:0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AppText(
                      'ملاحظة هامة',
                      style: AppTextStyle.title,
                      color: AppColors.primary,
                      align: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const AppText(
                      'جميع حسابات التواصل الاجتماعي الرسمية تحمل اسم "everestapp" فقط. تواصل معنا عبر الحسابات الرسمية فقط لضمان سلامة بياناتك.',
                      style: AppTextStyle.body,
                      align: TextAlign.center,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AppCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha:0.2),
                      color.withValues(alpha:0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title,
                      style: AppTextStyle.title,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      subtitle,
                      style: AppTextStyle.body,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                color: AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color iconColor,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppText(
                  title,
                  style: AppTextStyle.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 4),
                    Expanded(
                      child: AppText(
                        item,
                        style: AppTextStyle.body,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
