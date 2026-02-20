import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'presentation/admin_influencer_providers.dart';
import '../../core/widgets/admin_widgets.dart';
import 'data/admin_influencer_repository.dart';

class InfluencersScreen extends ConsumerStatefulWidget {
  const InfluencersScreen({super.key});

  @override
  ConsumerState<InfluencersScreen> createState() => _InfluencersScreenState();
}

class _InfluencersScreenState extends ConsumerState<InfluencersScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _createLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createInfluencer() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الاسم والكود مطلوبان')),
      );
      return;
    }
    setState(() => _createLoading = true);
    try {
      await ref.read(adminInfluencerRepositoryProvider).create(name: name, code: code);
      if (!mounted) return;
      ref.invalidate(adminInfluencersProvider);
      _nameController.clear();
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء كود المؤثر بنجاح'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _createLoading = false);
    }
  }

  Future<void> _toggleActive(String id) async {
    try {
      await ref.read(adminInfluencerRepositoryProvider).toggleActive(id);
      if (!mounted) return;
      ref.invalidate(adminInfluencersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الحالة'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المؤثر'),
        content: const Text(
          'سيتم إخفاء الكود (حذف تدريجي). المستخدمون المُحالون سيبقون مرتبطين. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('نعم')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminInfluencerRepositoryProvider).delete(id);
      if (!mounted) return;
      ref.invalidate(adminInfluencersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحذف التدريجي'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final influencersAsync = ref.watch(adminInfluencersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: adminAppBarLeading(context),
        title: const Text('أكواد المؤثرين / الإحالة'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(adminInfluencersProvider),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionHeader(
              title: 'إنشاء كود مؤثر',
              subtitle: 'اسم المؤثر والكود العام (مثل MOHAMMED10)',
            ),
            const SizedBox(height: AppSpacing.lg),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      hintText: 'اسم المؤثر أو الشريك',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'الكود',
                      hintText: 'MOHAMMED10',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _createLoading ? null : _createInfluencer,
                    child: _createLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('إنشاء'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AdminSectionHeader(
              title: 'قائمة المؤثرين',
              subtitle: 'إجمالي المستخدمين المُحالين لكل كود',
            ),
            const SizedBox(height: AppSpacing.lg),
            influencersAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return AdminCard(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: AppColors.textMuted.withValues(alpha: 0.6)),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'لا يوجد مؤثرون بعد',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return AdminCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, i) {
                      final row = list[i];
                      final id = row['influencer_id'] ?? row['id'] ?? '';
                      final name = row['influencer_name'] ?? row['name'] ?? '—';
                      final code = row['referral_code'] ?? row['code'] ?? '—';
                      final totalUsers = row['total_users'] is int
                          ? row['total_users'] as int
                          : (int.tryParse(row['total_users'].toString()) ?? 0);
                      final isActive = row['is_active'] as bool? ?? true;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : AppColors.textMuted.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                code,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? AppColors.primary : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text('المستخدمون المُحالون: $totalUsers'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isActive ? Icons.toggle_on : Icons.toggle_off,
                                color: isActive ? AppColors.primary : AppColors.textMuted,
                                size: 36,
                              ),
                              onPressed: () => _toggleActive(id.toString()),
                              tooltip: isActive ? 'تعطيل' : 'تفعيل',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                              onPressed: () => _delete(id.toString()),
                              tooltip: 'حذف تدريجي',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const AdminCard(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => AdminCard(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        e.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.danger),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(adminInfluencersProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
