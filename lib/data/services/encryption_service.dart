import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const String _keyStorageKey = 'pocketdocs_master_key';

  final FlutterSecureStorage secureStorage;

  final AesGcm _aesGcm = AesGcm.with256bits();

  EncryptionService({
    FlutterSecureStorage? secureStorage,
  }) : secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<SecretKey> _getOrCreateKey() async {
    final storedKey = await secureStorage.read(
      key: _keyStorageKey,
    );

    if (storedKey != null) {
      return SecretKey(
        base64Url.decode(storedKey),
      );
    }

    final key = await _aesGcm.newSecretKey();
    final keyBytes = await key.extract();

    await secureStorage.write(
      key: _keyStorageKey,
      value: base64UrlEncode(keyBytes.bytes),
    );
    return key;
  }

  Future<Uint8List> encryptBytes(
      Uint8List data,
      ) async {
    final key = await _getOrCreateKey();

    final nonce = _aesGcm.newNonce();

    final secretBox = await _aesGcm.encrypt(
      data,
      secretKey: key,
      nonce: nonce,
    );

    return Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  Future<Uint8List> decryptBytes(
      Uint8List encryptedData,
      ) async {
    if (encryptedData.length < 28) {
      throw const FormatException(
        'Invalid encrypted data.',
      );
    }

    final key = await _getOrCreateKey();

    final nonce = encryptedData.sublist(0, 12);

    final macStart = encryptedData.length - 16;

    final cipherText = encryptedData.sublist(
      12,
      macStart,
    );

    final mac = Mac(
      encryptedData.sublist(macStart),
    );

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    final decrypted = await _aesGcm.decrypt(
      secretBox,
      secretKey: key,
    );

    return Uint8List.fromList(decrypted);
  }
}