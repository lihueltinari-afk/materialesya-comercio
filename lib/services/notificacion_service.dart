import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'api_service.dart';

class NotificacionService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      debugPrint('[FCM] Firebase inicializado');

      final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true);
      debugPrint('[FCM] Permiso: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _messaging.getToken(
        vapidKey: 'BA96DCSHavydO14TElueAhoOnbf1ChkkmsF2CiaUHlhJl6WCatsiPO2dSlLaaCLQh_c1XnvmLjSFwNK0HUHM0fA',
      );
      debugPrint('[FCM] Token: $token');
      if (token != null) await _enviarToken(token);

      _messaging.onTokenRefresh.listen(_enviarToken);
      FirebaseMessaging.onMessage.listen((msg) {
        debugPrint('📬 Notif: ${msg.notification?.title}');
      });
    } catch (e, st) {
      debugPrint('[FCM] ERROR: $e\n$st');
    }
  }

  static Future<void> _enviarToken(String token) async {
    try {
      await ApiService.post('/notificaciones/token', {'token': token, 'plataforma': 'web'});
    } catch (_) {}
  }
}
