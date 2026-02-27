import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');

  var url = String.fromEnvironment('SUPABASE_URL', defaultValue: '').trim();
  var anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '').trim();

  if (url.isEmpty || anonKey.isEmpty) {
    try {
      await dotenv.load(fileName: 'env.$env');
    } catch (_) {
      try {
        await dotenv.load(fileName: '.env.$env');
      } catch (_) {}
    }
    url = (dotenv.env['SUPABASE_URL']?.trim() ?? url).trim();
    anonKey = (dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? anonKey).trim();
  }

  if (url.isEmpty || anonKey.isEmpty) {
    runApp(_ConfigErrorApp(
      message: 'إعدادات Supabase ناقصة.\nأضف SUPABASE_URL و SUPABASE_ANON_KEY في ملف env.$env أو .env.$env',
    ));
    return;
  }
  url = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  await SupabaseClientFactory.initialize(
    SupabaseConfig(url: url, anonKey: anonKey),
  );
  runApp(const ProviderScope(child: AdminApp()));
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

