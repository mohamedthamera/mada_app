import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (_) {
      // Firebase غير مهيأ أو الإشعارات غير متاحة
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (_) {
      // Firebase غير مهيأ أو الإشعارات غير متاحة
    }
  }
}

