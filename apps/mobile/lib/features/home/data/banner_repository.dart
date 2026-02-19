import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../app/di.dart';
import 'dart:developer' as developer;

final bannerRepositoryProvider = Provider<BannerRepository>(
  (ref) => SupabaseBannerRepository(ref.read(supabaseClientProvider)),
);

abstract class BannerRepository {
  Future<List<BannerModel>> fetchBanners();
}

class SupabaseBannerRepository implements BannerRepository {
  SupabaseBannerRepository(this._client);
  final dynamic _client;

  @override
  Future<List<BannerModel>> fetchBanners() async {
    final response = await _client
        .from('banners')
        .select()
        .eq('is_active', true)
        .order('order_index', ascending: true);

    developer.log('Raw response from banners: $response', name: 'BannerRepository');

    final list = (response as List)
        .map((e) {
          final m = Map<String, dynamic>.from(e as Map<String, dynamic>);
          m['image_url'] ??= '';
          developer.log('Processing banner: $m', name: 'BannerRepository');
          return BannerModel.fromJson(m);
        })
        .where((b) =>
            b.imageUrl.isNotEmpty ||
            (b.videoUrl != null && b.videoUrl!.isNotEmpty))
        .toList();
    
    developer.log('Final filtered banners count: ${list.length}', name: 'BannerRepository');
    for (var banner in list) {
      developer.log('Banner - ID: ${banner.id}, Image: ${banner.imageUrl}, Video: ${banner.videoUrl}', name: 'BannerRepository');
    }
    
    return list;
  }
}
