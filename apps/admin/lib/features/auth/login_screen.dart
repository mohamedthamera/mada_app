import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/di.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../ui_system/app_theme.dart';

String _authErrorMessage(dynamic e) {
  final msg = e.toString().toLowerCase();
  final is404 = msg.contains('404') || (e is AuthException && e.statusCode == '404');
  if (is404) {
    return 'الخادم غير متاح (404). تحقق من أن SUPABASE_URL في ملف .env صحيح وأن مشروع Supabase يعمل في اللوحة.';
  }
  if (e is AuthException) {
    final authMsg = e.message.toLowerCase();
    if (authMsg.contains('invalid') || authMsg.contains('credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    }
    if (authMsg.contains('confirm') || authMsg.contains('verified')) {
      return 'يجب تأكيد البريد أولاً من الرابط المرسل إلى بريدك.';
    }
    if (authMsg.contains('already') || authMsg.contains('registered')) {
      return 'هذا البريد مسجّل مسبقاً. جرّب تسجيل الدخول.';
    }
    if (authMsg.contains('email')) return 'تحقق من البريد الإلكتروني.';
    return e.message.isNotEmpty ? e.message : 'تعذر تنفيذ العملية.';
  }
  return e.toString();
}

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key, this.reason});

  final String? reason;

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reason = widget.reason;
      if (reason == 'not_admin' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'حسابك ليس لديه صلاحيات الأدمن. تواصل مع المسؤول لتفعيل الصلاحيات أو تأكد من تعيين دورك في قاعدة البيانات.',
            ),
            duration: Duration(seconds: 6),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (reason == 'error' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في التحقق من الصلاحيات. تأكد من وجود عمود role في جدول profiles.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل البريد وكلمة المرور')),
        );
      }
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(supabaseClientProvider).auth.signInWithPassword(
            email: email,
            password: password,
          );
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authErrorMessage(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل البريد وكلمة المرور')),
        );
      }
      return;
    }
    if (password.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كلمة المرور 6 أحرف على الأقل')),
        );
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await ref.read(supabaseClientProvider).auth.signUp(
            email: email,
            password: password,
            data: {'name': name.isEmpty ? 'أدمن' : name},
          );
      if (!mounted) return;
      if (response.session != null) {
        context.go('/dashboard');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الحساب وتسجيل الدخول.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحساب. راجع بريدك لتأكيد الرابط ثم سجّل الدخول.'),
            duration: Duration(seconds: 5),
          ),
        );
        setState(() => _isSignUp = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authErrorMessage(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AdminTheme.background,
                AdminTheme.surfaceVariant,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: AdminCard(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            height: 72,
                            width: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AdminTheme.primaryDark, AdminTheme.primary],
                              ),
                              borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                              boxShadow: [
                                BoxShadow(
                                  color: AdminTheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: AdminTheme.primaryForeground,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'مرحباً بعودتك',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'سجّل دخولك لإدارة منصة Everest',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (_isSignUp) ...[
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'الاسم',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 22),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email_outlined, size: 22),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            hintText: _isSignUp ? '6 أحرف على الأقل' : null,
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 22),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed: _loading ? null : (_isSignUp ? _signUp : _login),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: Text(
                            _loading ? 'جاري التحقق...' : (_isSignUp ? 'إنشاء الحساب' : 'دخول'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp
                                ? 'لديك حساب؟ تسجيل الدخول'
                                : 'ليس لديك حساب؟ إنشاء حساب',
                            style: TextStyle(color: AdminTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
