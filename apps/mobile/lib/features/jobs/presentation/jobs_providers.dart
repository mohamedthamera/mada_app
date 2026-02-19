import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mada_mobile/app/di.dart';
import '../data/job.dart';

final jobsProvider = FutureProvider<List<Job>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final res = await client
      .from('jobs')
      .select()
      .order('created_at', ascending: false);
  final list = res as List;
  return list.map((e) {
    final row = e as Map<String, dynamic>;
    return Job(
      id: row['id'] as String,
      titleAr: row['title_ar'] as String,
      companyName: row['company_name'] as String,
      location: row['location'] as String,
      jobType: row['job_type'] as String,
      descriptionAr: row['description_ar'] as String,
      salary: row['salary'] as String?,
      workMode: row['work_mode'] as String?,
      workDays: row['work_days'] as String?,
      requirements: row['requirements'] as String?,
      applyUrl: row['apply_url'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
    );
  }).toList();
});

