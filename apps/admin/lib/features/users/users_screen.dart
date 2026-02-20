import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'data/admin_users_repository.dart';
import 'data/admin_user_model.dart';
import 'presentation/admin_users_providers.dart';
import '../../core/constants/admin_breakpoints.dart';
import '../../core/widgets/admin_widgets.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AdminBreakpoints.isMobile(context);
    final padding = EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: adminAppBarLeading(context),
          title: const Text('المستخدمون'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(adminUsersProvider),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Padding(
          padding: padding,
          child: ref.watch(adminUsersProvider).when(
                data: (users) {
                  if (isMobile) {
                    return _UsersMobileList(users: users, ref: ref);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionHeader(
                        title: 'المستخدمون',
                        subtitle: 'جميع المستخدمين المسجلين في التطبيق',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: AdminCard(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable2(
                              columns: const [
                                DataColumn(label: Text('الاسم')),
                                DataColumn(label: Text('البريد')),
                                DataColumn(label: Text('الدور')),
                                DataColumn(label: Text('التسجيل')),
                                DataColumn(label: Text('الاشتراك')),
                                DataColumn(label: Text('إجراءات')),
                              ],
                              rows: users
                                  .map(
                                    (user) => DataRow(
                                      cells: [
                                        DataCell(Text(user.name)),
                                        DataCell(Text(user.email)),
                                        DataCell(Text(user.role)),
                                        DataCell(Text(
                                          '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                                        )),
                                        DataCell(Text(
                                          user.isSubscribed ? 'نعم' : 'لا',
                                          style: TextStyle(
                                            color: user.isSubscribed
                                                ? Colors.green.shade700
                                                : null,
                                            fontWeight: user.isSubscribed
                                                ? FontWeight.w600
                                                : null,
                                          ),
                                        )),
                                        DataCell(
                                          _SubscriptionActionButtons(
                                            user: user,
                                            onDone: () =>
                                                ref.invalidate(adminUsersProvider),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text('تعذر تحميل المستخدمين: $e'),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

class _UsersMobileList extends StatelessWidget {
  const _UsersMobileList({required this.users, required this.ref});

  final List<AdminUser> users;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionHeader(
          title: 'المستخدمون',
          subtitle: 'جميع المستخدمين المسجلين في التطبيق',
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final user = users[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AdminCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: user.isSubscribed
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            user.isSubscribed ? 'مشترك' : 'غير مشترك',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: user.isSubscribed
                                  ? Colors.green.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '${user.role} • ${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _SubscriptionActionButtons(
                      user: user,
                      onDone: () => ref.invalidate(adminUsersProvider),
                    ),
                  ],
                ),
              ),
            );
            },
          ),
        ),
      ],
    );
  }
}

class _SubscriptionActionButtons extends ConsumerStatefulWidget {
  const _SubscriptionActionButtons({
    required this.user,
    required this.onDone,
  });

  final AdminUser user;
  final VoidCallback onDone;

  @override
  ConsumerState<_SubscriptionActionButtons> createState() =>
      _SubscriptionActionButtonsState();
}

class _SubscriptionActionButtonsState
    extends ConsumerState<_SubscriptionActionButtons> {
  bool _loading = false;

  Future<void> _activate() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(adminUsersRepositoryProvider).activateSubscription(widget.user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تفعيل الاشتراك للمستخدم')),
        );
        widget.onDone();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التفعيل: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoke() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(adminUsersRepositoryProvider).revokeSubscription(widget.user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء اشتراك المستخدم')),
        );
        widget.onDone();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإلغاء: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (widget.user.isSubscribed) {
      return TextButton.icon(
        onPressed: _revoke,
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: const Text('إلغاء الاشتراك'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red.shade700,
        ),
      );
    }
    return TextButton.icon(
      onPressed: _activate,
      icon: const Icon(Icons.check_circle_outline, size: 18),
      label: const Text('تفعيل الاشتراك'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.green.shade700,
      ),
    );
  }
}

