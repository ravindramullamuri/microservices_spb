import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart'; // Required for PlatformException

class SecureStorageUtils {
  // Private constructor
  SecureStorageUtils._internal();

  // Singleton instance
  static final SecureStorageUtils _instance = SecureStorageUtils._internal();

  // Factory constructor
  factory SecureStorageUtils() => _instance;

  // Secure storage instance
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Write
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Safe Read – handles decryption failures gracefully
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (e) {
      // Detect BadPaddingException / BAD_DECRYPT (common on Android after reinstall/update)
      if (e.message?.contains('BadPaddingException') == true ||
          e.message?.contains('BAD_DECRYPT') == true) {
        print('Secure storage decryption failed for key "$key" – clearing corrupted data');
        // Clear only the problematic key (safer than deleteAll if you have multiple keys)
        await _storage.delete(key: key);
        // Optional: if you want to clear everything on any corruption:
        // await _storage.deleteAll();
      }
      return null; // Act as if no value was stored
    } catch (e) {
      print('Unexpected error reading secure storage: $e');
      return null;
    }
  }

  // Delete SINGLE key
  Future<void> delete(String key) async {
    print("Deleting key: $key");
    await _storage.delete(key: key);
  }

  // Optional: Clear everything (use with caution)
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // Read all
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } on PlatformException catch (e) {
      if (e.message?.contains('BadPaddingException') == true ||
          e.message?.contains('BAD_DECRYPT') == true) {
        print('Corrupted secure storage detected – clearing all');
        await _storage.deleteAll();
      }
      return {};
    }
  }

  // Save Tokens
   Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await write(StorageKeys.accessToken, accessToken);
    await write(StorageKeys.refreshToken, refreshToken);
  }

}

class StorageKeys {
  static const accessToken = 'auth_token';
  static const refreshToken = 'refresh_token';
}
