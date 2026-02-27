import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../data/books_repository.dart';

final featuredBooksProvider = FutureProvider<List<Book>>((ref) {
  return ref.read(booksRepositoryProvider).fetchFeaturedBooks();
});

final booksCategoriesProvider = FutureProvider<List<String>>((ref) {
  return ref.read(booksRepositoryProvider).fetchCategories();
});

/// State for paginated books list (search, category, infinite scroll)
class BooksListState {
  const BooksListState({
    this.list = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.searchQuery,
    this.category,
  });

  final List<Book> list;
  final bool hasMore;
  final bool isLoadingMore;
  final String? searchQuery;
  final String? category;
}

class BooksListNotifier extends AsyncNotifier<BooksListState> {
  static const _pageSize = 20;

  @override
  Future<BooksListState> build() async {
    final repo = ref.read(booksRepositoryProvider);
    final list = await repo.fetchPublishedBooks(limit: _pageSize, offset: 0);
    return BooksListState(list: list, hasMore: list.length >= _pageSize);
  }

  Future<void> loadInitial({String? searchQuery, String? category}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(booksRepositoryProvider);
      final list = await repo.fetchPublishedBooks(
        searchQuery: searchQuery,
        category: category,
        limit: _pageSize,
        offset: 0,
      );
      return BooksListState(
        list: list,
        hasMore: list.length >= _pageSize,
        searchQuery: searchQuery,
        category: category,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    ref.read(booksListLoadingMoreProvider.notifier).state = true;
    try {
      final repo = ref.read(booksRepositoryProvider);
      final next = await repo.fetchPublishedBooks(
        searchQuery: current.searchQuery,
        category: current.category,
        limit: _pageSize,
        offset: current.list.length,
      );
      if (next.isEmpty) {
        state = AsyncData(BooksListState(
          list: current.list,
          hasMore: false,
          searchQuery: current.searchQuery,
          category: current.category,
        ));
      } else {
        state = AsyncData(BooksListState(
          list: [...current.list, ...next],
          hasMore: next.length >= _pageSize,
          searchQuery: current.searchQuery,
          category: current.category,
        ));
      }
    } finally {
      ref.read(booksListLoadingMoreProvider.notifier).state = false;
    }
  }
}

final booksListProvider = AsyncNotifierProvider<BooksListNotifier, BooksListState>(BooksListNotifier.new);

final booksListLoadingMoreProvider = StateProvider<bool>((ref) => false);

final bookDetailProvider = FutureProvider.family<Book, String>((ref, id) {
  return ref.read(booksRepositoryProvider).fetchBookById(id);
});

/// Signed URL for a book's cover (for private bucket). Use when displaying cover images.
final bookCoverSignedUrlProvider = FutureProvider.family<String?, Book>((ref, book) async {
  return ref.read(booksRepositoryProvider).getSignedUrlForCover(book.coverPath);
});
