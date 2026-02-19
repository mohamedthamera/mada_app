import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/notifications/fcm_service.dart';
import 'features/auth/data/profile_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  await dotenv.load(fileName: '.env.$env');
  var firebaseReady = true;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    firebaseReady = false;
    debugPrint('Firebase init skipped: $e');
  }
  await Hive.initFlutter();
  await Hive.openBox<double>('progress_box');

  final revenueCatKey = dotenv.env['REVENUECAT_API_KEY'] ?? '';
  if (revenueCatKey.isNotEmpty) {
    await Purchases.configure(PurchasesConfiguration(revenueCatKey));
  }
  if (firebaseReady) {
    await FcmService().initialize();
  }

  await SupabaseClientFactory.initialize(
    SupabaseConfig(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      authRedirectUrl: 'com.meda.app://login-callback/',
    ),
  );

  // Sync profile when auth state changes (OAuth callback, login, etc.)
  final profileSync = ProfileSyncService(Supabase.instance.client);
  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    if (data.session?.user != null) {
      try {
        await profileSync.syncCurrentUser();
      } catch (e) {
        debugPrint('Profile sync error: $e');
      }
      // Notify router to re-evaluate redirect (e.g. after OAuth callback)
      refreshAuthRedirect();
    }
  });

  // Sync on startup if already logged in
  if (Supabase.instance.client.auth.currentUser != null) {
    try {
      await profileSync.syncCurrentUser();
    } catch (e) {
      debugPrint('Profile sync error: $e');
    }
  }

  // منع لقطات الشاشة والتسجيل على أندرويد (المحتوى يظهر أسود عند التصوير)
  if (Platform.isAndroid) {
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (e) {
      debugPrint('FLAG_SECURE error: $e');
    }
  }

  runApp(const ProviderScope(child: EverestApp()));
}

