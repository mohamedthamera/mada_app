import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../../core/widgets/widgets.dart';
import '../../profile/presentation/info_screens/privacy_policy_screen.dart';
import '../../profile/presentation/info_screens/terms_of_use_screen.dart';
import '../data/auth_error_helper.dart';
import '../data/supabase_auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static bool _isValidEmail(String v) {
    final s = v.trim();
    if (s.isEmpty) return false;
    final parts = s.split('@');
    if (parts.length != 2) return false;
    final local = parts[0], domain = parts[1];
    if (local.isEmpty || domain.isEmpty) return false;
    if (!domain.contains('.')) return false;
    if (domain.startsWith('.') || domain.endsWith('.')) return false;
    return true;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
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
    final banned = GoRouterState.of(context).uri.queryParameters['banned'] == '1';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: AppText(t.login, style: AppTextStyle.title)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (banned)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppText(
                            'تم حظر الحساب لأنه تم فتحه من أكثر من جهاز. للحفاظ على أمان المحتوى يُسمح بجهاز واحد فقط.',
                            style: AppTextStyle.body,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                const AppIcon(emoji: '🎓', size: 72),
                const SizedBox(height: AppSpacing.lg),
                const AppText('أهلاً بعودتك', style: AppTextStyle.title),
                const SizedBox(height: AppSpacing.sm),
                AppText('سجل دخولك للمتابعة',
                    style: AppTextStyle.body, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: t.email),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                    if (!_isValidEmail(v)) return 'أدخل بريداً إلكترونياً صحيحاً';
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
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: _loading ? '...' : t.login,
                  variant: AppButtonVariant.secondary,
                  onPressed: _loading ? null : _login,
                ),
                TextButton(
                  onPressed: () {
                    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
                    context.go(redirect != null ? '/signup?redirect=${Uri.encodeComponent(redirect)}' : '/signup');
                  },
                  child: AppText(
                    t.signup,
                    style: AppTextStyle.body,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppText(
                  'باستخدام التطبيق فإنك توافق على',
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
                    AppText(' و ', style: AppTextStyle.caption, color: AppColors.textSecondary),
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

