import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_influencer_repository.dart';

final adminInfluencersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminInfluencerRepositoryProvider).list();
});
