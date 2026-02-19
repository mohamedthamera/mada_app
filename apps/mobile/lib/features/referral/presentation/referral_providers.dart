import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/referral_repository.dart';

final userReferralProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  return ref.read(referralRepositoryProvider).getUserReferral();
});
