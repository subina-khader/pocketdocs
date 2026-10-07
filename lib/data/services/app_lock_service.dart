import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLockType {
  device,
  pin,
}

class AppLockService {
  static const String _enabledKey = 'app_lock_enabled';
  static const String _typeKey = 'app_lock_type';
  static const String _pinHashKey = 'app_lock_pin_hash';

  final LocalAuthentication _localAuth = LocalAuthentication();

  static const FlutterSecureStorage _secureStorage =
  FlutterSecureStorage();

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<AppLockType?> getLockType() async {
    final prefs = await SharedPreferences.getInstance();

    switch (prefs.getString(_typeKey)) {
      case 'device':
        return AppLockType.device;

      case 'pin':
        return AppLockType.pin;

      default:
        return null;
    }
  }

  Future<void> enableDeviceLock() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_enabledKey, true);
    await prefs.setString(_typeKey, 'device');

    // Only one App Lock method can be active.
    // Switching to device authentication removes the PocketDocs PIN.
    await _secureStorage.delete(
      key: _pinHashKey,
    );
  }

  Future<void> enablePinLock(String pin) async {
    if (!_isValidPin(pin)) {
      throw ArgumentError(
        'PIN must contain exactly 5 digits.',
      );
    }

    final prefs = await SharedPreferences.getInstance();

    final pinHash = _hashPin(pin);

    await _secureStorage.write(
      key: _pinHashKey,
      value: pinHash,
    );

    // PIN becomes the only active App Lock method.
    await prefs.setBool(
      _enabledKey,
      true,
    );

    await prefs.setString(
      _typeKey,
      'pin',
    );
  }

  Future<void> disableLock() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _enabledKey,
      false,
    );

    await prefs.remove(
      _typeKey,
    );

    await _secureStorage.delete(
      key: _pinHashKey,
    );
  }

  /// Checks whether the device has a supported authentication method.
  ///
  /// This can be fingerprint, face authentication, device PIN,
  /// password, or another authentication method supported by the OS.
  Future<bool> canAuthenticateWithDevice() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Authenticates the user using the device's authentication.
  ///
  /// [localizedReason] can be changed depending on why authentication
  /// is being requested.
  Future<bool> authenticateWithDevice({
    String localizedReason = 'Authenticate to open PocketDocs',
  }) async {
    try {
      final canAuthenticate =
      await canAuthenticateWithDevice();

      if (!canAuthenticate) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPin() async {
    final pinHash = await _secureStorage.read(
      key: _pinHashKey,
    );

    return pinHash != null;
  }

  Future<bool> verifyPin(String pin) async {
    if (!_isValidPin(pin)) {
      return false;
    }

    final savedHash = await _secureStorage.read(
      key: _pinHashKey,
    );

    if (savedHash == null) {
      return false;
    }

    final enteredHash = _hashPin(pin);

    return savedHash == enteredHash;
  }

  bool _isValidPin(String pin) {
    return RegExp(r'^\d{5}$').hasMatch(pin);
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }
}