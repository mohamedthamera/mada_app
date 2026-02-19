import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../../app/di.dart';
import '../../../core/notifications/fcm_service.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/data/supabase_auth_repository.dart';
import '../../subscription/presentation/subscription_providers.dart';
import '../data/profile_repository.dart';
import 'info_screens/privacy_policy_screen.dart';
import 'info_screens/about_app_screen.dart';
import 'info_screens/terms_of_use_screen.dart';
import 'info_screens/contact_us_screen.dart';
import '../../referral/presentation/referral_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final courseUpdates = ref.watch(courseUpdatesProvider);
    final marketingUpdates = ref.watch(marketingUpdatesProvider);
    final user = ref.watch(supabaseClientProvider).auth.currentUser;
    final hasSubAsync = ref.watch(hasActiveSubscriptionProvider);
    final displayName = () {
      final metaName = user?.userMetadata?['name']?.toString().trim();
      if (metaName != null && metaName.isNotEmpty) return metaName;
      final email = user?.email;
      if (email != null && email.isNotEmpty) {
        return email.split('@').first;
      }
      return 'مستخدم';
    }();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('الملف الشخصي', style: AppTextStyle.title),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            hasSubAsync.when(
              data: (isSubscribed) => _buildProfileHeader(
                context,
                displayName: user != null ? displayName : 'مرحباً بك',
                email: user != null ? (user.email ?? '') : 'سجّل الدخول لحفظ تقدمك',
                isSubscribed: isSubscribed,
              ),
              loading: () => _buildProfileHeader(
                context,
                displayName: user != null ? displayName : 'مرحباً بك',
                email: user != null ? (user.email ?? '') : 'سجّل الدخول لحفظ تقدمك',
                isSubscribed: false,
              ),
              error: (_, __) => _buildProfileHeader(
                context,
                displayName: user != null ? displayName : 'مرحباً بك',
                email: user != null ? (user.email ?? '') : 'سجّل الدخول لحفظ تقدمك',
                isSubscribed: false,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (user != null)
              _buildLogoutButton(context, ref)
            else
              _buildLoginButton(context),
            if (user != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _buildSectionTitle('إعدادات الحساب'),
              const SizedBox(height: AppSpacing.sm),
              _buildAccountSettingsCard(context, ref),
            ],
            const SizedBox(height: AppSpacing.xl),
            _buildSectionTitle('الإعدادات'),
            const SizedBox(height: AppSpacing.sm),
            _buildSettingsCard(
              context,
              ref: ref,
              locale: locale,
              courseUpdates: courseUpdates,
              marketingUpdates: marketingUpdates,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('الحساب والخدمات'),
            const SizedBox(height: AppSpacing.sm),
            _buildLinksCard(context),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context, {
    required String displayName,
    required String email,
    bool isSubscribed = false,
  }) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha:0.2),
            AppColors.primary.withValues(alpha:0.06),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha:0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha:0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha:0.5),
                width: 2,
              ),
            ),
            child: Text(
              initial,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryForeground,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppText(displayName, style: AppTextStyle.headline),
                    if (isSubscribed) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AppText(
                              'مشترك',
                              style: AppTextStyle.caption,
                              color: Colors.green.shade800,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                AppText(
                  email,
                  style: AppTextStyle.caption,
                  color: AppColors.textSecondary,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await ref.read(authRepositoryProvider).signOut();
          if (context.mounted) context.go('/login');
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha:0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.danger.withValues(alpha:0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: AppColors.danger, size: 22),
              const SizedBox(width: AppSpacing.sm),
              const AppText(
                'تسجيل الخروج',
                style: AppTextStyle.body,
                color: AppColors.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return AppButton(
      label: 'تسجيل الدخول',
      onPressed: () => context.go('/login'),
    );
  }

  Widget _buildSectionTitle(String title) {
    return AppText(title, style: AppTextStyle.title);
  }

  Widget _buildAccountSettingsCard(BuildContext context, WidgetRef ref) {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    final displayName = user?.userMetadata?['name']?.toString().trim() ??
        user?.email?.split('@').first ??
        'مستخدم';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _linkTile(
            context,
            icon: Icons.person_outline_rounded,
            title: 'تغيير الاسم',
            subtitle: displayName,
            onTap: () => _showEditNameDialog(context, ref, displayName),
          ),
          Divider(height: 1, color: AppColors.border),
          _linkTile(
            context,
            icon: Icons.phone_android_rounded,
            title: 'رقم الهاتف',
            subtitle: 'إضافة أو تغيير رقم الهاتف',
            onTap: () => _showEditPhoneDialog(context, ref),
          ),
          Divider(height: 1, color: AppColors.border),
          const _ReferralTile(),
          Divider(height: 1, color: AppColors.border),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            leading: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.delete_forever_rounded, size: 22, color: AppColors.danger),
            ),
            title: const AppText(
              'حذف الحساب',
              style: AppTextStyle.body,
              color: AppColors.danger,
            ),
            subtitle: const AppText(
              'تسجيل الخروج وحذف الحساب',
              style: AppTextStyle.caption,
              color: AppColors.textSecondary,
            ),
            trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final repo = ref.read(profileRepositoryProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تغيير الاسم'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'الاسم',
              hintText: 'أدخل اسمك',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await repo.updateName(controller.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الاسم بنجاح')),
        );
        ref.invalidate(supabaseClientProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التحديث: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showEditPhoneDialog(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(profileRepositoryProvider);
    String initialPhone = '';
    try {
      final data = await repo.getProfileData();
      initialPhone = data['phone'] ?? '';
    } catch (_) {}
    final controller = TextEditingController(text: initialPhone);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('رقم الهاتف'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف',
              hintText: 'مثال: 07XX XXX XXXX',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await repo.updatePhone(controller.text.isEmpty ? null : controller.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث رقم الهاتف بنجاح')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التحديث: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الحساب'),
          content: const Text(
            'سيتم تسجيل خروجك من التطبيق.\n'
            'لحذف حسابك نهائياً من السيرفر تواصل مع الدعم من صفحة «تواصل معنا».',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(profileRepositoryProvider).signOut();
    if (context.mounted) context.go('/login');
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required WidgetRef ref,
    required Locale locale,
    required bool courseUpdates,
    required bool marketingUpdates,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _settingsSwitch(
            icon: Icons.school_rounded,
            title: 'إشعارات الدورات الجديدة',
            value: courseUpdates,
            onChanged: (value) async {
              ref.read(courseUpdatesProvider.notifier).state = value;
              if (value) {
                await FcmService().subscribeToTopic('course_updates');
              } else {
                await FcmService().unsubscribeFromTopic('course_updates');
              }
            },
          ),
          Divider(height: 1, color: AppColors.border),
          _settingsSwitch(
            icon: Icons.campaign_rounded,
            title: 'عروض وتسويق',
            value: marketingUpdates,
            onChanged: (value) async {
              ref.read(marketingUpdatesProvider.notifier).state = value;
              if (value) {
                await FcmService().subscribeToTopic('marketing');
              } else {
                await FcmService().unsubscribeFromTopic('marketing');
              }
            },
          ),
          Divider(height: 1, color: AppColors.border),
          _settingsRow(
            icon: Icons.language_rounded,
            title: 'اللغة',
            subtitle: locale.languageCode == 'ar' ? 'العربية' : 'English',
            onTap: () {
              ref.read(localeProvider.notifier).state =
                  locale.languageCode == 'ar'
                      ? const Locale('en')
                      : const Locale('ar');
            },
          ),
        ],
      ),
    );
  }

  Widget _settingsSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppText(title, style: AppTextStyle.body),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 22, color: AppColors.primary),
      ),
      title: AppText(title, style: AppTextStyle.body),
      subtitle: AppText(
        subtitle,
        style: AppTextStyle.caption,
        color: AppColors.textSecondary,
      ),
      trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  Widget _buildLinksCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _linkTile(
            context,
            icon: Icons.subscriptions_rounded,
            title: 'الاشتراك',
            onTap: () => context.go('/subscription'),
          ),
          Divider(height: 1, color: AppColors.border),
          _linkTile(
            context,
            icon: Icons.verified_rounded,
            title: 'الشهادات',
            onTap: () => context.go('/certificates'),
          ),
          Divider(height: 1, color: AppColors.border),
          _linkTile(
            context,
            icon: Icons.privacy_tip_rounded,
            title: 'سياسة الخصوصية',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyScreen(),
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          _linkTile(
            context,
            icon: Icons.info_rounded,
            title: 'حول التطبيق',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AboutAppScreen(),
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          _linkTile(
            context,
            icon: Icons.description_rounded,
            title: 'شروط الاستخدام',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TermsOfUseScreen(),
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          _linkTile(
            context,
            icon: Icons.contact_support_rounded,
            title: 'تواصل معنا',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ContactUsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 22, color: AppColors.primary),
      ),
      title: AppText(title, style: AppTextStyle.body),
      subtitle: subtitle != null
          ? AppText(subtitle, style: AppTextStyle.caption, color: AppColors.textSecondary)
          : null,
      trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}

class _ReferralTile extends ConsumerWidget {
  const _ReferralTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralAsync = ref.watch(userReferralProvider);
    return referralAsync.when(
      data: (referral) {
        final codeUsed = referral?['code_used'] as String?;
        final subtitle = codeUsed != null && codeUsed.isNotEmpty
            ? 'تم استخدام: $codeUsed'
            : 'أدخل كود الإحالة';
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.card_giftcard_rounded, size: 22, color: AppColors.primary),
          ),
          title: const AppText('كود الإحالة', style: AppTextStyle.body),
          subtitle: AppText(subtitle, style: AppTextStyle.caption, color: AppColors.textSecondary),
          trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
          onTap: () => context.push('/referral'),
        );
      },
      loading: () => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        leading: const SizedBox(
          width: 40,
          height: 40,
          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
        title: const AppText('كود الإحالة', style: AppTextStyle.body),
        trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
        onTap: () => context.push('/referral'),
      ),
      error: (_, __) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(Icons.card_giftcard_rounded, size: 22, color: AppColors.primary),
        ),
        title: const AppText('كود الإحالة', style: AppTextStyle.body),
        subtitle: const AppText('أدخل كود الإحالة', style: AppTextStyle.caption, color: AppColors.textSecondary),
        trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
        onTap: () => context.push('/referral'),
      ),
    );
  }
}
