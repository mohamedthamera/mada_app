import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/admin_breakpoints.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../ui_system/app_theme.dart';
import 'notifications_repository.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;
  int _usersCount = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadUsersCount();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadUsersCount() async {
    try {
      final repository = ref.read(notificationsRepositoryProvider);
      final users = await repository.getAllUsersWithTokens();
      if (mounted) {
        setState(() {
          _usersCount = users.length;
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load users: $e');
      if (mounted) {
        setState(() => _initialized = true);
      }
    }
  }

  Future<void> _sendNotification() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      _showSnackBar('يرجى إدخال عنوان الإشعار', isError: true);
      return;
    }

    if (body.isEmpty) {
      _showSnackBar('يرجى إدخال نص الإشعار', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(notificationsRepositoryProvider);
      final result = await repository.sendNotificationToAllBatched(
        title: title,
        body: body,
      );

      if (result.success) {
        if (result.totalUsers == 0) {
          _showSnackBar('لا يوجد مستخدمين مسجلين للإشعارات', isError: true);
        } else {
          _showSnackBar(
            'تم إرسال الإشعار بنجاح إلى ${result.successCount} مستخدم',
          );
          _titleController.clear();
          _bodyController.clear();
        }
      } else {
        _showSnackBar(
          'فشل إرسال الإشعار: ${result.error ?? "خطأ غير معروف"}',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('فشل إرسال الإشعار: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AdminTheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AdminTheme.background,
        appBar: AppBar(
          leading: adminAppBarLeading(context),
          title: const Text('إرسال إشعارات'),
          backgroundColor: AdminTheme.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadUsersCount,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: AdminPageBody(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              AdminBreakpoints.isMobile(context) ? 16 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMainCard(),
                const SizedBox(height: 24),
                _buildInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return AdminCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: AdminTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إرسال إشعار لجميع المستخدمين',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _initialized
                          ? '$_usersCount مستخدم مسجلين للإشعارات'
                          : 'جارٍ التحميل...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AdminTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'عنوان الإشعار',
              hintText: 'مثال: دورة جديدة متاحة',
              prefixIcon: const Icon(Icons.title_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AdminTheme.surface,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bodyController,
            decoration: InputDecoration(
              labelText: 'نص الإشعار',
              hintText: 'مثال: تم إضافة دورة جديدة في البرمجة',
              prefixIcon: const Icon(Icons.message_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AdminTheme.surface,
            ),
            maxLines: 4,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _sendNotification,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_isLoading ? 'جارٍ الإرسال...' : 'إرسال الإشعار'),
              style: FilledButton.styleFrom(
                backgroundColor: AdminTheme.primary,
                foregroundColor: AdminTheme.primaryForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return AdminCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AdminTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'معلومات مهمة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.check_circle_outline,
            'الإشعار يصل للمستخدمين الذين فعّلوا الإشعارات فقط',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.phone_android_outlined,
            'الإشعار يظهر حتى لو كان التطبيق مغلق أو في الخلفية',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.speed_rounded,
            'يتم إرسال الإشعار فوراً عبر Supabase Edge Function',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AdminTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: AdminTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
