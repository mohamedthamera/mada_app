import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../app/di.dart';
import '../../../core/widgets/widgets.dart';
import '../data/referral_repository.dart';
import 'referral_providers.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _applyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل كود الإحالة')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final name = await ref.read(referralRepositoryProvider).applyReferralCode(code);
      if (!mounted) return;
      ref.invalidate(userReferralProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تطبيق الكود بنجاح. شكراً لاستخدامك كود: $name'),
          backgroundColor: Colors.green,
        ),
      );
      _codeController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final referralAsync = ref.watch(userReferralProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('كود الإحالة', style: AppTextStyle.title),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: referralAsync.when(
            data: (referral) {
              if (referral != null) {
                final codeUsed = referral['code_used'] as String? ?? '';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppIcon(emoji: '✅', size: 64),
                    const SizedBox(height: AppSpacing.lg),
                    const AppText(
                      'تم استخدام كود إحالة',
                      style: AppTextStyle.title,
                      align: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        codeUsed,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppText(
                      'لا يمكن تغيير كود الإحالة بعد الاستخدام.',
                      style: AppTextStyle.caption,
                      color: AppColors.textSecondary,
                      align: TextAlign.center,
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppIcon(emoji: '🎁', size: 64),
                  const SizedBox(height: AppSpacing.lg),
                  const AppText(
                    'أدخل كود الإحالة',
                    style: AppTextStyle.title,
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppText(
                    'إذا حصلت على كود من مؤثر أو شريك، أدخله هنا.',
                    style: AppTextStyle.body,
                    color: AppColors.textSecondary,
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'كود الإحالة',
                      hintText: 'مثال: MOHAMMED10',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _applyCode(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: _loading ? 'جاري التطبيق...' : 'تطبيق الكود',
                    onPressed: _loading ? null : _applyCode,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: AppText(
                'حدث خطأ في التحميل',
                style: AppTextStyle.body,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
