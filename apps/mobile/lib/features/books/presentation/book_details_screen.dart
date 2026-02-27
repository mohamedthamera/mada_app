import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/widgets.dart';
import '../data/books_repository.dart';
import 'books_providers.dart';

class BookDetailsScreen extends ConsumerWidget {
  const BookDetailsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('تفاصيل الكتاب', style: AppTextStyle.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: ref.watch(bookDetailProvider(bookId)).when(
              data: (book) => _BookDetailContent(book: book, ref: ref),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: AppSpacing.md),
                      AppText('تعذر تحميل الكتاب', style: AppTextStyle.body, color: AppColors.textSecondary),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(bookDetailProvider(bookId)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class _BookDetailContent extends ConsumerWidget {
  const _BookDetailContent({required this.book, required this.ref});

  final Book book;
  final WidgetRef ref;

  Future<void> _openOrDownload(BuildContext context) async {
    try {
      final repo = ref.read(booksRepositoryProvider);
      final String url;
      if (book.filePath != null && book.filePath!.trim().isNotEmpty) {
        url = await repo.getSignedUrlForFile(book.filePath);
      } else if (book.fileUrl != null && book.fileUrl!.trim().isNotEmpty) {
        url = book.fileUrl!;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('رابط الملف غير متوفر')),
          );
        }
        return;
      }
      final uri = Uri.tryParse(url);
      if (uri == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('رابط الملف غير صالح')),
          );
        }
        return;
      }
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح الرابط')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverUrlAsync = ref.watch(bookCoverSignedUrlProvider(book));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: coverUrlAsync.when(
                data: (url) => url != null && url.isNotEmpty
                    ? Image.network(
                        url,
                        height: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _coverPlaceholder(context),
                      )
                    : _coverPlaceholder(context),
                loading: () => _coverPlaceholder(context),
                error: (_, __) => _coverPlaceholder(context),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppText(book.title, style: AppTextStyle.headline),
          if (book.author != null && book.author!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(book.author!, style: AppTextStyle.body, color: AppColors.textSecondary),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (book.category != null && book.category!.isNotEmpty)
            _DetailRow(Icons.category_outlined, 'التصنيف', book.category!),
          if (book.language != null && book.language!.isNotEmpty)
            _DetailRow(Icons.language_rounded, 'اللغة', book.language!),
          if (book.pages != null && book.pages! > 0)
            _DetailRow(Icons.article_outlined, 'عدد الصفحات', '${book.pages}'),
          _DetailRow(Icons.picture_as_pdf_outlined, 'نوع الملف', book.fileType.toUpperCase()),
          if (book.description != null && book.description!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const AppText('الوصف', style: AppTextStyle.title),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              book.description!.trim(),
              style: AppTextStyle.body,
              color: AppColors.textSecondary,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () => _openOrDownload(context),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(book.fileType == 'pdf' ? 'فتح PDF' : 'فتح / تحميل'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder(BuildContext context) {
    return Container(
      height: 220,
      width: 160,
      color: AppColors.surface,
      child: const Icon(Icons.menu_book_rounded, size: 64, color: AppColors.textMuted),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.8)),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 100,
            child: AppText('$label:', style: AppTextStyle.body, color: AppColors.textMuted),
          ),
          Expanded(child: AppText(value, style: AppTextStyle.body)),
        ],
      ),
    );
  }
}
