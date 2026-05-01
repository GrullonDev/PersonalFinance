import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Manages the AES-256 cipher key used to encrypt every Hive box.
///
/// Key lifecycle:
///   - First launch: generates 32 cryptographically-secure random bytes,
///     encodes them as base64url, and stores them in the platform's
///     secure enclave (iOS Keychain / Android EncryptedSharedPreferences
///     backed by the hardware Keystore).
///   - Subsequent launches: reads and decodes the same key — same data.
///
/// [openBoxSafe] handles the plaintext → encrypted migration: if a box
/// was created before encryption was added it deletes the stale file and
/// recreates it rather than crashing. Local data is a re-fetchable cache
/// (Firestore is the source of truth), so data loss on first upgrade is
/// acceptable.
class HiveEncryptionService {
  HiveEncryptionService._();

  static const String _keyAlias = 'hive_aes_key_v1';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    // Android: wraps the key with EncryptedSharedPreferences → hardware Keystore.
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    // iOS: key survives app restarts but not device restore without iCloud
    // Keychain backup (acceptable for an encryption key — users re-login).
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Returns the [HiveAesCipher] to pass to every [Hive.openBox] call.
  /// Creates and persists the key on the very first call.
  static Future<HiveAesCipher> getCipher() async {
    final String? encoded = await _storage.read(key: _keyAlias);

    final List<int> keyBytes;
    if (encoded != null) {
      keyBytes = base64Url.decode(encoded);
    } else {
      keyBytes = Hive.generateSecureKey();
      await _storage.write(
        key: _keyAlias,
        value: base64Url.encode(keyBytes),
      );
    }

    return HiveAesCipher(keyBytes);
  }

  /// Opens [name] with [cipher]. If the box was previously written without a
  /// cipher (pre-encryption data), deletes it and opens a fresh encrypted box.
  static Future<Box<T>> openBoxSafe<T>(
    String name,
    HiveAesCipher cipher,
  ) async {
    try {
      return await Hive.openBox<T>(name, encryptionCipher: cipher);
    } on HiveError {
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox<T>(name, encryptionCipher: cipher);
    }
  }
}
