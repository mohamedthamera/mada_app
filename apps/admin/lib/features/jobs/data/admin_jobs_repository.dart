import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di.dart';

final adminJobsRepositoryProvider = Provider<AdminJobsRepository>(
  (ref) => AdminJobsRepository(ref.read(supabaseClientProvider)),
);

class AdminJobsRepository {
  AdminJobsRepository(this._client);
  final dynamic _client;

  Future<List<Map<String, dynamic>>> fetchJobs() async {
    final res = await _client
        .from('jobs')
        .select()
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<void> insertJob({
    required String titleAr,
    required String companyName,
    required String location,
    required String jobType,
    required String descriptionAr,
    String? salary,
    String? workMode,
    String? workDays,
    String? requirements,
    String? applyUrl,
  }) async {
    await _client.from('jobs').insert({
      'title_ar': titleAr,
      'company_name': companyName,
      'location': location,
      'job_type': jobType,
      'description_ar': descriptionAr,
      'salary': salary,
      'work_mode': workMode,
      'work_days': workDays,
      'requirements': requirements,
      'apply_url': applyUrl,
    });
  }

  Future<void> updateJob({
    required String id,
    required String titleAr,
    required String companyName,
    required String location,
    required String jobType,
    required String descriptionAr,
    String? salary,
    String? workMode,
    String? workDays,
    String? requirements,
    String? applyUrl,
  }) async {
    await _client.from('jobs').update({
      'title_ar': titleAr,
      'company_name': companyName,
      'location': location,
      'job_type': jobType,
      'description_ar': descriptionAr,
      'salary': salary,
      'work_mode': workMode,
      'work_days': workDays,
      'requirements': requirements,
      'apply_url': applyUrl,
    }).eq('id', id);
  }

  Future<void> deleteJob(String id) async {
    await _client.from('jobs').delete().eq('id', id);
  }
}

