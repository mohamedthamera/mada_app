import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/widgets.dart';

class AboutAppScreen extends ConsumerWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('حول التطبيق', style: AppTextStyle.title),
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
              // App Logo & Info Card
              AppCard(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha:0.3),
                            AppColors.primary.withValues(alpha:0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha:0.5),
                          width: 3,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/everest_logo.jpeg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primary.withValues(alpha:0.15),
                          alignment: Alignment.center,
                          child: const AppText(
                            'Everest',
                            style: AppTextStyle.title,
                            align: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AppText(
                      'تطبيق Everest',
                      style: AppTextStyle.headline,
                      align: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const AppText(
                      'منصة تعليمية شاملة',
                      style: AppTextStyle.body,
                      align: TextAlign.center,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const AppText(
                        'الإصدار: 1.0.0',
                        style: AppTextStyle.caption,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // About Section
              _buildSectionCard(
                icon: Icons.info_outline_rounded,
                title: 'عن التطبيق',
                content: 'تطبيق Everest هو منصة تعليمية شاملة يقدم دورات ومحتوى تعليمي عالي الجودة في مختلف المجالات. نسعى لتوفير تجربة تعليمية مميزة وفعالة لجميع المستخدمين.',
                iconColor: AppColors.primary,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Vision Section
              _buildSectionCard(
                icon: Icons.visibility_rounded,
                title: 'رؤيتنا',
                content: 'أن نكون المنصة التعليمية الرائدة في المنطقة، مساهمين في تطوير المهارات والمعرفة للملايين من المتعلمين.',
                iconColor: Colors.blue,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Features Section
              _buildFeaturesCard(),
              
              const SizedBox(height: AppSpacing.md),
              
              // Team Section
              _buildSectionCard(
                icon: Icons.people_rounded,
                title: 'فريق العمل',
                content: 'فريق Everest يتكون من خبراء ومتخصصين في التعليم والتكنولوجيا، يعملون معاً لتقديم أفضل تجربة تعليمية ممكنة.',
                iconColor: Colors.purple,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Developer Card
              _buildDeveloperCard(),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Footer
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const AppText(
                    '© 2026 Everest. جميع الحقوق محفوظة.',
                    style: AppTextStyle.caption,
                    color: AppColors.textSecondary,
                  ),
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

  Widget _buildFeaturesCard() {
    final features = [
      ('محتوى تعليمي متنوع', Icons.menu_book_rounded, Colors.green),
      ('شروحات فيديو تفاعلية', Icons.video_library_rounded, Colors.blue),
      ('اختبارات وتقييمات', Icons.quiz_rounded, Colors.orange),
      ('شهادات معتمدة', Icons.verified_rounded, Colors.purple),
      ('واجهة سهلة الاستخدام', Icons.phone_android_rounded, Colors.teal),
    ];

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
                  color: AppColors.primary.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: AppText(
                  'مميزات التطبيق',
                  style: AppTextStyle.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: feature.$3.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        feature.$2,
                        size: 18,
                        color: feature.$3,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppText(
                        feature.$1,
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

  Widget _buildDeveloperCard() {
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
                  color: Colors.purple.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.code_rounded,
                  size: 22,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: AppText(
                  'المطور',
                  style: AppTextStyle.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final Uri url = Uri.parse('https://www.instagram.com/moheodev');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.purple.withValues(alpha:0.3),
                            Colors.pink.withValues(alpha:0.2),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.purple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText(
                            'moheodev',
                            style: AppTextStyle.title,
                          ),
                          const SizedBox(height: 4),
                          const AppText(
                            'المطور الرئيسي للتطبيق',
                            style: AppTextStyle.caption,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
