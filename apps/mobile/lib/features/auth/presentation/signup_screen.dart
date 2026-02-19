import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../../core/widgets/widgets.dart';
import '../../profile/presentation/info_screens/privacy_policy_screen.dart';
import '../../profile/presentation/info_screens/terms_of_use_screen.dart';
import '../data/auth_error_helper.dart';
import '../data/supabase_auth_repository.dart';
import '../../referral/data/referral_repository.dart';
import '../../../app/di.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  /// قبول صيغ بريد شائعة (بما فيها نطاقات طويلة ونقاط متعددة)
  static bool _isValidEmail(String v) {
    final s = v.trim();
    if (s.isEmpty) return false;
    final parts = s.split('@');
    if (parts.length != 2) return false;
    final local = parts[0];
    final domain = parts[1];
    if (local.isEmpty || domain.isEmpty) return false;
    if (!domain.contains('.')) return false;
    if (domain.startsWith('.') || domain.endsWith('.')) return false;
    return true;
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signUp(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      final referralCode = _referralCodeController.text.trim();
      if (mounted && referralCode.isNotEmpty) {
        try {
          await ref.read(referralRepositoryProvider).applyReferralCode(referralCode);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إنشاء الحساب. كود الإحالة غير صالح أو غير نشط.')),
            );
          }
        }
      }
      if (mounted) {
        final redirect = GoRouterState.of(context).uri.queryParameters['redirect'] ?? '/home';
        context.go(redirect);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: AppText(t.signup, style: AppTextStyle.title)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const AppIcon(emoji: '✨', size: 72),
                const SizedBox(height: AppSpacing.lg),
                const AppText('إنشاء حساب جديد', style: AppTextStyle.title),
                const SizedBox(height: AppSpacing.sm),
                AppText('ابدأ رحلتك التعليمية الآن',
                    style: AppTextStyle.body, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل الاسم';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: t.email),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                    if (!_isValidEmail(v)) return 'أدخل بريداً إلكترونياً صحيحاً (مثال: name@example.com)';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: t.password),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                    if (v.length < 6) return 'كلمة المرور 6 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _referralCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'كود الإحالة (اختياري)',
                    hintText: 'مثال: MOHAMMED10',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: _loading ? '...' : t.signup,
                  onPressed: _loading ? null : _signup,
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                ),
                TextButton(
                  onPressed: () {
                    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
                    context.go(redirect != null ? '/login?redirect=${Uri.encodeComponent(redirect)}' : '/login');
                  },
                  child: const AppText(
                    'لديك حساب؟ سجّل الدخول',
                    style: AppTextStyle.body,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const AppText(
                  'باستخدام التطبيق فإنك توافق على سياسة الخصوصية وشروط الاستخدام.',
                  style: AppTextStyle.caption,
                  color: AppColors.textSecondary,
                  align: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      ),
                      child: const AppText(
                        'سياسة الخصوصية',
                        style: AppTextStyle.caption,
                        color: AppColors.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TermsOfUseScreen(),
                        ),
                      ),
                      child: const AppText(
                        'شروط الاستخدام',
                        style: AppTextStyle.caption,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

