import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/di.dart';
import '../../../core/widgets/widgets.dart';
import 'subscription_providers.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final _voucherController = TextEditingController();
  bool _codeLoading = false;
  String? _message;

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _redeemCode() async {
    if (_codeLoading) return;
    final code = _voucherController.text.trim();
    if (code.isEmpty) {
      setState(() => _message = 'أدخل رمز القسيمة');
      return;
    }
    final client = ref.read(supabaseClientProvider);
    if (client.auth.currentUser == null) {
      if (!mounted) return;
      context.go('/login');
      return;
    }
    setState(() {
      _codeLoading = true;
      _message = null;
    });
    try {
      await client.rpc('redeem_lifetime_code', params: {'p_code': code});
      if (!mounted) return;
      ref.invalidate(hasActiveSubscriptionProvider);
      _voucherController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم التفعيل! اشتراكك مفعّل الآن.')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      String text = e.message;
      if (msg.contains('invalid_code')) text = 'قسيمة غير صحيحة. تحقق من الرمز وأعد المحاولة.';
      else if (msg.contains('expired_code')) text = 'انتهت صلاحية هذه القسيمة.';
      else if (msg.contains('already_redeemed')) text = 'تم استخدام هذه القسيمة مسبقاً.';
      else if (msg.contains('code_exhausted')) text = 'تم استنفاد عدد استخدامات هذه القسيمة.';
      setState(() => _message = text);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) setState(() => _message = 'فشل التفعيل. أعد المحاولة.');
    } finally {
      if (mounted) setState(() => _codeLoading = false);
    }
  }

  Widget _buildSubscribedView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText('أنت مشترك', style: AppTextStyle.headline, color: Colors.green.shade800),
                        const SizedBox(height: 4),
                        AppText(
                          'اشتراكك مفعّل. يمكنك الاستفادة من كل محتوى التطبيق.',
                          style: AppTextStyle.body,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// على أندرويد: فقط حقل القسيمة وزر التفعيل — بدون سعر ولا مميزات.
  Widget _buildAndroidVoucherOnly(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText('القسيمة', style: AppTextStyle.title),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                'أدخل القسيمة.',
                style: AppTextStyle.body,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _voucherController,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'XXXX-XXXX-XXXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: _codeLoading ? 'جاري التفعيل...' : 'تفعيل',
                icon: Icons.check_circle,
                onPressed: _codeLoading ? null : _redeemCode,
              ),
              if (_message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: AppText(
                    _message!,
                    style: AppTextStyle.caption,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// على iOS: رسالة اعتذار وزر واتساب للمساعدة.
  Widget _buildIosNoPaymentView(BuildContext context) {
    const whatsAppUrl = 'https://wa.me/9647500000000'; // غيّر الرقم حسب رقم الدعم
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              'نعتذر منك، لا تتوفر طريقة الدفع. للمساعدة تواصل معنا.',
              style: AppTextStyle.title,
              align: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'واتساب - التواصل للمساعدة',
              icon: Icons.chat,
              onPressed: () async {
                final uri = Uri.parse(whatsAppUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeOfferView(BuildContext context) {
    if (Platform.isAndroid) {
      return _buildAndroidVoucherOnly(context);
    }
    if (Platform.isIOS) {
      return _buildIosNoPaymentView(context);
    }
    return _buildAndroidVoucherOnly(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasSubAsync = ref.watch(hasActiveSubscriptionProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('الاشتراك', style: AppTextStyle.title),
        ),
        body: hasSubAsync.when(
          data: (isSubscribed) {
            if (isSubscribed) {
              return _buildSubscribedView(context);
            }
            return _buildSubscribeOfferView(context);
          },
          loading: () => _buildSubscribeOfferView(context),
          error: (_, __) => _buildSubscribeOfferView(context),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppText(
              text,
              style: AppTextStyle.body,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
