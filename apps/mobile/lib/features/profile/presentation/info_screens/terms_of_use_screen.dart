import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../../core/widgets/widgets.dart';

class TermsOfUseScreen extends ConsumerWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('شروط الاستخدام', style: AppTextStyle.title),
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
                        Icons.description_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AppText(
                      'شروط وأحكام الاستخدام',
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
              
              // Terms Sections
              _buildTermCard(
                number: '1',
                icon: Icons.check_circle_outline_rounded,
                title: 'قبول الشروط',
                content: 'باستخدام تطبيق Everest، فإنك توافق على الالتزام بالشروط والأحكام التالية. إذا كنت لا توافق على هذه الشروط، يرجى عدم استخدام التطبيق.',
                iconColor: AppColors.primary,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              _buildTermCard(
                number: '2',
                icon: Icons.rule_rounded,
                title: 'الاستخدام المسموح',
                content: '• استخدام التطبيق للأغراض التعليمية فقط\n'
                    '• الالتزام بالقوانين والأنظمة المعمول بها\n'
                    '• احترام حقوق الملكية الفكرية للمحتوى\n'
                    '• عدم محاولة اختراق أو إتلاف النظام',
                iconColor: Colors.blue,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              _buildTermCard(
                number: '3',
                icon: Icons.copyright_rounded,
                title: 'المحتوى والملكية الفكرية',
                content: '• جميع المحتويات في التطبيق محمية بحقوق الملكية الفكرية\n'
                    '• يمنع نسخ أو توزيع المحتوى دون إذن كتابي\n'
                    '• المحتوى مخصص للاستخدام الشخصي غير التجاري',
                iconColor: Colors.orange,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              _buildTermCard(
                number: '4',
                icon: Icons.account_circle_rounded,
                title: 'حساب المستخدم',
                content: '• أنت مسؤول عن سرية معلومات الدخول\n'
                    '• يمنع مشاركة حسابك مع الآخرين\n'
                    '• يجب تقديم معلومات دقيقة وحقيقية',
                iconColor: Colors.green,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              _buildTermCard(
                number: '5',
                icon: Icons.payment_rounded,
                title: 'الدفع والاشتراكات',
                content: '• الأسعار المعروضة نهائية وتشمل الضريبة\n'
                    '• يتم الدفع عبر القنوات المعتمدة فقط\n'
                    '• لا يتم استرجاع المبالغ المدفوعة بعد بدء الخدمة',
                iconColor: Colors.purple,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              _buildTermCard(
                number: '6',
                icon: Icons.privacy_tip_rounded,
                title: 'الخصوصية والبيانات',
                content: '• نلتزم بحماية بياناتك الشخصية\n'
                    '• يتم جمع البيانات وفقاً لسياسة الخصوصية\n'
                    '• نحتفظ بالحق في استخدام البيانات لتحسين الخدمة',
                iconColor: Colors.teal,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              _buildTermCard(
                number: '7',
                icon: Icons.gavel_rounded,
                title: 'تحديد المسؤولية',
                content: '• نحن لا نضمن استمرارية الخدمة 100%\n'
                    '• لسنا مسؤولين عن أي أضرار ناتجة عن استخدام التطبيق\n'
                    '• نحاول تقديم أفضل خدمة ممكنة ولكن بدون ضمانات',
                iconColor: Colors.red,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              _buildTermCard(
                number: '8',
                icon: Icons.edit_rounded,
                title: 'تعديل الشروط',
                content: '• نحتفظ بالحق في تعديل هذه الشروط والأحكام\n'
                    '• سيتم إعلام المستخدمين بأي تغييرات مهمة\n'
                    '• استمرار استخدام التطبيق يعني قبول التعديلات',
                iconColor: Colors.amber,
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

  Widget _buildTermCard({
    required String number,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: AppText(
                    number,
                    style: AppTextStyle.title,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
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
