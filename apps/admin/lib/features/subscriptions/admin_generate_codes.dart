import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/shared.dart';

// ignore: deprecated_member_use
import 'dart:html' if (dart.library.io) 'admin_generate_codes_stub.dart' as html;

class AdminGenerateCodes extends StatefulWidget {
  const AdminGenerateCodes({super.key});

  @override
  State<AdminGenerateCodes> createState() => _AdminGenerateCodesState();
}

class _AdminGenerateCodesState extends State<AdminGenerateCodes> {
  final _quantityController = TextEditingController(text: '10');
  DateTime? _expiresAt;
  bool _isLoading = false;
  List<Map<String, String>> _generatedCodes = [];
  String? _error;
  String? _csvData;
  String? _statusMessage;
  String? _currentRole; // من جدول profiles للتحقق

  static const int _maxCount = 1000;
  static const int _minCount = 1;

  Future<void> _fetchCurrentRole() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', session.user.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _currentRole = res != null && res['role'] != null
              ? res['role'].toString().trim()
              : null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _currentRole = null);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrentRole();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  int _getCount() {
    final n = int.tryParse(_quantityController.text);
    if (n == null || n < _minCount) return _minCount;
    if (n > _maxCount) return _maxCount;
    return n;
  }

  String _csvFromRows(List<dynamic> rows) {
    final lines = <String>['code,expires_at,max_redemptions'];
    for (final r in rows) {
      if (r is Map<String, dynamic>) {
        final c = r['code'] ?? '';
        final e = r['expires_at'] ?? '';
        final m = r['max_redemptions'] ?? 1;
        lines.add('"$c","$e","$m"');
      }
    }
    return lines.join('\n');
  }

  String _maskCode(String code) {
    if (code.length <= 8) return code;
    return '${code.substring(0, 4)}****${code.substring(code.length - 4)}';
  }

  Future<void> _generateCodes() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _statusMessage = 'جاري التوليد...';
    });

    try {
      final supabase = Supabase.instance.client;

      final session = supabase.auth.currentSession;
      if (session == null) {
        if (mounted) {
          setState(() {
            _error = 'يجب تسجيل الدخول أولاً';
            _statusMessage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login as admin to access this feature'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final count = _getCount();
      final params = <String, dynamic>{
        'p_count': count,
        'p_max_redemptions': 1,
      };
      if (_expiresAt != null) {
        params['p_expires_at'] = _expiresAt!.toIso8601String();
      }

      if (mounted) setState(() => _statusMessage = 'جاري توليد $count كود...');

      final result = await supabase.rpc(
        'admin_generate_lifetime_codes',
        params: params,
      );

      if (result is! List || result.isEmpty) {
        throw Exception('لم تُرجع الدالة أي أكواد');
      }

      final rows = result.cast<dynamic>();
      final csv = _csvFromRows(rows);

      if (!mounted) return;
      setState(() {
        _generatedCodes = rows.map((r) {
          final codeStr = r is Map<String, dynamic>
              ? (r['code'] as String? ?? '')
              : r.toString();
          return {'code': codeStr, 'mask': _maskCode(codeStr)};
        }).toList();
        _csvData = csv;
        _error = null;
        _statusMessage = 'تم توليد ${rows.length} كود بنجاح';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم توليد ${rows.length} كود بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      _showDownloadDialog(csv, rows.length);
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      final userEmail = Supabase.instance.client.auth.currentSession?.user.email ?? 'بريدك@example.com';
      String userMessage;
      if (msg.contains('not authenticated') || msg.contains('jwt')) {
        userMessage = 'انتهت الجلسة. سجّل الدخول مرة أخرى.';
      } else if (msg.contains('no profile found') || msg.contains('forbidden') || msg.contains('admin required')) {
        userMessage = 'صلاحية الأدمن مطلوبة.\n'
            'في Supabase: SQL Editor → نفّذ:\n'
            "select set_admin_by_email('$userEmail');";
      } else if (msg.contains('user_id=') || msg.contains('role=')) {
        userMessage = '${e.message}\n\nلتفعيل الصلاحيات في Supabase → SQL Editor:\n'
            "select set_admin_by_email('$userEmail');";
      } else {
        userMessage = e.message;
      }
      if (mounted) {
        setState(() {
          _error = userMessage;
          _statusMessage = 'فشل التوليد';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage.split('\n').first), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      final userEmail = Supabase.instance.client.auth.currentSession?.user.email ?? 'بريدك@example.com';
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ.\nفي Supabase → SQL Editor نفّذ:\n'
              "select set_admin_by_email('$userEmail');";
          _statusMessage = 'فشل التوليد';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التوليد. تحقق من صلاحيات الأدمن (انظر الصندوق الأحمر أعلاه).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDownloadDialog(String csvString, int codeCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تم توليد الأكواد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تم توليد $codeCount كود اشتراك دائم.'),
            const SizedBox(height: 16),
            const Text('هل تريد تحميل ملف CSV؟'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('لا'),
          ),
          FilledButton(
            onPressed: () {
              _downloadCSV(csvString);
              Navigator.of(ctx).pop();
            },
            child: const Text('تحميل CSV'),
          ),
        ],
      ),
    );
  }

  void _downloadCSV(String csvString) {
    if (kIsWeb) {
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..setAttribute('download', 'lifetime_codes_${DateTime.now().millisecondsSinceEpoch}.csv');
      anchor.click();
      html.Url.revokeObjectUrl(url);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('بيانات CSV'),
          content: SingleChildScrollView(
            child: SelectableText(csvString),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csvString));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم النسخ إلى الحافظة')),
                );
              },
              child: const Text('نسخ'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    }
  }

  void _copyAllCodes() {
    final codes = _generatedCodes.map((c) => c['code']).join('\n');
    Clipboard.setData(ClipboardData(text: codes));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ كل الأكواد')),
    );
  }

  Future<void> _selectExpirationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) setState(() => _expiresAt = date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توليد أكواد الاشتراك الدائم',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'إنشاء أكواد قابلة للاستخدام لتفعيل الاشتراك مدى الحياة',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Builder(
            builder: (context) {
              final session = Supabase.instance.client.auth.currentSession;
              final email = session?.user.email ?? '—';
              final roleOk = _currentRole != null &&
                  _currentRole!.toLowerCase().contains('admin');
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: roleOk
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.textMuted.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: roleOk
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      roleOk ? Icons.verified_user : Icons.info_outline,
                      size: 18,
                      color: roleOk ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'البريد: $email  |  الدور: ${_currentRole ?? 'جاري التحقق...'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (!roleOk && _currentRole != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'لتفعيل الأدمن: Supabase → SQL Editor → select set_admin_by_email(\'$email\');',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: _isLoading ? null : () => _fetchCurrentRole(),
                      tooltip: 'تحديث الدور',
                    ),
                    if (!roleOk && _currentRole != null)
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text: "select set_admin_by_email('$email');",
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم نسخ الجملة إلى الحافظة')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('نسخ'),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'الكمية',
                    hintText: 'عدد الأكواد',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _selectExpirationDate,
                  child: Text(
                    _expiresAt == null
                        ? 'تحديد انتهاء'
                        : '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}',
                  ),
                ),
              ),
              if (_expiresAt != null)
                IconButton(
                  onPressed: _isLoading ? null : () => setState(() => _expiresAt = null),
                  icon: const Icon(Icons.clear),
                  tooltip: 'إلغاء الانتهاء',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => _quantityController.text = '10',
                child: const Text('10'),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => _quantityController.text = '100',
                child: const Text('100'),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => _quantityController.text = '1000',
                child: const Text('1000'),
              ),
            ],
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(_statusMessage!, style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SelectableText(
                      _error!,
                      style: TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                  if (_error!.contains('set_admin_by_email'))
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        final match = RegExp(r"select set_admin_by_email\('[^']+'\)")
                            .firstMatch(_error!);
                        if (match != null) {
                          Clipboard.setData(
                              ClipboardData(text: '${match.group(0)};'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ الجملة')),
                          );
                        }
                      },
                      tooltip: 'نسخ جملة SQL',
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _isLoading ? null : _generateCodes,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.generating_tokens),
            label: Text(_isLoading ? 'جاري التوليد...' : 'توليد الأكواد'),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
          if (_generatedCodes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'الأكواد المُولَّدة (${_generatedCodes.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _copyAllCodes,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('نسخ الكل'),
                ),
                if (_csvData != null)
                  TextButton.icon(
                    onPressed: () => _downloadCSV(_csvData!),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('تحميل CSV'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _generatedCodes.length > 20 ? 20 : _generatedCodes.length,
                itemBuilder: (context, index) {
                  final codeData = _generatedCodes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  codeData['code']!,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: codeData['code']!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم النسخ')),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: 'نسخ',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'إخفاء: ${codeData['mask']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_generatedCodes.length > 20)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'عرض أول 20 من ${_generatedCodes.length}. استخدم "نسخ الكل" لجميع الأكواد.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
