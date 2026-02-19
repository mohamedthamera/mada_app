import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/admin_lesson_repository.dart';
import 'data/video_upload_repository.dart';
import '../../core/widgets/admin_widgets.dart';

String _lessonError(dynamic e) {
  if (e is PostgrestException) {
    final d = e.details?.toString() ?? '';
    return '${e.message}${d.isEmpty ? '' : '\n$d'}';
  }
  return e.toString();
}

String _getContentType(String fileName) {
  final extension = fileName.toLowerCase().split('.').last;
  switch (extension) {
    case 'txt':
      return 'text/plain';
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    default:
      return 'application/octet-stream';
  }
}

class CourseLessonsScreen extends ConsumerStatefulWidget {
  const CourseLessonsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  final String courseId;
  final String courseTitle;

  @override
  ConsumerState<CourseLessonsScreen> createState() =>
      _CourseLessonsScreenState();
}

class _CourseLessonsScreenState extends ConsumerState<CourseLessonsScreen> {
  List<Lesson> _lessons = [];
  bool _loading = true;
  String? _error;

  void _showEditLessonFilesDialog(Lesson lesson) {
    final uploadedTextFileUrls = [...lesson.textFileUrls];
    final uploadedTextFileNames = [...lesson.textFileNames];
    var uploadingText = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('ملفات الدرس: ${lesson.titleAr}'),
            content: SizedBox(
              width: 520,
              height: 520,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'الملفات المرفقة',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (uploadedTextFileNames.isEmpty)
                      Text(
                        'لا توجد ملفات مرفقة.',
                        style: TextStyle(color: Colors.grey[700]),
                      )
                    else
                      Column(
                        children: [
                          ...uploadedTextFileNames.map(
                            (fileName) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.description,
                                      color: Colors.blue, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      fileName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        size: 16, color: Colors.red),
                                    onPressed: () {
                                      final index = uploadedTextFileNames
                                          .indexOf(fileName);
                                      if (index != -1) {
                                        setDialogState(() {
                                          uploadedTextFileNames.removeAt(index);
                                          uploadedTextFileUrls.removeAt(index);
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: uploadingText
                          ? null
                          : () async {
                              setDialogState(() => uploadingText = true);
                              try {
                                final result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['txt', 'pdf', 'doc', 'docx'],
                                  allowMultiple: true,
                                  withData: true,
                                );
                                if (result == null || result.files.isEmpty) {
                                  setDialogState(() => uploadingText = false);
                                  return;
                                }

                                for (final file in result.files) {
                                  final rawBytes = file.bytes;
                                  if (rawBytes == null) continue;

                                  final bytes = Uint8List.fromList(rawBytes);
                                  final name = file.name.isEmpty
                                      ? 'text_file.txt'
                                      : file.name;

                                  final fileName =
                                      '${DateTime.now().millisecondsSinceEpoch}_$name';
                                  final path =
                                      'lesson-files/${widget.courseId}/$fileName';

                                  await Supabase.instance.client.storage
                                      .from('uploads')
                                      .uploadBinary(
                                        path,
                                        bytes,
                                        fileOptions: FileOptions(
                                          upsert: true,
                                          contentType: _getContentType(name),
                                        ),
                                      );

                                  final publicUrl = Supabase
                                      .instance.client.storage
                                      .from('uploads')
                                      .getPublicUrl(path);

                                  setDialogState(() {
                                    uploadedTextFileUrls.add(publicUrl);
                                    uploadedTextFileNames.add(name);
                                  });
                                }
                                setDialogState(() => uploadingText = false);
                              } catch (e) {
                                setDialogState(() => uploadingText = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('فشل رفع الملفات: $e')),
                                  );
                                }
                              }
                            },
                      icon: uploadingText
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(
                        uploadingText
                            ? 'جاري رفع الملفات...'
                            : 'إضافة ملفات (txt/pdf/doc/docx)',
                      ),
                    ),
                  ],
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
                  try {
                    await ref.read(adminLessonRepositoryProvider).updateLessonFiles(
                          lessonId: lesson.id,
                          textFileUrls: uploadedTextFileUrls,
                          textFileNames: uploadedTextFileNames,
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    _loadLessons();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حفظ ملفات الدرس')),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('خطأ: ${_lessonError(e)}'),
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
      ),
    );
  }

  Future<void> _loadLessons() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref
          .read(adminLessonRepositoryProvider)
          .fetchLessons(widget.courseId);
      if (mounted) setState(() => _lessons = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLessons());
  }

  void _showAddLessonDialog() {
    final titleAr = TextEditingController();
    final titleEn = TextEditingController();
    final durationMin = TextEditingController(text: '10');
    final orderIndex = TextEditingController(text: '${_lessons.length + 1}');
    var isFree = false;
    String? uploadedVideoUrl;
    String? uploadedFileName;
    List<String> uploadedTextFileUrls = [];
    List<String> uploadedTextFileNames = [];
    var uploading = false;
    var uploadingText = false;
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة درس (رفع فيديو وملفات نصية)'),
            content: SizedBox(
              width: 500,
              height: 600,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleAr,
                        decoration: const InputDecoration(
                          labelText: 'عنوان الدرس (عربي) *',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: titleEn,
                        decoration: const InputDecoration(
                          labelText: 'عنوان الدرس (إنجليزي) *',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: uploading
                            ? null
                            : () async {
                                setDialogState(() => uploading = true);
                                try {
                                  final result = await FilePicker.platform
                                      .pickFiles(
                                    type: FileType.video,
                                    allowMultiple: false,
                                    withData: true,
                                  );
                                  if (result == null ||
                                      result.files.single.bytes == null) {
                                    setDialogState(() => uploading = false);
                                    return;
                                  }
                                  final file = result.files.single;
                                  final rawBytes = file.bytes;
                                  if (rawBytes == null) {
                                    setDialogState(() => uploading = false);
                                    return;
                                  }
                                  final bytes = Uint8List.fromList(rawBytes);
                                  final name =
                                      file.name.isEmpty ? 'video.mp4' : file.name;
                                  final url = await ref
                                      .read(videoUploadRepositoryProvider)
                                      .uploadVideo(
                                        courseId: widget.courseId,
                                        bytes: bytes,
                                        fileName: name,
                                      );
                                  setDialogState(() {
                                    uploadedVideoUrl = url;
                                    uploadedFileName = name;
                                    uploading = false;
                                  });
                                } catch (e) {
                                  setDialogState(() => uploading = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text('فشل الرفع: $e')),
                                    );
                                  }
                                }
                              },
                        icon: uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(
                          uploadedFileName ?? (uploading ? 'جاري الرفع...' : 'اختر فيديو للرفع'),
                        ),
                      ),
                      if (uploadedFileName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  uploadedFileName!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Text Files Upload Section
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'الملفات النصية (اختياري)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: uploadingText
                            ? null
                            : () async {
                                setDialogState(() => uploadingText = true);
                                try {
                                  final result = await FilePicker.platform
                                      .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['txt', 'pdf', 'doc', 'docx'],
                                    allowMultiple: true,
                                    withData: true,
                                  );
                                  if (result == null || result.files.isEmpty) {
                                    setDialogState(() => uploadingText = false);
                                    return;
                                  }
                                  
                                  for (final file in result.files) {
                                    final rawBytes = file.bytes;
                                    if (rawBytes == null) continue;
                                    
                                    final bytes = Uint8List.fromList(rawBytes);
                                    final name = file.name.isEmpty ? 'text_file.txt' : file.name;
                                    
                                    // Upload to Supabase Storage (uploads bucket)
                                    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$name';
                                    final path = 'lesson-files/${widget.courseId}/$fileName';
                                    
                                    await Supabase.instance.client.storage.from('uploads').uploadBinary(
                                      path,
                                      bytes,
                                      fileOptions: FileOptions(
                                        upsert: true,
                                        contentType: _getContentType(name),
                                      ),
                                    );
                                    
                                    final publicUrl = Supabase.instance.client.storage
                                        .from('uploads')
                                        .getPublicUrl(path);
                                    
                                    setDialogState(() {
                                      uploadedTextFileUrls.add(publicUrl);
                                      uploadedTextFileNames.add(name);
                                    });
                                  }
                                  setDialogState(() => uploadingText = false);
                                } catch (e) {
                                  setDialogState(() => uploadingText = false);
                                  if (ctx.mounted) {
                                    String errorMessage = 'فشل رفع الملفات النصية';
                                    
                                    if (e is StorageException) {
                                      if (e.message.contains('mime type')) {
                                        errorMessage = 'نوع الملف غير مدعوم. استخدم txt, pdf, doc, docx';
                                      } else if (e.message.contains('unauthorized')) {
                                        errorMessage = 'صلاحيات غير كافية. تحقق من إعدادات Supabase';
                                      } else {
                                        errorMessage = 'خطأ في التخزين: ${e.message}';
                                      }
                                    } else {
                                      errorMessage = 'خطأ غير متوقع: $e';
                                    }
                                    
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text(errorMessage)),
                                    );
                                  }
                                }
                              },
                        icon: uploadingText
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(
                          uploadingText 
                              ? 'جاري رفع الملفات...' 
                              : 'اختر ملفات نصية للرفع',
                        ),
                      ),
                      if (uploadedTextFileNames.isNotEmpty)
                        Column(
                          children: [
                            const SizedBox(height: 8),
                            ...uploadedTextFileNames.map((fileName) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.description, color: Colors.blue, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      fileName,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                    onPressed: () {
                                      final index = uploadedTextFileNames.indexOf(fileName);
                                      if (index != -1) {
                                        setDialogState(() {
                                          uploadedTextFileNames.removeAt(index);
                                          uploadedTextFileUrls.removeAt(index);
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            )).toList(),
                          ],
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: durationMin,
                        decoration: const InputDecoration(
                          labelText: 'مدة الدرس (دقيقة)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'مطلوب';
                          if (int.tryParse(v) == null) return 'أدخل رقم';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: orderIndex,
                        decoration: const InputDecoration(
                          labelText: 'ترتيب الدرس',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'مطلوب';
                          if (int.tryParse(v) == null) return 'أدخل رقم';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('درس مجاني'),
                        value: isFree,
                        onChanged: (v) =>
                            setDialogState(() => isFree = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ]),
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
                  if (uploadedVideoUrl == null && uploadedTextFileUrls.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('اختر فيديو أو ملفات نصية للرفع أولاً')),
                    );
                    return;
                  }
                  if (!formKey.currentState!.validate()) return;
                  final order =
                      int.tryParse(orderIndex.text) ?? _lessons.length + 1;
                  final min = int.tryParse(durationMin.text) ?? 10;
                  try {
                    await ref.read(adminLessonRepositoryProvider).insertLesson(
                          courseId: widget.courseId,
                          titleAr: titleAr.text.trim(),
                          titleEn: titleEn.text.trim(),
                          videoUrl: uploadedVideoUrl ?? '',
                          durationSec: min * 60,
                          orderIndex: order,
                          isFree: isFree,
                          textFileUrls: uploadedTextFileUrls,
                          textFileNames: uploadedTextFileNames,
                        );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  _loadLessons();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت إضافة الدرس')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('خطأ إضافة الدرس: ${_lessonError(e)}'),
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


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('دروس: ${widget.courseTitle}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/courses'),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSectionHeader(
                title: 'الدروس والفيديوهات',
                trailing: ElevatedButton.icon(
                  onPressed: _showAddLessonDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة درس'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Center(child: Text('خطأ: $_error'))
              else if (_lessons.isEmpty)
                AdminCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.video_library_outlined,
                              size: 48, color: Colors.grey[600]),
                          const SizedBox(height: AppSpacing.md),
                          const Text('لا توجد دروس بعد. اضغط "إضافة درس" وادخل رابط الفيديو.'),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: AdminCard(
                    child: ListView.builder(
                      itemCount: _lessons.length,
                      itemBuilder: (_, i) {
                        final l = _lessons[i];
                        return ListTile(
                          leading: const Icon(Icons.play_circle_outline),
                          title: Text(l.titleAr),
                          subtitle: Text(
                            '${l.durationSec ~/ 60} دقيقة • ${l.isFree ? "مجاني" : "مدفوع"}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'ملفات الدرس',
                                onPressed: () => _showEditLessonFilesDialog(l),
                                icon: const Icon(Icons.attach_file),
                              ),
                              const Icon(Icons.chevron_left),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
