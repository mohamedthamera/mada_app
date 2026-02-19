import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../data/admin_banner_repository.dart';
import 'dart:typed_data';

final adminBannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  final repository = ref.watch(adminBannerRepositoryProvider);
  return repository.fetchBanners();
});

class AdminBannerNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminBannerRepository _repository;
  final Ref _ref;

  AdminBannerNotifier(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> addBanner({
    required BannerModel banner,
    Uint8List? imageBytes,
    String? fileName,
    Uint8List? videoBytes,
    String? videoFileName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addBanner(
        banner: banner,
        imageBytes: imageBytes,
        fileName: fileName,
        videoBytes: videoBytes,
        videoFileName: videoFileName,
      );
      _ref.invalidate(adminBannersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateBanner({
    required BannerModel banner,
    Uint8List? imageBytes,
    String? fileName,
    Uint8List? videoBytes,
    String? videoFileName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateBanner(
        banner: banner,
        imageBytes: imageBytes,
        fileName: fileName,
        videoBytes: videoBytes,
        videoFileName: videoFileName,
      );
      _ref.invalidate(adminBannersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBanner(
    String id,
    String imageUrl, {
    String? videoUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteBanner(id, imageUrl, videoUrl: videoUrl);
      _ref.invalidate(adminBannersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminBannerActionProvider =
    StateNotifierProvider<AdminBannerNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(adminBannerRepositoryProvider);
      return AdminBannerNotifier(repository, ref);
    });
