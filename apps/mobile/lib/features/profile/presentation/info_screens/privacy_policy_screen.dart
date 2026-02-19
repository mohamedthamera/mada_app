import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../../core/widgets/widgets.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('سياسة الخصوصية', style: AppTextStyle.title),
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
                        Icons.privacy_tip_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AppText(
                      'سياسة الخصوصية',
                      style: AppTextStyle.headline,
                      align: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const AppText(
                      'لتطبيق Everest',
                      style: AppTextStyle.body,
                      color: AppColors.textSecondary,
                      align: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Introduction Section
              _buildSectionCard(
                icon: Icons.info_outline_rounded,
                title: 'مقدمة',
                content: 'نحن في تطبيق Everest نلتزم بحماية خصوصيتك وبياناتك الشخصية. توفر هذه السياسة معلومات حول كيفية جمع واستخدام وحماية بياناتك عند استخدام تطبيقنا.',
                iconColor: AppColors.primary,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Data Collection Section
              _buildSectionCard(
                icon: Icons.data_object_rounded,
                title: 'البيانات التي نجمعها',
                content: '• المعلومات الشخصية الأساسية (الاسم، البريد الإلكتروني)\n'
                    '• معلومات الجهاز ونظام التشغيل\n'
                    '• بيانات الاستخدام والتفاعل مع التطبيق\n'
                    '• معلومات الدفع والاشتراكات',
                iconColor: Colors.blue,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Data Usage Section
              _buildSectionCard(
                icon: Icons.analytics_rounded,
                title: 'كيفية استخدام البيانات',
                content: '• توفير وتحسين خدمات التطبيق\n'
                    '• التواصل مع المستخدمين\n'
                    '• تحليل البيانات لتحسين التجربة\n'
                    '• إرسال إشعارات مهمة',
                iconColor: Colors.green,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Data Protection Section
              _buildSectionCard(
                icon: Icons.lock_rounded,
                title: 'حماية البيانات',
                content: 'نستخدم أحدث تقنيات الأمان لحماية بياناتك ولا نشارك معلوماتك الشخصية مع أطراف ثالثة دون موافقتك. جميع البيانات مشفرة ومخزنة بشكل آمن.',
                iconColor: Colors.orange,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // User Rights Section
              _buildSectionCard(
                icon: Icons.verified_user_rounded,
                title: 'حقوق المستخدم',
                content: '• حق الوصول إلى بياناتك\n'
                    '• حق تعديل أو حذف بياناتك\n'
                    '• حق سحب الموافقة في أي وقت\n'
                    '• حق نقل البيانات',
                iconColor: Colors.purple,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Last Update
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.update_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const AppText(
                      'آخر تحديث: فبراير 2026',
                      style: AppTextStyle.caption,
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

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
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
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            content,
            style: AppTextStyle.body,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
