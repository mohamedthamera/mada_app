import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/shared.dart';
import '../../../app/di.dart';

final adminBooksRepositoryProvider = Provider<AdminBooksRepository>(
  (ref) => AdminBooksRepository(ref.read(supabaseClientProvider)),
);

const int _signedUrlExpirySeconds = 3600;
const int _cacheExpirySeconds = 2700;

class _CachedSignedUrl {
  _CachedSignedUrl({required this.url, required this.at});
  final String url;
  final DateTime at;
}

class AdminBooksRepository {
  AdminBooksRepository(this._client);
  final dynamic _client;

  static const _coverBucket = 'book-covers';
  static const _fileBucket = 'book-files';

  final Map<String, _CachedSignedUrl> _signedUrlCache = {};

  static const _coverExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const _fileExtensions = ['pdf', 'epub'];

  Future<List<Book>> fetchBooks({
    String? searchQuery,
    String? category,
    bool? isPublished,
    int limit = 100,
    int offset = 0,
  }) async {
    var query = _client
        .from('books')
        .select()
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().replaceAll(RegExp(r'[*%]'), '');
      query = query.or('title.ilike.*$q*,author.ilike.*$q*');
    }
    if (category != null && category.trim().isNotEmpty) {
      query = query.eq('category', category.trim());
    }
    if (isPublished != null) {
      query = query.eq('is_published', isPublished);
    }

    final res = await query;
    return _parseList(res);
  }

  Future<Book> fetchBookById(String id) async {
    final res = await _client.from('books').select().eq('id', id).single();
    return Book.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Upload cover; returns storage path (e.g. covers/1234567890.jpg). Enforces jpg/jpeg/png/webp.
  Future<String> uploadCover(Uint8List bytes, String fileName) async {
    final rawExt = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    final ext = _coverExtensions.contains(rawExt) ? rawExt : 'jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'covers/$timestamp.$ext';
    final contentType = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    await _client.storage.from(_coverBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );
    return path;
  }

  /// Upload file; returns storage path (e.g. files/xyz.pdf). Enforces pdf/epub.
  Future<String> uploadFile(Uint8List bytes, String fileName) async {
    final ext = fileName.split('.').last.toLowerCase();
    if (!_fileExtensions.contains(ext)) {
      throw ArgumentError('File must be pdf or epub');
    }
    final path = 'files/$fileName';
    await _client.storage.from(_fileBucket).uploadBinary(path, bytes);
    return path;
  }

  /// Signed URL for cover (admin list thumbnails). Cached.
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

  Future<void> insertBook({
    required String title,
    String? description,
    String? author,
    String? category,
    String? language,
    int? pages,
    String? coverPath,
    required String filePath,
    required String fileType,
    int? fileSizeBytes,
    bool isPublished = false,
    bool isFeatured = false,
    int sortOrder = 0,
    String? createdBy,
  }) async {
    await _client.from('books').insert({
      'title': title.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'author': author?.trim().isEmpty == true ? null : author?.trim(),
      'category': category?.trim().isEmpty == true ? null : category?.trim(),
      'language': language?.trim().isEmpty == true ? null : language?.trim(),
      'pages': pages,
      'cover_path': coverPath?.trim().isEmpty == true ? null : coverPath?.trim(),
      'file_path': filePath.trim(),
      'cover_url': null,
      'file_url': '', // required column; actual access via file_path + signed URL
      'file_type': fileType,
      'file_size_bytes': fileSizeBytes,
      'is_published': isPublished,
      'is_featured': isFeatured,
      'sort_order': sortOrder,
      'created_by': createdBy,
    });
  }

  Future<void> updateBook({
    required String id,
    required String title,
    String? description,
    String? author,
    String? category,
    String? language,
    int? pages,
    String? coverPath,
    required String filePath,
    required String fileType,
    int? fileSizeBytes,
    required bool isPublished,
    required bool isFeatured,
    required int sortOrder,
  }) async {
    await _client.from('books').update({
      'title': title.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'author': author?.trim().isEmpty == true ? null : author?.trim(),
      'category': category?.trim().isEmpty == true ? null : category?.trim(),
      'language': language?.trim().isEmpty == true ? null : language?.trim(),
      'pages': pages,
      'cover_path': coverPath?.trim().isEmpty == true ? null : coverPath?.trim(),
      'file_path': filePath.trim(),
      'file_url': '', // keep required column satisfied
      'file_type': fileType,
      'file_size_bytes': fileSizeBytes,
      'is_published': isPublished,
      'is_featured': isFeatured,
      'sort_order': sortOrder,
    }).eq('id', id);
  }

  Future<void> updateBookFlags(String id, {bool? isPublished, bool? isFeatured}) async {
    final map = <String, dynamic>{};
    if (isPublished != null) map['is_published'] = isPublished;
    if (isFeatured != null) map['is_featured'] = isFeatured;
    if (map.isEmpty) return;
    await _client.from('books').update(map).eq('id', id);
  }

  /// Deletes storage objects (cover + file) then the book row. Throws with clear message if storage delete fails.
  Future<void> deleteBook(Book book) async {
    final errors = <String>[];
    if (book.coverPath != null && book.coverPath!.trim().isNotEmpty) {
      try {
        await _client.storage.from(_coverBucket).remove([book.coverPath!]);
      } catch (e) {
        errors.add('غلاف: $e');
      }
    }
    if (book.filePath != null && book.filePath!.trim().isNotEmpty) {
      try {
        await _client.storage.from(_fileBucket).remove([book.filePath!]);
      } catch (e) {
        errors.add('ملف: $e');
      }
    }
    if (errors.isNotEmpty) {
      throw Exception('فشل حذف الملفات من التخزين. يرجى الحذف يدوياً من التخزين ثم حذف السجل. ${errors.join(' ')}');
    }
    await _client.from('books').delete().eq('id', book.id);
  }

  List<Book> _parseList(dynamic res) {
    final list = res as List;
    return list
        .map((e) => Book.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
