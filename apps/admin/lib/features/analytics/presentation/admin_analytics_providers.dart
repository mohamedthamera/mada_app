import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_analytics_repository.dart';

final adminCountsProvider = FutureProvider((ref) {
  return ref.read(adminAnalyticsRepositoryProvider).fetchCounts();
});

/// أعداد حقيقية للوحة الأدمن: مسجلون، مشتركون، دورات، اشتراكات، معدل إكمال
final adminDashboardCountsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(adminAnalyticsRepositoryProvider).fetchDashboardCounts();
});

final adminCompletionRateProvider = FutureProvider<double>((ref) {
  return ref.read(adminAnalyticsRepositoryProvider).fetchCompletionRate();
});

final adminEnrollmentsPerDayProvider = FutureProvider<List<int>>((ref) {
  return ref.read(adminAnalyticsRepositoryProvider).fetchEnrollmentsPerDayLast30();
});
