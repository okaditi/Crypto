import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionHelper {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _keyStorageKey = 'encryption_key';

  /// Loads the encryption key if available, or generates and stores a new one
  static Future<void> loadKey() async {
    String? existingKey = await _secureStorage.read(key: _keyStorageKey);
    if (existingKey == null) {
      String newKey = _generateRandomKey(32); // 256-bit key
      await _secureStorage.write(key: _keyStorageKey, value: newKey);
    }
  }

  /// Returns the current encryption key
  static Future<String?> getEncryptionKey() async {
    return await _secureStorage.read(key: _keyStorageKey);
  }

  /// Optional: Removes the encryption key (for resetting or wiping)
  static Future<void> clearEncryptionKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
  }

  /// Generates a random base64-encoded key of given length
  static String _generateRandomKey(int length) {
    final Random random = Random.secure();
    final List<int> values = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }
}
