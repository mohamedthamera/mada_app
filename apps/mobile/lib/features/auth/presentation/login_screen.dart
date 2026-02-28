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
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _resetLoading = false;
  final _resetEmailController = TextEditingController();
  final _resetFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    final v = _emailOrUsernameController.text.trim();
    _resetEmailController.text = v.contains('@') ? v : '';
    final sent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const AppText('إعادة تعيين كلمة المرور', style: AppTextStyle.title),
          content: SingleChildScrollView(
            child: Form(
              key: _resetFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText(
                    'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.',
                    style: AppTextStyle.body,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      hintText: 'example@email.com',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                      if (!_isValidEmail(v)) return 'أدخل بريداً إلكترونياً صحيحاً';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _resetLoading ? null : () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: _resetLoading
                  ? null
                  : () async {
                      if (!_resetFormKey.currentState!.validate()) return;
                      setState(() => _resetLoading = true);
                      try {
                        await ref.read(authRepositoryProvider).resetPasswordForEmail(
                              _resetEmailController.text.trim(),
                            );
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(authErrorMessage(e))),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _resetLoading = false);
                      }
                    },
              child: _resetLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('إرسال الرابط'),
            ),
          ],
        ),
      ),
    );
    if (mounted && sent == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رابط إعادة التعيين إلى بريدك. راجع بريدك واضغط الرابط لتعيين كلمة مرور جديدة.'),
        ),
      );
    }
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
            emailOrUsername: _emailOrUsernameController.text.trim(),
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
                  controller: _emailOrUsernameController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني أو اسم المستخدم',
                    hintText: 'example@email.com أو اسم المستخدم',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني أو اسم المستخدم';
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
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading ? null : _showForgotPasswordDialog,
                    child: AppText(
                      'هل نسيت كلمة المرور؟',
                      style: AppTextStyle.body,
                      color: AppColors.primary,
                    ),
                  ),
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

