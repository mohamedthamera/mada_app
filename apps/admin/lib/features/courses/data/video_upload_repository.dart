import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/di.dart';

final videoUploadRepositoryProvider = Provider<VideoUploadRepository>(
  (ref) => VideoUploadRepository(ref.read(supabaseClientProvider)),
);

class VideoUploadRepository {
  VideoUploadRepository(this._client);
  final SupabaseClient _client;

  static const _bucket = 'videos';
  static const _thumbnailsBucket = 'thumbnails';

  /// يرفع صورة غلاف ويعيد الرابط العام
  Future<String> uploadThumbnail({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
    final storagePath =
        '${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from(_thumbnailsBucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: true,
          ),
        );
    return _client.storage.from(_thumbnailsBucket).getPublicUrl(storagePath);
  }

  /// يرفع ملف فيديو (بايتات) ويعيد الرابط العام
  Future<String> uploadVideo({
    required String courseId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ext = fileName.contains('.') ? fileName.split('.').last : 'mp4';
    final storagePath =
        '$courseId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from(_bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: 'video/$ext',
            upsert: true,
          ),
        );

    return _client.storage.from(_bucket).getPublicUrl(storagePath);
  }
}
