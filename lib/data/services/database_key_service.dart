import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseKeyService {
  static const String _storageKey = 'pocketdocs_database_key';

  final FlutterSecureStorage secureStorage;

  DatabaseKeyService({
    FlutterSecureStorage? secureStorage,
  }) : secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<String> getOrCreateKey() async {
    final existingKey = await secureStorage.read(
      key: _storageKey,
    );

    if (existingKey != null && existingKey.isNotEmpty) {
      return existingKey;
    }

    final random = Random.secure();

    final bytes = Uint8List.fromList(
      List<int>.generate(
        32,
            (_) => random.nextInt(256),
      ),
    );

    final key = base64UrlEncode(bytes);

    await secureStorage.write(
      key: _storageKey,
      value: key,
    );

    return key;
  }
}