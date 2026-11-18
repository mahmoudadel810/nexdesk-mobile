import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the refresh token lives between launches. The access token is never stored: it stays in memory.
abstract interface class TokenStore {
  Future<String?> read();

  Future<void> write(String refreshToken);

  Future<void> clear();
}

/// The Keychain on iOS (this device only, not synced to iCloud) and the Keystore-backed storage on Android.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
          );

  static const _key = 'nexdesk.refresh-token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String refreshToken) => _storage.write(key: _key, value: refreshToken);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// For tests.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String refreshToken) async => value = refreshToken;

  @override
  Future<void> clear() async => value = null;
}
