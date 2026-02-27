import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../data/admin_books_repository.dart';

final adminBooksProvider = FutureProvider<List<Book>>((ref) {
  return ref.read(adminBooksRepositoryProvider).fetchBooks();
});

/// Signed URL for a book's cover (private bucket). Use for list thumbnails.
final adminBookCoverSignedUrlProvider = FutureProvider.family<String?, Book>((ref, book) async {
  return ref.read(adminBooksRepositoryProvider).getSignedUrlForCover(book.coverPath);
});
