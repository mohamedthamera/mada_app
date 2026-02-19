import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/community_repository.dart';

final discussionsProvider = FutureProvider((ref) {
  return ref.read(communityRepositoryProvider).fetchDiscussions();
});

