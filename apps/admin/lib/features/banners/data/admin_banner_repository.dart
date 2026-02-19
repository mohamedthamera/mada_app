import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../app/di.dart';

final adminBannerRepositoryProvider = Provider<AdminBannerRepository>(
  (ref) => SupabaseAdminBannerRepository(ref.read(supabaseClientProvider)),
);

abstract class AdminBannerRepository {
  Future<List<BannerModel>> fetchBanners();
  Future<void> addBanner({
    required BannerModel banner,
    Uint8List? imageBytes,
    String? fileName,
    Uint8List? videoBytes,
    String? videoFileName,
  });
  Future<void> updateBanner({
    required BannerModel banner,
    Uint8List? imageBytes,
    String? fileName,
    Uint8List? videoBytes,
    String? videoFileName,
  });
  Future<void> deleteBanner(String id, String imageUrl, {String? videoUrl});
}

class SupabaseAdminBannerRepository implements AdminBannerRepository {
  SupabaseAdminBannerRepository(this._client);
  final dynamic _client;

  @override
  Future<List<BannerModel>> fetchBanners() async {
    final response = await _client
        .from('banners')
        .select()
        .order('order_index', ascending: true);

    return (response as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map<String, dynamic>);
      m['image_url'] ??= '';
      return BannerModel.fromJson(m);
    })
        .toList();
  }

  @override
  Future<void> addBanner({
    required BannerModel banner,
    Uint8List? imageBytes,
    String? fileName,
    Uint8List? videoBytes,
    String? videoFileName,
  }) async {
    String? imageUrl;
    if (imageBytes != null && fileName != null) {
      final path = 'banners/$fileName';
      await _client.storage.from('banners').uploadBinary(path, imageBytes);
      imageUrl = _client.storage.from('banners').getPublicUrl(path);
    }

    String? videoUrl;
    if (videoBytes != null && videoFileName != null) {
      final vPath = 'banners/$videoFileName';
      await _client.storage.from('banners').uploadBinary(vPath, videoBytes);
      videoUrl = _client.storage.from('banners').getPublicUrl(vPath);
    }

    // 2. Save to database
    final insertMap = <String, dynamic>{
      'image_url': imageUrl ?? '',
      'title': banner.title,
      'link_url': banner.linkUrl,
      'order_index': banner.orderIndex,
      'is_active': banner.isActive,
    };
    if (videoUrl != null) {
      insertMap['video_url'] = videoUrl;
    }
    await _client.from('banners').insert(insertMap);
  }

  @override
  Future<void> updateBanner({
    required BannerModel banner,
    Uint8List? imageBytes,
    String? fileName,
    Uint8List? videoBytes,
    String? videoFileName,
  }) async {
    String? imageUrl;
    if (imageBytes != null && fileName != null) {
      final path = 'banners/$fileName';
      await _client.storage.from('banners').uploadBinary(path, imageBytes);
      imageUrl = _client.storage.from('banners').getPublicUrl(path);
    }
    String? videoUrl;
    if (videoBytes != null && videoFileName != null) {
      final vPath = 'banners/$videoFileName';
      await _client.storage.from('banners').uploadBinary(vPath, videoBytes);
      videoUrl = _client.storage.from('banners').getPublicUrl(vPath);
    }

    final updateMap = <String, dynamic>{
      'title': banner.title,
      'link_url': banner.linkUrl,
      'order_index': banner.orderIndex,
      'is_active': banner.isActive,
    };
    if (imageUrl != null) updateMap['image_url'] = imageUrl;
    if (videoUrl != null) updateMap['video_url'] = videoUrl;

    await _client.from('banners').update(updateMap).eq('id', banner.id);
  }

  @override
  Future<void> deleteBanner(String id, String imageUrl, {String? videoUrl}) async {
    await _client.from('banners').delete().eq('id', id);
    if (imageUrl.isNotEmpty) {
      try {
        final bucket = _client.storage.from('banners');
        final path = Uri.parse(imageUrl).pathSegments.last;
        await bucket.remove(['banners/$path']);
      } catch (_) {}
    }
    if (videoUrl != null && videoUrl.isNotEmpty) {
      try {
        final bucket = _client.storage.from('banners');
        final path = Uri.parse(videoUrl).pathSegments.last;
        await bucket.remove(['banners/$path']);
      } catch (_) {}
    }
  }

 
}
