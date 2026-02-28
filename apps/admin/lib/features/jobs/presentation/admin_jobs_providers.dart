import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_jobs_repository.dart';

final adminJobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ref.read(adminJobsRepositoryProvider).fetchJobs();
  } catch (_) {
    return [];
  }
});

