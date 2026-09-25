import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class PushTokenManager {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SharedPreferences _prefs;

  static const String _tokenKey = 'fcm_token';

  PushTokenManager(this._prefs);

  Future<String?> getToken() async {
    // Try to get from FCM
    String? token = await _fcm.getToken();

    if (token != null) {
      await _saveTokenLocally(token);
    } else {
      // Fallback to local if offline or something
      token = _prefs.getString(_tokenKey);
    }

    return token;
  }

  Future<void> _saveTokenLocally(String token) async {
    final String? oldToken = _prefs.getString(_tokenKey);
    if (oldToken != token) {
      await _prefs.setString(_tokenKey, token);
      developer.log('New FCM Token saved: $token');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Usar update para evitar el bug de Pigeon con set+merge en cloud_firestore 6.x
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'fcmToken': token});
        } catch (_) {
          // Si el documento no existe aún, lo creamos sin merge
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({'fcmToken': token});
          } catch (e) {
            developer.log('Error al guardar FCM Token en Firestore: $e');
          }
        }
      }
    }
  }

  void listenToTokenRefresh() {
    _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenLocally(newToken);
    });
  }
}
