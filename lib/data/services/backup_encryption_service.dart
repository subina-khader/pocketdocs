import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class BackupEncryptionService {
  static const List<int> _magic = [
    0x50, // P
    0x44, // D
    0x42, // B
    0x4B, // K
  ];

  static const int _version = 2;

  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _macLength = 16;

  // Argon2id parameters.
  //
  // 19 MiB memory, 2 iterations, 1 lane.
  static const int _argonMemory = 19 * 1024;
  static const int _argonIterations = 2;
  static const int _argonParallelism = 1;
  static const int _keyLength = 32;

  final AesGcm _aesGcm = AesGcm.with256bits();

  final Argon2id _argon2id = Argon2id(
    memory: _argonMemory,
    parallelism: _argonParallelism,
    iterations: _argonIterations,
    hashLength: _keyLength,
  );

  Future<Uint8List> encrypt({
    required Uint8List data,
    required String password,
  }) async {
    _validatePassword(password);

    final salt = _generateRandomBytes(_saltLength);

    final key = await _argon2id.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    final nonce = _aesGcm.newNonce();

    final secretBox = await _aesGcm.encrypt(
      data,
      secretKey: key,
      nonce: nonce,
    );

    return Uint8List.fromList([
      ..._magic,
      _version,
      ...salt,
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  Future<Uint8List> decrypt({
    required Uint8List encryptedData,
    required String password,
  }) async {
    _validatePassword(password);

    final minimumLength =
        _magic.length +
            1 +
            _saltLength +
            _nonceLength +
            _macLength;

    if (encryptedData.length < minimumLength) {
      throw const FormatException(
        'Invalid or corrupted PocketDocs backup.',
      );
    }

    _validateHeader(encryptedData);

    var offset = _magic.length;

    final version = encryptedData[offset];
    offset++;

    if (version != _version) {
      throw const FormatException(
        'This PocketDocs backup version is not supported.',
      );
    }

    final salt = encryptedData.sublist(
      offset,
      offset + _saltLength,
    );

    offset += _saltLength;

    final nonce = encryptedData.sublist(
      offset,
      offset + _nonceLength,
    );

    offset += _nonceLength;

    final macStart = encryptedData.length - _macLength;

    if (macStart <= offset) {
      throw const FormatException(
        'Invalid or corrupted PocketDocs backup.',
      );
    }

    final cipherText = encryptedData.sublist(
      offset,
      macStart,
    );

    final mac = Mac(
      encryptedData.sublist(macStart),
    );

    final key = await _argon2id.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    try {
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
    } catch (_) {
      throw const FormatException(
        'Incorrect backup password or corrupted backup.',
      );
    }
  }

  void _validatePassword(String password) {
    if (password.length < 8) {
      throw const FormatException(
        'Backup password must be at least 8 characters.',
      );
    }
  }

  void _validateHeader(Uint8List data) {
    for (var i = 0; i < _magic.length; i++) {
      if (data[i] != _magic[i]) {
        throw const FormatException(
          'This is not a valid PocketDocs backup.',
        );
      }
    }
  }

  List<int> _generateRandomBytes(int length) {
    final random = Random.secure();

    return List<int>.generate(
      length,
          (_) => random.nextInt(256),
    );
  }
}