import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../core/widgets/admin_widgets.dart';
import 'data/admin_jobs_repository.dart';
import 'presentation/admin_jobs_providers.dart';

class AdminJobsScreen extends ConsumerWidget {
  const AdminJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة الوظائف')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              AdminSectionHeader(
                title: 'الوظائف',
                trailing: ElevatedButton(
                  onPressed: () => _showAddJobDialog(context, ref),
                  child: const Text('إضافة وظيفة'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: AdminCard(
                  child: ref.watch(adminJobsProvider).when(
                        data: (jobs) {
                          if (jobs.isEmpty) {
                            return const Center(
                              child: Text('لا توجد وظائف حالياً'),
                            );
                          }
                          return DataTable2(
                            columns: const [
                              DataColumn(label: Text('المسمى الوظيفي')),
                              DataColumn(label: Text('الشركة')),
                              DataColumn(label: Text('الموقع')),
                              DataColumn(label: Text('النوع')),
                              DataColumn(label: Text('رابط التقديم')),
                              DataColumn(label: Text('إجراءات')),
                            ],
                            rows: jobs
                                .map(
                                  (j) => DataRow(
                                    cells: [
                                      DataCell(Text(j['title_ar'] as String)),
                                      DataCell(Text(j['company_name'] as String)),
                                      DataCell(Text(j['location'] as String)),
                                      DataCell(
                                        Text(_jobTypeLabel(
                                            j['job_type'] as String)),
                                      ),
                                      DataCell(
                                        Text(
                                          (j['apply_url'] as String?) ?? '—',
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: 'تعديل',
                                              icon: const Icon(Icons.edit),
                                              onPressed: () =>
                                                  _showEditJobDialog(
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
                                              onPressed: () =>
                                                  _confirmDeleteJob(
                                                context,
                                                ref,
                                                j['id'] as String,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) =>
                            Center(child: Text('تعذر تحميل الوظائف: $e')),
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
    String jobType = 'full_time';
    String workMode = 'onsite';
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة وظيفة جديدة'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleAr,
                      decoration: const InputDecoration(
                        labelText: 'المسمى الوظيفي *',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: company,
                      decoration: const InputDecoration(
                        labelText: 'اسم الشركة *',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: location,
                      decoration: const InputDecoration(
                        labelText: 'الموقع *',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: jobType,
                      decoration: const InputDecoration(
                        labelText: 'نوع الوظيفة *',
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
                      onChanged: (v) => jobType = v ?? 'full_time',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: workMode,
                      decoration: const InputDecoration(
                        labelText: 'طبيعة الدوام *',
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
                      onChanged: (v) => workMode = v ?? 'onsite',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: salary,
                      decoration: const InputDecoration(
                        labelText: 'الراتب (اختياري)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: workDays,
                      decoration: const InputDecoration(
                        labelText: 'أيام العمل (مثال: الأحد - الخميس)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionAr,
                      decoration: const InputDecoration(
                        labelText: 'الوصف (عربي) *',
                      ),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: requirements,
                      decoration: const InputDecoration(
                        labelText: 'المتطلبات والخبرات (اختياري)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: applyUrl,
                      decoration: const InputDecoration(
                        labelText: 'رابط التقديم (اختياري)',
                      ),
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
                  await ref.read(adminJobsRepositoryProvider).insertJob(
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
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('خطأ: $e')),
                    );
                  }
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditJobDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> job,
  ) {
    final titleAr =
        TextEditingController(text: job['title_ar'] as String? ?? '');
    final company =
        TextEditingController(text: job['company_name'] as String? ?? '');
    final location =
        TextEditingController(text: job['location'] as String? ?? '');
    final descriptionAr =
        TextEditingController(text: job['description_ar'] as String? ?? '');
    final salary = TextEditingController(text: job['salary'] as String? ?? '');
    final workDays =
        TextEditingController(text: job['work_days'] as String? ?? '');
    final requirements =
        TextEditingController(text: job['requirements'] as String? ?? '');
    final applyUrl =
        TextEditingController(text: job['apply_url'] as String? ?? '');

    String jobType = job['job_type'] as String? ?? 'full_time';
    String workMode = job['work_mode'] as String? ?? 'onsite';

    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل وظيفة'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleAr,
                      decoration: const InputDecoration(
                        labelText: 'المسمى الوظيفي *',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: company,
                      decoration: const InputDecoration(
                        labelText: 'اسم الشركة *',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: location,
                      decoration: const InputDecoration(
                        labelText: 'الموقع *',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: jobType,
                      decoration: const InputDecoration(
                        labelText: 'نوع الوظيفة *',
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
                      onChanged: (v) => jobType = v ?? 'full_time',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: workMode,
                      decoration: const InputDecoration(
                        labelText: 'طبيعة الدوام *',
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
                      onChanged: (v) => workMode = v ?? 'onsite',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: salary,
                      decoration: const InputDecoration(
                        labelText: 'الراتب (اختياري)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: workDays,
                      decoration: const InputDecoration(
                        labelText: 'أيام العمل (مثال: الأحد - الخميس)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionAr,
                      decoration: const InputDecoration(
                        labelText: 'الوصف (عربي) *',
                      ),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: requirements,
                      decoration: const InputDecoration(
                        labelText: 'المتطلبات والخبرات (اختياري)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: applyUrl,
                      decoration: const InputDecoration(
                        labelText: 'رابط التقديم (اختياري)',
                      ),
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
                  await ref.read(adminJobsRepositoryProvider).updateJob(
                        id: job['id'] as String,
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
                      );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  ref.invalidate(adminJobsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث الوظيفة بنجاح'),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('خطأ: $e')),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteJob(
    BuildContext context,
    WidgetRef ref,
    String jobId,
  ) {
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
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                try {
                  await ref
                      .read(adminJobsRepositoryProvider)
                      .deleteJob(jobId);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  ref.invalidate(adminJobsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف الوظيفة'),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('خطأ: $e')),
                    );
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

