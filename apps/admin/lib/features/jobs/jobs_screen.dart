import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../core/constants/admin_breakpoints.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../ui_system/app_theme.dart';
import 'data/admin_jobs_repository.dart';
import 'presentation/admin_jobs_providers.dart';

/// استخراج نص من خريطة الوظيفة دون رمي استثناء
String _str(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v == null) return '';
  return v.toString().trim();
}

class AdminJobsScreen extends ConsumerWidget {
  const AdminJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AdminTheme.background,
        appBar: AppBar(
          leading: adminAppBarLeading(context),
          title: const Text('إدارة الوظائف'),
          backgroundColor: AdminTheme.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(adminJobsProvider),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: AdminPageBody(
          child: Column(
            children: [
              AdminSectionHeader(
                title: 'الوظائف',
                subtitle: 'إضافة وتعديل وحذف الوظائف',
                trailing: FilledButton.icon(
                  onPressed: () => _showAddJobDialog(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('إضافة وظيفة'),
                ),
              ),
              Expanded(
                child: AdminCard(
                  padding: const EdgeInsets.all(16),
                  child: ref
                      .watch(adminJobsProvider)
                      .when(
                        data: (jobs) {
                          if (jobs.isEmpty) {
                            return const Center(
                              child: Text(
                                'لا توجد وظائف حالياً. اضغط «إضافة وظيفة» لإنشاء أول وظيفة.',
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: jobs.length,
                            itemBuilder: (context, index) {
                              final j = jobs[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _str(j, 'title_ar').isEmpty
                                                  ? '—'
                                                  : _str(j, 'title_ar'),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'تعديل',
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _showEditJobDialog(
                                              context,
                                              ref,
                                              j,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'حذف',
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () {
                                              final id = _str(j, 'id');
                                              if (id.isNotEmpty)
                                                _confirmDeleteJob(
                                                  context,
                                                  ref,
                                                  id,
                                                );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'الشركة: ${_str(j, 'company_name').isEmpty ? '—' : _str(j, 'company_name')}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        'الموقع: ${_str(j, 'location').isEmpty ? '—' : _str(j, 'location')}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        'النوع: ${_jobTypeLabel(_str(j, 'job_type'))}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      if (_str(j, 'apply_url').isNotEmpty)
                                        Text(
                                          'رابط التقديم: ${_str(j, 'apply_url')}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AdminTheme.textMuted,
                                              ),
                                        ),
                                      if (_str(j, 'whatsapp_number').isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.chat_rounded,
                                              size: 16,
                                              color: Colors.green.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'واتساب التقديم: ${_str(j, 'whatsapp_number')}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        Colors.green.shade700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: AdminTheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'تعذر تحميل الوظائف',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$e',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () =>
                                      ref.invalidate(adminJobsProvider),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showAddJobDialog(BuildContext context, WidgetRef ref) {
    final titleAr = TextEditingController();
    final company = TextEditingController();
    final location = TextEditingController();
    final descriptionAr = TextEditingController();
    final salary = TextEditingController();
    final workDays = TextEditingController();
    final requirements = TextEditingController();
    final applyUrl = TextEditingController();
    final whatsappNumber = TextEditingController();
    final applyMessage = TextEditingController();
    String jobType = 'full_time';
    String workMode = 'onsite';
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة وظيفة جديدة'),
            content: SizedBox(
              width: AdminBreakpoints.isMobile(context) ? null : 440,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminFormSection(
                        title: 'البيانات الأساسية',
                        icon: Icons.work_outline_rounded,
                        children: [
                          TextFormField(
                            controller: titleAr,
                            decoration: const InputDecoration(
                              labelText: 'المسمى الوظيفي *',
                              isDense: true,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: company,
                            decoration: const InputDecoration(
                              labelText: 'اسم الشركة *',
                              isDense: true,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: location,
                            decoration: const InputDecoration(
                              labelText: 'الموقع *',
                              isDense: true,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          DropdownButtonFormField<String>(
                            initialValue: jobType,
                            decoration: const InputDecoration(
                              labelText: 'نوع الوظيفة',
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'full_time',
                                child: Text('دوام كامل'),
                              ),
                              DropdownMenuItem(
                                value: 'part_time',
                                child: Text('دوام جزئي'),
                              ),
                              DropdownMenuItem(
                                value: 'internship',
                                child: Text('تدريب'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => jobType = v ?? 'full_time'),
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          DropdownButtonFormField<String>(
                            initialValue: workMode,
                            decoration: const InputDecoration(
                              labelText: 'طبيعة الدوام',
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'onsite',
                                child: Text('حضوري'),
                              ),
                              DropdownMenuItem(
                                value: 'remote',
                                child: Text('عن بعد'),
                              ),
                              DropdownMenuItem(
                                value: 'hybrid',
                                child: Text('هجين'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => workMode = v ?? 'onsite'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AdminFormSection(
                        title: 'التفاصيل والوصف',
                        icon: Icons.description_outlined,
                        children: [
                          TextFormField(
                            controller: salary,
                            decoration: const InputDecoration(
                              labelText: 'الراتب (اختياري)',
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: workDays,
                            decoration: const InputDecoration(
                              labelText: 'أيام العمل',
                              hintText: 'مثال: الأحد - الخميس',
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: descriptionAr,
                            decoration: const InputDecoration(
                              labelText: 'الوصف *',
                              isDense: true,
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: requirements,
                            decoration: const InputDecoration(
                              labelText: 'المتطلبات (اختياري)',
                              isDense: true,
                              alignLabelWithHint: true,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: applyUrl,
                            decoration: const InputDecoration(
                              labelText: 'رابط التقديم (اختياري)',
                              hintText: 'https://...',
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AdminFormSection(
                        title: 'التقديم عبر واتساب',
                        icon: Icons.chat_rounded,
                        children: [
                          TextFormField(
                            controller: whatsappNumber,
                            decoration: const InputDecoration(
                              labelText: 'رقم واتساب التقديم (اختياري)',
                              hintText: 'مثال: 9647XXXXXXXXX',
                              helperText: 'بدون + أو صفر في البداية',
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: applyMessage,
                            decoration: const InputDecoration(
                              labelText: 'رسالة التقديم (اختياري)',
                              hintText:
                                  'الرسالة الافتراضية: مرحباً، أريد التقديم على وظيفة...',
                              isDense: true,
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    await ref
                        .read(adminJobsRepositoryProvider)
                        .insertJob(
                          titleAr: titleAr.text.trim(),
                          companyName: company.text.trim(),
                          location: location.text.trim(),
                          jobType: jobType,
                          descriptionAr: descriptionAr.text.trim(),
                          salary: salary.text.trim().isEmpty
                              ? null
                              : salary.text.trim(),
                          workMode: workMode,
                          workDays: workDays.text.trim().isEmpty
                              ? null
                              : workDays.text.trim(),
                          requirements: requirements.text.trim().isEmpty
                              ? null
                              : requirements.text.trim(),
                          applyUrl: applyUrl.text.trim().isEmpty
                              ? null
                              : applyUrl.text.trim(),
                          whatsappNumber: whatsappNumber.text.trim().isEmpty
                              ? null
                              : whatsappNumber.text.trim(),
                          applyMessage: applyMessage.text.trim().isEmpty
                              ? null
                              : applyMessage.text.trim(),
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    ref.invalidate(adminJobsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تمت إضافة الوظيفة بنجاح'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(
                        ctx,
                      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                    }
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditJobDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> job,
  ) {
    final titleAr = TextEditingController(text: _str(job, 'title_ar'));
    final company = TextEditingController(text: _str(job, 'company_name'));
    final location = TextEditingController(text: _str(job, 'location'));
    final descriptionAr = TextEditingController(
      text: _str(job, 'description_ar'),
    );
    final salary = TextEditingController(text: _str(job, 'salary'));
    final workDays = TextEditingController(text: _str(job, 'work_days'));
    final requirements = TextEditingController(text: _str(job, 'requirements'));
    final applyUrl = TextEditingController(text: _str(job, 'apply_url'));
    final whatsappNumber = TextEditingController(
      text: _str(job, 'whatsapp_number'),
    );
    final applyMessage = TextEditingController(
      text: _str(job, 'apply_message'),
    );

    String jobType = _str(job, 'job_type').isEmpty
        ? 'full_time'
        : _str(job, 'job_type');
    String workMode = _str(job, 'work_mode').isEmpty
        ? 'onsite'
        : _str(job, 'work_mode');

    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعديل وظيفة'),
            content: SizedBox(
              width: AdminBreakpoints.isMobile(context) ? null : 440,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminFormSection(
                        title: 'البيانات الأساسية',
                        icon: Icons.work_outline_rounded,
                        children: [
                          TextFormField(
                            controller: titleAr,
                            decoration: const InputDecoration(
                              labelText: 'المسمى الوظيفي *',
                              isDense: true,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: company,
                            decoration: const InputDecoration(
                              labelText: 'اسم الشركة *',
                              isDense: true,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: location,
                            decoration: const InputDecoration(
                              labelText: 'الموقع *',
                              isDense: true,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          DropdownButtonFormField<String>(
                            initialValue: jobType,
                            decoration: const InputDecoration(
                              labelText: 'نوع الوظيفة',
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'full_time',
                                child: Text('دوام كامل'),
                              ),
                              DropdownMenuItem(
                                value: 'part_time',
                                child: Text('دوام جزئي'),
                              ),
                              DropdownMenuItem(
                                value: 'internship',
                                child: Text('تدريب'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => jobType = v ?? 'full_time'),
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          DropdownButtonFormField<String>(
                            initialValue: workMode,
                            decoration: const InputDecoration(
                              labelText: 'طبيعة الدوام',
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'onsite',
                                child: Text('حضوري'),
                              ),
                              DropdownMenuItem(
                                value: 'remote',
                                child: Text('عن بعد'),
                              ),
                              DropdownMenuItem(
                                value: 'hybrid',
                                child: Text('هجين'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => workMode = v ?? 'onsite'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AdminFormSection(
                        title: 'التفاصيل والوصف',
                        icon: Icons.description_outlined,
                        children: [
                          TextFormField(
                            controller: salary,
                            decoration: const InputDecoration(
                              labelText: 'الراتب (اختياري)',
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: workDays,
                            decoration: const InputDecoration(
                              labelText: 'أيام العمل',
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: descriptionAr,
                            decoration: const InputDecoration(
                              labelText: 'الوصف *',
                              isDense: true,
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: requirements,
                            decoration: const InputDecoration(
                              labelText: 'المتطلبات (اختياري)',
                              isDense: true,
                              alignLabelWithHint: true,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: applyUrl,
                            decoration: const InputDecoration(
                              labelText: 'رابط التقديم (اختياري)',
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AdminFormSection(
                        title: 'التقديم عبر واتساب',
                        icon: Icons.chat_rounded,
                        children: [
                          TextFormField(
                            controller: whatsappNumber,
                            decoration: const InputDecoration(
                              labelText: 'رقم واتساب التقديم (اختياري)',
                              hintText: 'مثال: 9647XXXXXXXXX',
                              helperText: 'بدون + أو صفر في البداية',
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: applyMessage,
                            decoration: const InputDecoration(
                              labelText: 'رسالة التقديم (اختياري)',
                              hintText:
                                  'الرسالة الافتراضية: مرحباً، أريد التقديم على وظيفة...',
                              isDense: true,
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    await ref
                        .read(adminJobsRepositoryProvider)
                        .updateJob(
                          id: _str(job, 'id'),
                          titleAr: titleAr.text.trim(),
                          companyName: company.text.trim(),
                          location: location.text.trim(),
                          jobType: jobType,
                          descriptionAr: descriptionAr.text.trim(),
                          salary: salary.text.trim().isEmpty
                              ? null
                              : salary.text.trim(),
                          workMode: workMode,
                          workDays: workDays.text.trim().isEmpty
                              ? null
                              : workDays.text.trim(),
                          requirements: requirements.text.trim().isEmpty
                              ? null
                              : requirements.text.trim(),
                          applyUrl: applyUrl.text.trim().isEmpty
                              ? null
                              : applyUrl.text.trim(),
                          whatsappNumber: whatsappNumber.text.trim().isEmpty
                              ? null
                              : whatsappNumber.text.trim(),
                          applyMessage: applyMessage.text.trim().isEmpty
                              ? null
                              : applyMessage.text.trim(),
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    ref.invalidate(adminJobsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تحديث الوظيفة بنجاح')),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(
                        ctx,
                      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                    }
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteJob(BuildContext context, WidgetRef ref, String jobId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الوظيفة'),
          content: const Text('هل أنت متأكد من حذف هذه الوظيفة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                try {
                  await ref.read(adminJobsRepositoryProvider).deleteJob(jobId);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  ref.invalidate(adminJobsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حذف الوظيفة')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(
                      ctx,
                    ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                  }
                }
              },
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  String _jobTypeLabel(String type) {
    switch (type) {
      case 'full_time':
        return 'دوام كامل';
      case 'part_time':
        return 'دوام جزئي';
      case 'internship':
        return 'تدريب';
      default:
        return type;
    }
  }
}
