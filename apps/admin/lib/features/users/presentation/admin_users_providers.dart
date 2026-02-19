import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_users_repository.dart';

final adminUsersProvider = FutureProvider((ref) {
  return ref.read(adminUsersRepositoryProvider).fetchUsers();
});

