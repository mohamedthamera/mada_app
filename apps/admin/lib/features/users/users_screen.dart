import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'data/admin_users_repository.dart';
import 'data/admin_user_model.dart';
import 'presentation/admin_users_providers.dart';
import '../../core/widgets/admin_widgets.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: adminAppBarLeading(context),
          title: const Text('المستخدمون'),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(adminUsersProvider),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: AdminPageBody(
          child: ref.watch(adminUsersProvider).when(
                data: (users) => _UsersList(users: users, ref: ref),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('تعذر تحميل المستخدمين', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('$e', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => ref.invalidate(adminUsersProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

/// قائمة المستخدمين — تعمل على الكمبيوتر والموبايل بدون DataTable
class _UsersList extends StatelessWidget {
  const _UsersList({required this.users, required this.ref});

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
        if (users.isEmpty)
          const Expanded(
            child: Center(child: Text('لا يوجد مستخدمون مسجلون حالياً')),
          )
        else
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

