import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../app/di.dart';

final booksRepositoryProvider = Provider<BooksRepository>(
  (ref) => BooksRepository(ref.read(supabaseClientProvider)),
);

/// Default signed URL expiry (50 minutes) to avoid expiry during a session
const int _signedUrlExpirySeconds = 3000;

class BooksRepository {
  BooksRepository(this._client);
  final dynamic _client;

  static const String _coverBucket = 'book-covers';
  static const String _fileBucket = 'book-files';

  final Map<String, _CachedSignedUrl> _signedUrlCache = {};
  static const int _cacheExpirySeconds = 2700; // 45 min

  /// Returns a signed URL for a cover image, or null if path is null/empty.
  /// Caches by path and refreshes when expired.
  Future<String?> getSignedUrlForCover(String? path) async {
    if (path == null || path.trim().isEmpty) return null;
    final key = '$_coverBucket/$path';
    final now = DateTime.now();
    final cached = _signedUrlCache[key];
    if (cached != null && now.difference(cached.at).inSeconds < _cacheExpirySeconds) {
      return cached.url;
    }
    try {
      final response = await _client.storage
          .from(_coverBucket)
          .createSignedUrl(path.trim(), _signedUrlExpirySeconds);
      final url = _extractSignedUrl(response);
      if (url != null) _signedUrlCache[key] = _CachedSignedUrl(url: url, at: now);
      return url;
    } catch (_) {
      return null;
    }
  }

  /// Returns a signed URL for a book file (PDF/EPUB). Throws if path is missing or request fails.
  Future<String> getSignedUrlForFile(String? path) async {
    if (path == null || path.trim().isEmpty) {
      throw ArgumentError('Book file path is required');
    }
    final key = '$_fileBucket/$path';
    final now = DateTime.now();
    final cached = _signedUrlCache[key];
    if (cached != null && now.difference(cached.at).inSeconds < _cacheExpirySeconds) {
      return cached.url;
    }
    final response = await _client.storage
        .from(_fileBucket)
        .createSignedUrl(path.trim(), _signedUrlExpirySeconds);
    final url = _extractSignedUrl(response);
    if (url == null) throw Exception('Failed to create signed URL for file');
    _signedUrlCache[key] = _CachedSignedUrl(url: url, at: now);
    return url;
  }

  static String? _extractSignedUrl(dynamic response) {
    if (response == null) return null;
    if (response is String) return response;
    if (response is Map && response.containsKey('signedUrl')) {
      return response['signedUrl'] as String?;
    }
    if (response is Map && response.containsKey('path')) {
      return response['path'] as String?;
    }
    try {
      return (response as dynamic).signedUrl as String?;
    } catch (_) {
      return null;
    }
  }

  /// Featured published books for carousel (is_featured = true, is_published = true)
  Future<List<Book>> fetchFeaturedBooks() async {
    final res = await _client
        .from('books')
        .select()
        .eq('is_published', true)
        .eq('is_featured', true)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);
    return _parseList(res);
  }

  /// Published books with optional search, category filter, and pagination
  Future<List<Book>> fetchPublishedBooks({
    String? searchQuery,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client
        .from('books')
        .select()
        .eq('is_published', true)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = _sanitizeSearch(searchQuery.trim());
      query = query.or('title.ilike.*$q*,author.ilike.*$q*');
    }
    if (category != null && category.trim().isNotEmpty) {
      query = query.eq('category', category.trim());
    }

    final res = await query;
    return _parseList(res);
  }

  static String _sanitizeSearch(String s) {
    return s.replaceAll(RegExp(r'[*%]'), '');
  }

  /// Distinct categories from published books (for filter chips)
  Future<List<String>> fetchCategories() async {
    final res = await _client
        .from('books')
        .select('category')
        .eq('is_published', true)
        .not('category', 'is', null);
    final list = res as List;
    final categories = <String>{};
    for (final e in list) {
      final cat = (e as Map<String, dynamic>)['category'] as String?;
      if (cat != null && cat.trim().isNotEmpty) {
        categories.add(cat.trim());
      }
    }
    return categories.toList()..sort();
  }

  Future<Book> fetchBookById(String id) async {
    final res = await _client
        .from('books')
        .select()
        .eq('id', id)
        .eq('is_published', true)
        .single();
    return Book.fromJson(Map<String, dynamic>.from(res as Map));
  }

  List<Book> _parseList(dynamic res) {
    final list = res as List;
    return list
        .map((e) => Book.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

class _CachedSignedUrl {
  _CachedSignedUrl({required this.url, required this.at});
  final String url;
  final DateTime at;
}
