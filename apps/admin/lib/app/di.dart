import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/shared.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => SupabaseClientFactory.client,
);

