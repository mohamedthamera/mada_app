import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.read(supabaseClientProvider)),
);

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final dynamic _client;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

