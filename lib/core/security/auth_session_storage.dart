import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionSnapshot {
  const AuthSessionSnapshot({
    this.accessToken,
    this.refreshToken,
    this.tokenExpiry,
    this.currentUserJson,
  });

  final String? accessToken;
  final String? refreshToken;
  final String? tokenExpiry;
  final String? currentUserJson;
}

/// Secure storage for auth session artifacts.
///
/// This migrates legacy session data from SharedPreferences on first read and
/// immediately removes the plaintext copy.
class AuthSessionStorage {
  AuthSessionStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _currentUserKey = 'current_user';

  static const List<String> _legacyKeys = <String>[
    _accessTokenKey,
    _refreshTokenKey,
    _tokenExpiryKey,
    _currentUserKey,
  ];

  static Future<AuthSessionSnapshot> read() async {
    final snapshot = AuthSessionSnapshot(
      accessToken: await _storage.read(key: _accessTokenKey),
      refreshToken: await _storage.read(key: _refreshTokenKey),
      tokenExpiry: await _storage.read(key: _tokenExpiryKey),
      currentUserJson: await _storage.read(key: _currentUserKey),
    );

    final hasSecureData =
        snapshot.accessToken != null ||
        snapshot.refreshToken != null ||
        snapshot.tokenExpiry != null ||
        snapshot.currentUserJson != null;

    if (hasSecureData) {
      await clearLegacyPrefs();
      return snapshot;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacySnapshot = AuthSessionSnapshot(
      accessToken: prefs.getString(_accessTokenKey),
      refreshToken: prefs.getString(_refreshTokenKey),
      tokenExpiry: prefs.getString(_tokenExpiryKey),
      currentUserJson: prefs.getString(_currentUserKey),
    );

    final hasLegacyData =
        legacySnapshot.accessToken != null ||
        legacySnapshot.refreshToken != null ||
        legacySnapshot.tokenExpiry != null ||
        legacySnapshot.currentUserJson != null;

    if (hasLegacyData) {
      await save(
        accessToken: legacySnapshot.accessToken,
        refreshToken: legacySnapshot.refreshToken,
        tokenExpiry: legacySnapshot.tokenExpiry,
        currentUserJson: legacySnapshot.currentUserJson,
      );
      await clearLegacyPrefs();
    }

    return legacySnapshot;
  }

  static Future<void> save({
    String? accessToken,
    String? refreshToken,
    String? tokenExpiry,
    String? currentUserJson,
  }) async {
    await _writeOrDelete(_accessTokenKey, accessToken);
    await _writeOrDelete(_refreshTokenKey, refreshToken);
    await _writeOrDelete(_tokenExpiryKey, tokenExpiry);
    await _writeOrDelete(_currentUserKey, currentUserJson);
    await clearLegacyPrefs();
  }

  static Future<void> clear() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _tokenExpiryKey),
      _storage.delete(key: _currentUserKey),
    ]);
    await clearLegacyPrefs();
  }

  static Future<void> clearLegacyPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _legacyKeys) {
      await prefs.remove(key);
    }
  }

  static Future<void> _writeOrDelete(String key, String? value) {
    if (value == null || value.isEmpty) {
      return _storage.delete(key: key);
    }
    return _storage.write(key: key, value: value);
  }
}
