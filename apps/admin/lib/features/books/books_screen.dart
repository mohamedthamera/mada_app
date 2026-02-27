import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../core/constants/admin_breakpoints.dart';
import '../../core/widgets/admin_widgets.dart';
import 'data/admin_books_repository.dart';
import 'presentation/admin_books_providers.dart';

class AdminBooksScreen extends ConsumerStatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  ConsumerState<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends ConsumerState<AdminBooksScreen> {
  String _searchQuery = '';
  String? _categoryFilter;
  bool? _publishedFilter; // null = all, true = published, false = unpublished

  List<Book> _filter(List<Book> books) {
    var list = books;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((b) {
        return (b.title.toLowerCase().contains(q)) ||
            ((b.author ?? '').toLowerCase().contains(q)) ||
            ((b.category ?? '').toLowerCase().contains(q));
      }).toList();
    }
    if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
      list = list.where((b) => b.category == _categoryFilter).toList();
    }
    if (_publishedFilter != null) {
      list = list.where((b) => b.isPublished == _publishedFilter).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AdminBreakpoints.isMobile(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: adminAppBarLeading(context),
          title: const Text('إدارة الكتب'),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(adminBooksProvider),
              tooltip: 'تحديث',
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _showBookDialog(context, ref),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('إضافة كتاب'),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: AdminPageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSectionHeader(
                title: 'الكتب',
                subtitle: 'إدارة كتب التطبيق (PDF / EPUB)',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'بحث',
                        hintText: 'عنوان أو مؤلف',
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  DropdownButton<bool?>(
                    value: _publishedFilter,
                    hint: const Text('الحالة'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('الكل')),
                      DropdownMenuItem(value: true, child: Text('منشور')),
                      DropdownMenuItem(value: false, child: Text('غير منشور')),
                    ],
                    onChanged: (v) => setState(() => _publishedFilter = v),
                  ),
                ],
              ),
              Expanded(
                child: ref.watch(adminBooksProvider).when(
                      data: (books) {
                        final filtered = _filter(books);
                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(books.isEmpty ? 'لا توجد كتب' : 'لا توجد نتائج'),
                          );
                        }
                        if (isMobile) {
                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final book = filtered[i];
                              return _BookListCard(
                                book: book,
                                onEdit: () => _showBookDialog(context, ref, book),
                                onDelete: () => _confirmDelete(context, ref, book),
                                onTogglePublished: () => _togglePublished(ref, book),
                                onToggleFeatured: () => _toggleFeatured(ref, book),
                              );
                            },
                          );
                        }
                        return AdminCard(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('غلاف')),
                                DataColumn(label: Text('العنوان')),
                                DataColumn(label: Text('المؤلف')),
                                DataColumn(label: Text('التصنيف')),
                                DataColumn(label: Text('نوع الملف')),
                                DataColumn(label: Text('منشور')),
                                DataColumn(label: Text('مميز')),
                                DataColumn(label: Text('الترتيب')),
                                DataColumn(label: Text('تاريخ')),
                                DataColumn(label: Text('إجراءات')),
                              ],
                              rows: filtered.map((book) {
                                return DataRow(
                                  cells: [
                                    DataCell(_AdminBookCoverThumbnail(book: book)),
                                    DataCell(Text(book.title)),
                                    DataCell(Text(book.author ?? '—')),
                                    DataCell(Text(book.category ?? '—')),
                                    DataCell(Text(book.fileType.toUpperCase())),
                                    DataCell(Text(book.isPublished ? 'نعم' : 'لا')),
                                    DataCell(Text(book.isFeatured ? 'نعم' : 'لا')),
                                    DataCell(Text('${book.sortOrder}')),
                                    DataCell(Text('${book.createdAt.day}/${book.createdAt.month}/${book.createdAt.year}')),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _showBookDialog(context, ref, book),
                                            tooltip: 'تعديل',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              book.isPublished ? Icons.visibility_off : Icons.visibility,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () => _togglePublished(ref, book),
                                            tooltip: book.isPublished ? 'إلغاء النشر' : 'نشر',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              book.isFeatured ? Icons.star : Icons.star_border,
                                              color: Colors.amber,
                                            ),
                                            onPressed: () => _toggleFeatured(ref, book),
                                            tooltip: book.isFeatured ? 'إلغاء التميز' : 'تمييز',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () => _confirmDelete(context, ref, book),
                                            tooltip: 'حذف',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('خطأ: $e')),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePublished(WidgetRef ref, Book book) async {
    try {
      await ref.read(adminBooksRepositoryProvider).updateBookFlags(book.id, isPublished: !book.isPublished);
      ref.invalidate(adminBooksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(book.isPublished ? 'تم إلغاء النشر' : 'تم النشر')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _toggleFeatured(WidgetRef ref, Book book) async {
    try {
      await ref.read(adminBooksRepositoryProvider).updateBookFlags(book.id, isFeatured: !book.isFeatured);
      ref.invalidate(adminBooksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(book.isFeatured ? 'تم إلغاء التميز' : 'تم التميز')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('حذف الكتاب "${book.title}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(adminBooksRepositoryProvider).deleteBook(book);
      ref.invalidate(adminBooksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  void _showBookDialog(BuildContext context, WidgetRef ref, [Book? existing]) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _BookFormDialog(
        existing: existing,
        onSaved: () {
          ref.invalidate(adminBooksProvider);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

class _AdminBookCoverThumbnail extends ConsumerWidget {
  // ignore: unused_element_parameter - optional size used in build, callers use defaults
  const _AdminBookCoverThumbnail({required this.book, this.width = 40, this.height = 56});

  final Book book;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(adminBookCoverSignedUrlProvider(book));
    return SizedBox(
      width: width,
      height: height,
      child: urlAsync.when(
        data: (url) => url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 40),
              )
            : const Icon(Icons.image_not_supported, size: 40),
        loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, __) => const Icon(Icons.image_not_supported, size: 40),
      ),
    );
  }
}

class _BookListCard extends StatelessWidget {
  const _BookListCard({
    required this.book,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublished,
    required this.onToggleFeatured,
  });

  final Book book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublished;
  final VoidCallback onToggleFeatured;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: SizedBox(
          width: 48,
          height: 64,
          child: _AdminBookCoverThumbnail(book: book),
        ),
        title: Text(book.title),
        subtitle: Text('${book.author ?? "—"} • ${book.fileType.toUpperCase()} • ${book.isPublished ? "منشور" : "غير منشور"}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(icon: Icon(book.isPublished ? Icons.visibility_off : Icons.visibility), onPressed: onTogglePublished),
            IconButton(icon: Icon(book.isFeatured ? Icons.star : Icons.star_border), onPressed: onToggleFeatured),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class _BookFormDialog extends ConsumerStatefulWidget {
  const _BookFormDialog({this.existing, required this.onSaved});

  final Book? existing;
  final VoidCallback onSaved;

  @override
  ConsumerState<_BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends ConsumerState<_BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _authorController;
  late final TextEditingController _categoryController;
  late final TextEditingController _languageController;
  late final TextEditingController _pagesController;
  late final TextEditingController _sortOrderController;
  bool _isPublished = false;
  bool _isFeatured = false;
  String _fileType = 'pdf';
  String? _coverPath;
  String? _filePath;
  int? _fileSizeBytes;
  bool _uploading = false;
  String? _coverFileName;
  String? _fileFileName;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _authorController = TextEditingController(text: e?.author ?? '');
    _categoryController = TextEditingController(text: e?.category ?? '');
    _languageController = TextEditingController(text: e?.language ?? '');
    _pagesController = TextEditingController(text: e?.pages != null ? '${e!.pages}' : '');
    _sortOrderController = TextEditingController(text: e?.sortOrder != null ? '${e!.sortOrder}' : '0');
    _isPublished = e?.isPublished ?? false;
    _isFeatured = e?.isFeatured ?? false;
    _fileType = e?.fileType ?? 'pdf';
    _coverPath = e?.coverPath;
    _filePath = e?.filePath;
    _fileSizeBytes = e?.fileSizeBytes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _languageController.dispose();
    _pagesController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() => _uploading = true);
    try {
      final repo = ref.read(adminBooksRepositoryProvider);
      final bytes = result.files.single.bytes!;
      final name = result.files.single.name;
      final path = await repo.uploadCover(bytes, name);
      if (mounted) {
        setState(() {
          _coverPath = path;
          _coverFileName = name;
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل رفع الغلاف: $e')));
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
    );
    if (result == null || result.files.single.bytes == null) return;
    final ext = result.files.single.extension?.toLowerCase();
    if (ext != 'pdf' && ext != 'epub') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الملف يجب أن يكون PDF أو EPUB')));
      }
      return;
    }
    setState(() => _uploading = true);
    try {
      final repo = ref.read(adminBooksRepositoryProvider);
      final bytes = result.files.single.bytes!;
      final name = result.files.single.name;
      final path = await repo.uploadFile(bytes, name);
      if (mounted) {
        setState(() {
          _filePath = path;
          _fileFileName = name;
          _fileType = ext ?? 'pdf';
          _fileSizeBytes = bytes.length;
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل رفع الملف: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_filePath == null || _filePath!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى رفع ملف الكتاب (PDF أو EPUB)')));
      return;
    }
    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;
    final pages = int.tryParse(_pagesController.text.trim());
    try {
      final repo = ref.read(adminBooksRepositoryProvider);
      final userId = SupabaseClientFactory.client.auth.currentUser?.id;
      if (widget.existing != null) {
        await repo.updateBook(
          id: widget.existing!.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          author: _authorController.text.trim().isEmpty ? null : _authorController.text.trim(),
          category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
          language: _languageController.text.trim().isEmpty ? null : _languageController.text.trim(),
          pages: pages,
          coverPath: _coverPath,
          filePath: _filePath!,
          fileType: _fileType,
          fileSizeBytes: _fileSizeBytes,
          isPublished: _isPublished,
          isFeatured: _isFeatured,
          sortOrder: sortOrder,
        );
      } else {
        await repo.insertBook(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          author: _authorController.text.trim().isEmpty ? null : _authorController.text.trim(),
          category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
          language: _languageController.text.trim().isEmpty ? null : _languageController.text.trim(),
          pages: pages,
          coverPath: _coverPath,
          filePath: _filePath!,
          fileType: _fileType,
          fileSizeBytes: _fileSizeBytes,
          isPublished: _isPublished,
          isFeatured: _isFeatured,
          sortOrder: sortOrder,
          createdBy: userId,
        );
      }
      widget.onSaved();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.existing != null ? 'تعديل الكتاب' : 'إضافة كتاب'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminFormSection(
                    title: 'معلومات الكتاب',
                    icon: Icons.menu_book_rounded,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'العنوان *',
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: adminFormFieldSpacing),
                      TextFormField(
                        controller: _authorController,
                        decoration: const InputDecoration(labelText: 'المؤلف', isDense: true),
                      ),
                      const SizedBox(height: adminFormFieldSpacing),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(labelText: 'التصنيف', isDense: true),
                      ),
                      const SizedBox(height: adminFormFieldSpacing),
                      TextFormField(
                        controller: _languageController,
                        decoration: const InputDecoration(labelText: 'اللغة', isDense: true),
                      ),
                      const SizedBox(height: adminFormFieldSpacing),
                      TextFormField(
                        controller: _pagesController,
                        decoration: const InputDecoration(labelText: 'عدد الصفحات', isDense: true),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: adminFormFieldSpacing),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'الوصف',
                          isDense: true,
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AdminFormSection(
                    title: 'الغلاف والملف',
                    icon: Icons.upload_file_rounded,
                    children: [
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _uploading ? null : _pickAndUploadCover,
                            icon: const Icon(Icons.image_outlined, size: 20),
                            label: Text(_coverFileName ?? 'رفع غلاف'),
                          ),
                          const SizedBox(width: 8),
                          if (_coverPath != null) const Icon(Icons.check_circle, color: Colors.green, size: 22),
                        ],
                      ),
                      const SizedBox(height: adminFormFieldSpacing),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _uploading ? null : _pickAndUploadFile,
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                              label: Text(_fileFileName ?? 'رفع PDF/EPUB *'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_filePath != null)
                            Text(
                              '$_fileType • ${_fileSizeBytes != null ? "${(_fileSizeBytes! / 1024).toStringAsFixed(1)} KB" : ""}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                      if (_uploading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
                      const SizedBox(height: adminFormFieldSpacing),
                      DropdownButtonFormField<String>(
                        initialValue: _fileType,
                        decoration: const InputDecoration(labelText: 'نوع الملف', isDense: true),
                        items: const [
                          DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                          DropdownMenuItem(value: 'epub', child: Text('EPUB')),
                        ],
                        onChanged: (v) => setState(() => _fileType = v ?? 'pdf'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AdminFormSection(
                    title: 'العرض والنشر',
                    icon: Icons.tune_rounded,
                    children: [
                      TextFormField(
                        controller: _sortOrderController,
                        decoration: const InputDecoration(
                          labelText: 'ترتيب العرض',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: adminFormFieldSpacing),
                      Row(
                        children: [
                          const Text('منشور'),
                          const SizedBox(width: 8),
                          Switch(value: _isPublished, onChanged: (v) => setState(() => _isPublished = v)),
                          const SizedBox(width: 24),
                          const Text('مميز'),
                          const SizedBox(width: 8),
                          Switch(value: _isFeatured, onChanged: (v) => setState(() => _isFeatured = v)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          FilledButton(onPressed: _save, child: const Text('حفظ')),
        ],
      ),
    );
  }
}
