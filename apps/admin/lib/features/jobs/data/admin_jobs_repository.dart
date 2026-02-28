import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di.dart';

final adminJobsRepositoryProvider = Provider<AdminJobsRepository>(
  (ref) => AdminJobsRepository(ref.read(supabaseClientProvider)),
);

class AdminJobsRepository {
  AdminJobsRepository(this._client);
  final dynamic _client;

  /// جلب قائمة الوظائف: محاولة RPC أولاً ثم الاستعلام المباشر كبديل. لا يرمي أبداً.
  Future<List<Map<String, dynamic>>> fetchJobs() async {
    try {
      final res = await _client.rpc('admin_list_jobs');
      if (res == null) return [];
      final list = res is List ? res : <dynamic>[];
      return list
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : null)
          .whereType<Map<String, dynamic>>()
          .where((m) => m['id'] != null)
          .toList();
    } catch (_) {
      try {
        final res = await _client.from('jobs').select().order('created_at', ascending: false);
        if (res == null || res is! List) return [];
        final list = res;
        return list
            .map<Map<String, dynamic>?>((e) => e is Map ? Map<String, dynamic>.from(e) : null)
            .whereType<Map<String, dynamic>>()
            .toList();
      } catch (_) {
        return [];
      }
    }
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

