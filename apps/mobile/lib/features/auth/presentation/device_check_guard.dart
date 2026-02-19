import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/di.dart';
import '../data/device_check_repository.dart';
import '../data/supabase_auth_repository.dart';

/// يلف المحتوى المحمي: يتحقق من الجهاز عند وجود جلسة.
/// إن كان الحساب محظوراً (فتح من جهاز آخر) يُسجّل الخروج ويوجّه لشاشة تسجيل الدخول مع رسالة حظر.
class DeviceCheckGuard extends ConsumerStatefulWidget {
  const DeviceCheckGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeviceCheckGuard> createState() => _DeviceCheckGuardState();
}

class _DeviceCheckGuardState extends ConsumerState<DeviceCheckGuard> {
  bool _checked = false;
  bool _allowed = false;
  bool _checking = false;

  Future<void> _runCheck() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() { _checked = true; _allowed = true; });
      return;
    }
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final result = await ref.read(deviceCheckRepositoryProvider).checkDeviceOrRegister();
      if (!mounted) return;
      if (result.banned) {
        await ref.read(authRepositoryProvider).signOut();
        if (mounted) {
          context.go('/login?banned=1');
        }
        return;
      }
      setState(() {
        _checked = true;
        _allowed = result.allowed;
        _checking = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _checked = true;
          _allowed = true;
          _checking = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checked && !_checking) _runCheck();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return widget.child;
    if (!_checked || _checking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'جاري التحقق من الجهاز...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (!_allowed) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 64, color: AppColors.danger),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'حسابك محظور',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'تم فتح الحساب من أكثر من جهاز. للحفاظ على أمان المحتوى تم حظر الحساب. تواصل مع الدعم إذا كنت تحتاج مساعدة.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (mounted) context.go('/login?banned=1');
                  },
                  child: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
