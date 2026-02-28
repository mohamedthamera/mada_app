import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/admin_course_repository.dart';
import 'data/admin_lesson_repository.dart';
import 'data/video_upload_repository.dart';
import 'presentation/admin_course_providers.dart';
import '../../core/constants/admin_breakpoints.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../ui_system/app_theme.dart';

String _courseLessonError(dynamic e) {
  if (e is PostgrestException) {
    final d = e.details?.toString() ?? '';
    return '${e.message}${d.isEmpty ? '' : '\n$d'}';
  }
  return e.toString();
}

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  static const _defaultCategoryId =
      '00000000-0000-0000-0000-000000000001';

  /// بيانات الدورة التجريبية ودرسها الأول
  static const _demoThumbnailUrl =
      'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800';
  static const _demoVideoUrl =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';

  /// صورة غلاف دورة التسويق
  static const _marketingThumbnailUrl =
      'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800';

  Future<void> _addMarketingCourse(WidgetRef ref, BuildContext context) async {
    try {
      final courseId = await ref.read(adminCourseRepositoryProvider).insertCourse(
            titleAr: 'تعلم التسويق',
            titleEn: 'Learn Marketing',
            descAr: 'دورة شاملة في أساسيات التسويق والتسويق الرقمي ووسائل التواصل. تعلّم كيف تروّج لعملك وتصل لجمهورك وتُحقق أهدافك.',
            descEn: 'A comprehensive course on marketing fundamentals, digital marketing and social media. Learn how to promote your business, reach your audience and achieve your goals.',
            categoryId: _defaultCategoryId,
            level: 'متوسط',
            thumbnailUrl: _marketingThumbnailUrl,
          );
      final lessonRepo = ref.read(adminLessonRepositoryProvider);
      final lessons = [
        ('مقدمة في التسويق', 'Introduction to Marketing', 8),
        ('التسويق الرقمي', 'Digital Marketing', 10),
        ('التسويق عبر وسائل التواصل', 'Social Media Marketing', 12),
        ('تحليل السوق والجمهور', 'Market and Audience Analysis', 9),
        ('بناء العلامة التجارية', 'Building Your Brand', 11),
      ];
      for (var i = 0; i < lessons.length; i++) {
        final (titleAr, titleEn, min) = lessons[i];
        await lessonRepo.insertLesson(
          courseId: courseId,
          titleAr: titleAr,
          titleEn: titleEn,
          videoUrl: _demoVideoUrl,
          durationSec: min * 60,
          orderIndex: i + 1,
          isFree: i == 0,
        );
      }
      ref.invalidate(adminCoursesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة دورة تعلم التسويق بنجاح')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${_courseLessonError(e)}'), duration: const Duration(seconds: 8)),
        );
      }
    }
  }

  Future<void> _addDemoCourse(WidgetRef ref, BuildContext context) async {
    try {
      final courseId = await ref.read(adminCourseRepositoryProvider).insertCourse(
            titleAr: 'دورة تجريبية',
            titleEn: 'Demo Course',
            descAr: 'هذه دورة تجريبية للتعرف على المنصة والمحتوى. يمكنك استكشاف الدروس والتقييمات.',
            descEn: 'This is a demo course to explore the platform and content.',
            categoryId: _defaultCategoryId,
            level: 'مبتدئ',
            thumbnailUrl: _demoThumbnailUrl,
          );
      await ref.read(adminLessonRepositoryProvider).insertLesson(
            courseId: courseId,
            titleAr: 'الدرس الأول التجريبي',
            titleEn: 'First Demo Lesson',
            videoUrl: _demoVideoUrl,
            durationSec: 60,
            orderIndex: 1,
            isFree: true,
          );
      ref.invalidate(adminCoursesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الدورة التجريبية بنجاح')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${_courseLessonError(e)}'), duration: const Duration(seconds: 8)),
        );
      }
    }
  }

  void _showAddCourseDialog(BuildContext context, WidgetRef ref) {
    final titleAr = TextEditingController();
    final descAr = TextEditingController();
    final thumbnailUrl = TextEditingController();
    String level = 'مبتدئ';
    final formKey = GlobalKey<FormState>();
    bool thumbnailUploading = false;
    String? thumbnailUploadedName;

    // قائمة الدروس: عنوان عربي، مدة، فيديو (بايتات + اسم) أو رابط
    final lessonEntries = <_LessonEntry>[
      _LessonEntry(
        titleAr: TextEditingController(),
        durationMin: TextEditingController(text: '10'),
        videoUrl: TextEditingController(),
      ),
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة دورة جديدة'),
            content: SizedBox(
              width: AdminBreakpoints.isMobile(context) ? null : 480,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminFormSection(
                        title: 'معلومات الدورة',
                        icon: Icons.menu_book_rounded,
                        children: [
                          TextFormField(
                            controller: titleAr,
                            decoration: const InputDecoration(
                              labelText: 'العنوان *',
                              isDense: true,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          TextFormField(
                            controller: descAr,
                            decoration: const InputDecoration(
                              labelText: 'الوصف *',
                              isDense: true,
                              alignLabelWithHint: true,
                            ),
                            maxLines: 2,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: adminFormFieldSpacing),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: thumbnailUrl,
                                  decoration: const InputDecoration(
                                    labelText: 'رابط الغلاف أو ارفع صورة',
                                    hintText: 'رابط أو ارفع',
                                    isDense: true,
                                  ),
                                  validator: (v) =>
                                      v == null || v.isEmpty ? 'مطلوب' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: thumbnailUploading
                                    ? null
                                    : () async {
                                        setDialogState(() => thumbnailUploading = true);
                                        try {
                                          final result = await FilePicker.platform.pickFiles(
                                            type: FileType.image,
                                            allowMultiple: false,
                                            withData: true,
                                          );
                                          if (result == null ||
                                              result.files.isEmpty ||
                                              result.files.first.bytes == null) {
                                            setDialogState(() => thumbnailUploading = false);
                                            return;
                                          }
                                          final file = result.files.first;
                                          final bytes = Uint8List.fromList(file.bytes!);
                                          final name = file.name.isEmpty ? 'cover.jpg' : file.name;
                                          final url = await ref
                                              .read(videoUploadRepositoryProvider)
                                              .uploadThumbnail(bytes: bytes, fileName: name);
                                          thumbnailUrl.text = url;
                                          setDialogState(() {
                                            thumbnailUploadedName = name;
                                            thumbnailUploading = false;
                                          });
                                        } catch (e) {
                                          setDialogState(() => thumbnailUploading = false);
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(ctx).showSnackBar(
                                              SnackBar(content: Text('فشل رفع الصورة: $e')),
                                            );
                                          }
                                        }
                                      },
                                icon: thumbnailUploading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.upload_rounded, size: 20),
                                label: const Text('رفع'),
                              ),
                            ],
                          ),
                          if (thumbnailUploadedName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                                  const SizedBox(width: 6),
                                  Text(thumbnailUploadedName!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          const SizedBox(height: adminFormFieldSpacing),
                          DropdownButtonFormField<String>(
                            initialValue: level,
                            decoration: const InputDecoration(
                              labelText: 'المستوى',
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'مبتدئ', child: Text('مبتدئ')),
                              DropdownMenuItem(value: 'متوسط', child: Text('متوسط')),
                              DropdownMenuItem(value: 'متقدم', child: Text('متقدم')),
                            ],
                            onChanged: (v) => setDialogState(() => level = v ?? 'مبتدئ'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AdminFormSection(
                        title: 'الدروس (درس واحد على الأقل)',
                        icon: Icons.play_circle_outline_rounded,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    lessonEntries.add(_LessonEntry(
                                      titleAr: TextEditingController(),
                                      durationMin: TextEditingController(text: '10'),
                                      videoUrl: TextEditingController(),
                                    ));
                                  });
                                },
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text('إضافة درس'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...lessonEntries.asMap().entries.map((entry) {
                        final i = entry.key;
                        final le = entry.value;
                        return _buildLessonEntry(
                          ctx,
                          ref,
                          setDialogState,
                          i + 1,
                          le,
                          lessonEntries.length > 1,
                          () {
                            setDialogState(() {
                              lessonEntries.removeAt(i);
                            });
                          },
                        );
                      }),
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
                  for (var i = 0; i < lessonEntries.length; i++) {
                    final le = lessonEntries[i];
                    final lessonTitleAr = le.titleAr.text.trim();
                    final url = le.videoUrl.text.trim();
                    final isCompletelyEmpty =
                        lessonTitleAr.isEmpty && le.videoBytes == null && url.isEmpty;

                    // إذا كان الدرس فارغاً تماماً نتجاهله (لا نفرض تعبئته)
                    if (isCompletelyEmpty) {
                      continue;
                    }

                    if (lessonTitleAr.isEmpty) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('الدرس ${i + 1}: أدخل عنوان الدرس')),
                        );
                      }
                      return;
                    }

                    if (le.videoBytes == null && url.isEmpty) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('الدرس ${i + 1}: اختر فيديو للرفع أو أدخل رابط فيديو')),
                        );
                      }
                      return;
                    }
                  }
                    try {
                    final courseTitleAr = titleAr.text.trim();
                    final courseDescAr = descAr.text.trim();
                    final courseId = await ref.read(adminCourseRepositoryProvider).insertCourse(
                          titleAr: courseTitleAr,
                          titleEn: courseTitleAr,
                          descAr: courseDescAr,
                          descEn: courseDescAr,
                          categoryId: _defaultCategoryId,
                          level: level,
                          thumbnailUrl: thumbnailUrl.text.trim(),
                        );
                    final lessonRepo = ref.read(adminLessonRepositoryProvider);
                    final uploadRepo = ref.read(videoUploadRepositoryProvider);
                    var order = 1;
                    for (var i = 0; i < lessonEntries.length; i++) {
                      final le = lessonEntries[i];
                      final lessonTitleAr = le.titleAr.text.trim();
                      final url = le.videoUrl.text.trim();
                      final isCompletelyEmpty =
                          lessonTitleAr.isEmpty && le.videoBytes == null && url.isEmpty;

                      // تجاهل الدروس الفارغة تماماً
                      if (isCompletelyEmpty) continue;

                      String videoUrl;
                      if (le.videoBytes != null && le.videoFileName != null) {
                        videoUrl = await uploadRepo.uploadVideo(
                          courseId: courseId,
                          bytes: le.videoBytes!,
                          fileName: le.videoFileName!,
                        );
                      } else {
                        videoUrl = url;
                      }
                      final min = int.tryParse(le.durationMin.text) ?? 10;
                      await lessonRepo.insertLesson(
                        courseId: courseId,
                        titleAr: lessonTitleAr,
                        videoUrl: videoUrl,
                        durationSec: min * 60,
                        orderIndex: order++,
                        isFree: order == 2, // أول درس فعلي يكون مجاني
                      );
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    ref.invalidate(adminCoursesProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تمت إضافة الدورة بنجاح')),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('خطأ: ${_courseLessonError(e)}'),
                          duration: const Duration(seconds: 8),
                        ),
                      );
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

  Widget _buildLessonEntry(
    BuildContext ctx,
    WidgetRef ref,
    void Function(void Function()) setDialogState,
    int index,
    _LessonEntry le,
    bool canRemove,
    VoidCallback onRemove,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('الدرس $index', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                    onPressed: () => onRemove(),
                    tooltip: 'حذف الدرس',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: le.titleAr,
              decoration: const InputDecoration(labelText: 'عنوان الدرس *'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: le.durationMin,
              decoration: const InputDecoration(labelText: 'مدة الدرس (دقيقة)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.video,
                    allowMultiple: false,
                    withData: true,
                  );
                  if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
                  final file = result.files.first;
                  setDialogState(() {
                    le.videoBytes = Uint8List.fromList(file.bytes!);
                    le.videoFileName = file.name.isEmpty ? 'video.mp4' : file.name;
                    le.videoUrl.clear();
                  });
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل اختيار الفيديو: $e'), backgroundColor: Colors.red.shade700),
                    );
                  }
                }
              },
              icon: const Icon(Icons.video_file, size: 20),
              label: Text(le.videoFileName ?? 'رفع فيديو'),
            ),
            if (le.videoFileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        le.videoFileName!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            TextFormField(
              controller: le.videoUrl,
              decoration: const InputDecoration(
                labelText: 'أو رابط فيديو (إذا لم ترفع ملفاً)',
                hintText: 'https://...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AdminTheme.background,
        appBar: AppBar(
          leading: adminAppBarLeading(context),
          title: const Text('إدارة الدورات'),
          backgroundColor: AdminTheme.background,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: AdminPageBody(
          child: ref.watch(adminCoursesProvider).when(
                data: (courses) => Column(
                  children: [
                    AdminSectionHeader(
                      title: 'الدورات',
                      subtitle: 'إضافة وتعديل الدروس',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _addDemoCourse(ref, context),
                            icon: const Icon(Icons.science, size: 20),
                            label: const Text('دورة تجريبية'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _addMarketingCourse(ref, context),
                            icon: const Icon(Icons.campaign, size: 20),
                            label: const Text('دورة تعلم التسويق'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => _showAddCourseDialog(context, ref),
                            child: const Text('إضافة دورة'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: AdminCard(
                        child: DataTable2(
                          columns: const [
                            DataColumn(label: Text('العنوان')),
                            DataColumn(label: Text('التصنيف')),
                            DataColumn(label: Text('المستوى')),
                            DataColumn(label: Text('التقييم')),
                            DataColumn(label: Text('إجراءات')),
                          ],
                          rows: courses
                              .map(
                                (course) => DataRow(
                                  cells: [
                                    DataCell(Text(course.titleAr)),
                                    DataCell(Text(course.categoryId)),
                                    DataCell(Text(course.level)),
                                    DataCell(Text(
                                        course.ratingAvg.toStringAsFixed(1))),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () => context.push(
                                              '/courses/${course.id}/lessons?title=${Uri.encodeComponent(course.titleAr)}',
                                            ),
                                            icon:
                                                const Icon(Icons.video_library),
                                            tooltip: 'دروس / فيديوهات',
                                          ),
                                          IconButton(
                                            tooltip: 'تعديل',
                                            onPressed: () => _showEditCourseDialog(
                                              context,
                                              ref,
                                              course,
                                            ),
                                            icon: const Icon(Icons.edit),
                                          ),
                                          IconButton(
                                            tooltip: 'حذف',
                                            onPressed: () => _confirmDeleteCourse(
                                              context,
                                              ref,
                                              course.id,
                                            ),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('تعذر تحميل الدورات: $e')),
              ),
        ),
      ),
    );
  }

  void _showEditCourseDialog(
    BuildContext context,
    WidgetRef ref,
    Course course,
  ) {
    final titleAr = TextEditingController(text: course.titleAr);
    final descAr = TextEditingController(text: course.descAr);
    final thumbnailUrl = TextEditingController(text: course.thumbnailUrl);
    String level = course.level;
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل دورة'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: titleAr,
                      decoration: const InputDecoration(
                        labelText: 'العنوان *',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descAr,
                      decoration: const InputDecoration(
                        labelText: 'الوصف *',
                      ),
                      maxLines: 2,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: thumbnailUrl,
                      decoration: const InputDecoration(
                        labelText: 'رابط صورة الغلاف *',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: level,
                      decoration: const InputDecoration(
                        labelText: 'المستوى',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'مبتدئ', child: Text('مبتدئ')),
                        DropdownMenuItem(value: 'متوسط', child: Text('متوسط')),
                        DropdownMenuItem(
                          value: 'متقدم',
                          child: Text('متقدم'),
                        ),
                      ],
                      onChanged: (v) => level = v ?? course.level,
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
                  final t = titleAr.text.trim();
                  final d = descAr.text.trim();
                  await ref.read(adminCourseRepositoryProvider).updateCourse(
                        id: course.id,
                        titleAr: t,
                        titleEn: t,
                        descAr: d,
                        descEn: d,
                        categoryId: course.categoryId,
                        level: level,
                        thumbnailUrl: thumbnailUrl.text.trim(),
                      );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  ref.invalidate(adminCoursesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث الدورة بنجاح'),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('خطأ: ${_courseLessonError(e)}'),
                        duration: const Duration(seconds: 8),
                      ),
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

  void _confirmDeleteCourse(
    BuildContext context,
    WidgetRef ref,
    String courseId,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الدورة'),
          content: const Text('هل أنت متأكد من حذف هذه الدورة؟'),
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
                      .read(adminCourseRepositoryProvider)
                      .deleteCourse(courseId);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  ref.invalidate(adminCoursesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف الدورة'),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('خطأ: ${_courseLessonError(e)}'),
                        duration: const Duration(seconds: 8),
                      ),
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
}

class _LessonEntry {
  _LessonEntry({
    required this.titleAr,
    required this.durationMin,
    required this.videoUrl,
  });

  final TextEditingController titleAr;
  final TextEditingController durationMin;
  final TextEditingController videoUrl;
  Uint8List? videoBytes;
  String? videoFileName;
}
