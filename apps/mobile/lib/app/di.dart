import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => SupabaseClientFactory.client,
);

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final localeProvider = StateProvider<Locale>((ref) => const Locale('ar'));
final courseUpdatesProvider = StateProvider<bool>((ref) => true);
final marketingUpdatesProvider = StateProvider<bool>((ref) => false);

