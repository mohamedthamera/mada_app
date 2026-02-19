import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/di.dart';

final deviceCheckRepositoryProvider = Provider<DeviceCheckRepository>(
  (ref) => DeviceCheckRepository(ref.read(supabaseClientProvider)),
);

/// نتيجة التحقق: مسموح، محظور، أو خطأ (مثلاً غير مسجّل الدخول)
class DeviceCheckResult {
  const DeviceCheckResult({this.allowed = false, this.banned = false, this.error});
  final bool allowed;
  final bool banned;
  final String? error;

  static const DeviceCheckResult allowedResult = DeviceCheckResult(allowed: true);
  static const DeviceCheckResult bannedResult = DeviceCheckResult(banned: true);
}

class DeviceCheckRepository {
  DeviceCheckRepository(this._client);

  final SupabaseClient _client;

  /// يحصل على معرّف جهاز ثابت (لربط الحساب بجهاز واحد)
  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      return android.id;
    }
    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      return ios.identifierForVendor ?? 'ios-${DateTime.now().millisecondsSinceEpoch}';
    }
    return 'unknown-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// يتحقق من الجهاز أو يسجّله. إن كان الحساب محظوراً أو الجهاز مختلف يُرجع banned.
  Future<DeviceCheckResult> checkDeviceOrRegister() async {
    final deviceId = await getDeviceId();
    try {
      final res = await _client.rpc(
        'check_device_or_register',
        params: {'p_device_id': deviceId},
      );
      if (res is! Map<String, dynamic>) {
        return const DeviceCheckResult(error: 'استجابة غير متوقعة');
      }
      final allowed = res['allowed'] as bool? ?? false;
      final banned = res['banned'] as bool? ?? false;
      final err = res['error'] as String?;
      if (banned) return DeviceCheckResult.bannedResult;
      if (err != null && err.isNotEmpty) return DeviceCheckResult(error: err);
      if (allowed) return DeviceCheckResult.allowedResult;
      return const DeviceCheckResult(error: 'غير مسموح');
    } catch (e) {
      return DeviceCheckResult(error: e.toString());
    }
  }
}
