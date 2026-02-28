import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../ui_system/app_theme.dart';
import 'data/admin_users_repository.dart';
import 'data/admin_user_model.dart';
import 'presentation/admin_users_providers.dart';
import '../../core/widgets/admin_widgets.dart';

/// تصفية حسب الاشتراك: الكل / مشترك / غير مشترك
enum _SubscriptionFilter { all, subscribed, notSubscribed }

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();
  _SubscriptionFilter _filter = _SubscriptionFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AdminTheme.background,
        appBar: AppBar(
          leading: adminAppBarLeading(context),
          title: const Text('المستخدمون'),
          backgroundColor: AdminTheme.background,
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
                data: (users) {
                  final filtered = _filterUsers(users);
                  return _UsersList(
                    users: filtered,
                    ref: ref,
                    searchController: _searchController,
                    filter: _filter,
                    onFilterChanged: (f) => setState(() => _filter = f),
                    onSearchChanged: () => setState(() {}),
                  );
                },
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

  List<AdminUser> _filterUsers(List<AdminUser> users) {
    var list = users;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((u) {
        return u.email.toLowerCase().contains(query) ||
            u.username.toLowerCase().contains(query) ||
            u.name.toLowerCase().contains(query);
      }).toList();
    }
    switch (_filter) {
      case _SubscriptionFilter.subscribed:
        list = list.where((u) => u.isSubscribed).toList();
        break;
      case _SubscriptionFilter.notSubscribed:
        list = list.where((u) => !u.isSubscribed).toList();
        break;
      case _SubscriptionFilter.all:
        break;
    }
    return list;
  }
}

/// قائمة المستخدمين — تعمل على الكمبيوتر والموبايل بدون DataTable
class _UsersList extends StatelessWidget {
  const _UsersList({
    required this.users,
    required this.ref,
    required this.searchController,
    required this.filter,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  final List<AdminUser> users;
  final WidgetRef ref;
  final TextEditingController searchController;
  final _SubscriptionFilter filter;
  final void Function(_SubscriptionFilter) onFilterChanged;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminSectionHeader(
          title: 'المستخدمون',
          subtitle: 'جميع المستخدمين المسجلين في التطبيق',
        ),
        const SizedBox(height: AppSpacing.md),
        // البحث: بالإيميل أو اسم المستخدم
        TextField(
          controller: searchController,
          onChanged: (_) => onSearchChanged(),
          decoration: InputDecoration(
            hintText: 'بحث بالإيميل أو اسم المستخدم أو الاسم...',
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            ),
            filled: true,
            fillColor: AdminTheme.surface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // تصفية: مشترك / غير مشترك / الكل
        Row(
          children: [
            Text(
              'التصفية:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AdminTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: const Text('الكل'),
              selected: filter == _SubscriptionFilter.all,
              onSelected: (_) => onFilterChanged(_SubscriptionFilter.all),
            ),
            const SizedBox(width: AppSpacing.xs),
            ChoiceChip(
              label: const Text('مشترك'),
              selected: filter == _SubscriptionFilter.subscribed,
              onSelected: (_) => onFilterChanged(_SubscriptionFilter.subscribed),
            ),
            const SizedBox(width: AppSpacing.xs),
            ChoiceChip(
              label: const Text('غير مشترك'),
              selected: filter == _SubscriptionFilter.notSubscribed,
              onSelected: (_) => onFilterChanged(_SubscriptionFilter.notSubscribed),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (users.isEmpty)
          const Expanded(
            child: Center(child: Text('لا توجد نتائج')),
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
                                borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
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
                            color: AdminTheme.textMuted,
                          ),
                        ),
                        if (user.username.isNotEmpty && user.username != '—')
                          Text(
                            'اسم المستخدم: ${user.username}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AdminTheme.textMuted,
                            ),
                          ),
                        Text(
                          '${user.role} • ${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AdminTheme.textMuted,
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

