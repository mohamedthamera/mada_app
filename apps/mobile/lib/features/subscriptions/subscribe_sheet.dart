import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscribeSheet extends StatefulWidget {
  const SubscribeSheet({super.key, this.onRedeemed});

  /// يُستدعى بعد تفعيل الاشتراك بنجاح (كود أو دفع) لتحديث الواجهة.
  final VoidCallback? onRedeemed;

  @override
  State<SubscribeSheet> createState() => _SubscribeSheetState();
}

class _SubscribeSheetState extends State<SubscribeSheet> {
  bool _busy = false;
  bool _isLifetime = false;
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final supabase = Supabase.instance.client;
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final resp = await supabase.from('user_subscriptions').select('is_lifetime').eq('user_id', uid).maybeSingle();
    if (mounted) {
      setState(() {
        _isLifetime = (resp?['is_lifetime'] ?? false) as bool;
      });
    }
  }

  Future<void> _redeemCode() async {
    if (_busy) return;
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.rpc('redeem_lifetime_code', params: {'p_code': code});
      if (!mounted) return;
      await _loadStatus();
      if (mounted) {
        widget.onRedeemed?.call();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التفعيل! اشتراكك مدى الحياة مفعّل الآن.')));
        Navigator.of(context).maybePop();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        final msg = e.message.toLowerCase();
        String text = e.message;
        if (msg.contains('invalid_code')) text = 'كود غير صحيح. تحقق من الرمز وأعد المحاولة.';
        else if (msg.contains('expired_code')) text = 'انتهت صلاحية هذا الكود.';
        else if (msg.contains('already_redeemed')) text = 'تم استخدام هذا الكود مسبقاً.';
        else if (msg.contains('code_exhausted')) text = 'تم استنفاد عدد استخدامات هذا الكود.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التفعيل: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startGateway() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final resp = await Supabase.instance.client.functions.invoke('create_payment_session', body: {
        'provider': 'custom',
        'amount': 99.00,
        'currency': 'USD',
      });
      final data = resp.data as Map<String, dynamic>? ?? {};
      final url = data['payment_url']?.toString() ?? '';
      if (!mounted) return;
      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create session')));
      } else {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Open this URL in your browser to pay:'),
                const SizedBox(height: 8),
                SelectableText(url),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Clipboard.setData(ClipboardData(text: url)),
                  child: const Text('Copy URL'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Done')),
            ],
          ),
        );
        await _pollForUnlock();
        await _loadStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pollForUnlock() async {
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final before = _isLifetime;
      await _loadStatus();
      if (_isLifetime && !before) break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الاشتراك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (_isLifetime) const Chip(label: Text('مفعل مدى الحياة')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'رمز التفعيل'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _redeemCode,
                    child: const Text('استخدم كود'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _startGateway,
                    child: const Text('الدفع عبر بوابة خارجية'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

Future<void> showSubscribeSheet(BuildContext context, {VoidCallback? onRedeemed}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SubscribeSheet(onRedeemed: onRedeemed),
    ),
  );
}
