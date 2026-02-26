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
      // TODO: Here you would call your backend API to update the token
    }
  }

  void listenToTokenRefresh() {
    _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenLocally(newToken);
    });
  }
}
