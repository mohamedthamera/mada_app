import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../data/banner_repository.dart';

final bannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  return ref.read(bannerRepositoryProvider).fetchBanners();
});
