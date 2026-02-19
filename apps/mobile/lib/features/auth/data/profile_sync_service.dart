import 'package:supabase_flutter/supabase_flutter.dart';

/// Syncs user info from auth to profiles table after OAuth or login.
class ProfileSyncService {
  ProfileSyncService(this._client);

  final SupabaseClient _client;

  Future<void> syncCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final metadata = user.userMetadata ?? {};
    final fullName = metadata['full_name'] as String? ??
        metadata['name'] as String? ??
        user.email?.split('@').first ??
        'مستخدم';
    final avatarUrl = metadata['avatar_url'] as String?;
    final email = user.email ?? '';

    await _client.from('profiles').upsert(
      {
        'id': user.id,
        'name': fullName,
        'email': email,
        'avatar_url': avatarUrl,
      },
      onConflict: 'id',
    );
  }
}
