import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../../core/widgets/widgets.dart';
import 'books_providers.dart';
import '../../subscription/presentation/subscription_providers.dart';

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  String? _categoryFilter;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _searchQuery = value.trim());
        ref.read(booksListProvider.notifier).loadInitial(
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          category: _categoryFilter,
        );
      }
    });
  }

  void _onScroll() {
    final notifier = ref.read(booksListProvider.notifier);
    final state = ref.read(booksListProvider).valueOrNull;
    if (state == null || !state.hasMore || state.isLoadingMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      notifier.loadMore();
    }
  }

  Widget _buildLockedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppText(
              'صفحة الكتب للمشتركين',
              style: AppTextStyle.title,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              'اشترك الآن لتصفح الكتب وتحميلها',
              style: AppTextStyle.body,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.go('/subscription'),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('الذهاب للاشتراك'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSubAsync = ref.watch(hasActiveSubscriptionProvider);
    final featuredAsync = ref.watch(featuredBooksProvider);
    final categoriesAsync = ref.watch(booksCategoriesProvider);
    final listAsync = ref.watch(booksListProvider);
    final loadingMore = ref.watch(booksListLoadingMoreProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('الكتب', style: AppTextStyle.title),
        ),
        body: hasSubAsync.when(
          data: (hasSub) {
            if (!hasSub) return _buildLockedView(context);
            return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(featuredBooksProvider);
            ref.invalidate(booksCategoriesProvider);
            ref.invalidate(booksListProvider);
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InputField(
                        hintText: 'ابحث بالعنوان أو المؤلف...',
                        prefixIcon: Icons.search_rounded,
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      categoriesAsync.when(
                        data: (categories) {
                          final allCats = ['الكل', ...categories];
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: allCats.map((c) {
                              final selected = _categoryFilter == null
                                  ? c == 'الكل'
                                  : _categoryFilter == c;
                              return FilterChip(
                                label: Text(c),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    _categoryFilter = c == 'الكل' ? null : c;
                                  });
                                  ref.read(booksListProvider.notifier).loadInitial(
                                    searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                                    category: _categoryFilter,
                                  );
                                },
                                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                                checkmarkColor: AppColors.primary,
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              featuredAsync.when(
                data: (featured) {
                  if (featured.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.lg, left: AppSpacing.lg, bottom: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText('مميز', style: AppTextStyle.title),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: featured.length,
                              itemBuilder: (context, i) {
                                final book = featured[i];
                                return Padding(
                                  padding: const EdgeInsets.only(left: AppSpacing.md),
                                  child: _BookCard(
                                    book: book,
                                    onTap: () => context.go('/books/${book.id}'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              listAsync.when(
                data: (state) {
                  if (state.list.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_outlined, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: AppSpacing.md),
                            AppText(
                              _searchQuery.isNotEmpty || _categoryFilter != null
                                  ? 'لا توجد نتائج تطابق البحث'
                                  : 'لا توجد كتب متاحة حالياً',
                              style: AppTextStyle.body,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final book = state.list[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _BookListTile(
                              book: book,
                              onTap: () => context.go('/books/${book.id}'),
                            ),
                          );
                        },
                        childCount: state.list.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: AppSpacing.md),
                        AppText('تعذر تحميل الكتب', style: AppTextStyle.body, color: AppColors.textSecondary),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton.icon(
                          onPressed: () => ref.invalidate(booksListProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                ),
            ],
          ),
        );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildLockedView(context),
        ),
      ),
    );
  }
}

class _BookCard extends ConsumerWidget {
  const _BookCard({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverUrlAsync = ref.watch(bookCoverSignedUrlProvider(book));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: coverUrlAsync.when(
                    data: (url) => url != null && url.isNotEmpty
                        ? Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _coverPlaceholder(context),
                          )
                        : _coverPlaceholder(context),
                    loading: () => _coverPlaceholder(context),
                    error: (_, __) => _coverPlaceholder(context),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText(
                book.title,
                style: AppTextStyle.caption,
                maxLines: 2,
              ),
              if (book.author != null && book.author!.isNotEmpty)
                AppText(
                  book.author!,
                  style: AppTextStyle.caption,
                  color: AppColors.textMuted,
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: const Icon(Icons.menu_book_rounded, size: 40, color: AppColors.textMuted),
    );
  }
}

class _BookListTile extends ConsumerWidget {
  const _BookListTile({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverUrlAsync = ref.watch(bookCoverSignedUrlProvider(book));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 64,
              height: 96,
              child: coverUrlAsync.when(
                data: (url) => url != null && url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(context),
                      )
                    : _placeholder(context),
                loading: () => _placeholder(context),
                error: (_, __) => _placeholder(context),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(book.title, style: AppTextStyle.title, maxLines: 2),
                if (book.author != null && book.author!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AppText(book.author!, style: AppTextStyle.body, color: AppColors.textSecondary),
                ],
                if (book.category != null && book.category!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: AppText(book.category!, style: AppTextStyle.caption, color: AppColors.primary),
                  ),
                ],
                const SizedBox(height: 4),
                AppText(
                  book.fileType.toUpperCase(),
                  style: AppTextStyle.caption,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: const Icon(Icons.menu_book_rounded, color: AppColors.textMuted),
    );
  }
}
