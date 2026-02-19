import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig({
    required this.url,
    required this.anonKey,
    this.authRedirectUrl,
  });

  final String url;
  final String anonKey;
  /// Deep link for OAuth callback, e.g. com.meda.app://login-callback/
  final String? authRedirectUrl;
}

class SupabaseClientFactory {
  static String? _authRedirectUrl;

  static Future<void> initialize(SupabaseConfig config) async {
    _authRedirectUrl = config.authRedirectUrl;
    await Supabase.initialize(
      url: config.url,
      anonKey: config.anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static String? get authRedirectUrl => _authRedirectUrl;
}

