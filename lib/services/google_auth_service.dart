import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../legal_texts.dart';

class GoogleAuthService {
  static Future<Map<String, dynamic>?> signIn({String rol = 'comercio'}) async {
    try {
      final provider = GoogleAuthProvider();
      // En Flutter Web se usa popup (mobile usaría signInWithRedirect, pero estas apps son solo web)
      final result = await FirebaseAuth.instance.signInWithPopup(provider);
      final idToken = await result.user?.getIdToken();
      if (idToken == null) return null;

      final res = await ApiService.post('/auth/google-login', {
        'idToken': idToken,
        'rol': rol,
        'tc_version': kTcVersion,
        'privacidad_version': kPrivacidadVersion,
      });
      if (res['status'] == 200) return res['data'];
      return null;
    } catch (e) {
      debugPrint('[GoogleAuth] Error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
