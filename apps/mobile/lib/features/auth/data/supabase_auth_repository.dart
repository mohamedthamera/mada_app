import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/di.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.read(supabaseClientProvider)),
);

void _ensureSupabaseConfigured() {
  final url = (dotenv.env['SUPABASE_URL'] ?? '').trim();
  final anonKey = (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();
  if (url.isEmpty || anonKey.isEmpty) {
    throw Exception('SUPABASE_NOT_CONFIGURED');
  }
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final dynamic _client;

  @override
  Future<void> signIn({required String email, required String password}) async {
    _ensureSupabaseConfigured();
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _ensureSupabaseConfigured();
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

  @override
  Future<void> resetPasswordForEmail(String email) async {
    _ensureSupabaseConfigured();
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'com.meda.app://login-callback/',
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}

