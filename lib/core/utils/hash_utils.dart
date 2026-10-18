import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class HashUtils {
  static const String schemePrefix = 'pbkdf2';
  static const int defaultIterations = 310000;
  static const int saltLengthBytes = 16;
  static final RegExp _legacySha256Hex = RegExp(r'^[a-fA-F0-9]{64}$');

  /// Hashea una contraseña usando PBKDF2-HMAC-SHA256 con sal aleatoria de 128 bits.
  /// Formato resultante: `pbkdf2$<iterations>$<salt_b64>$<hash_b64>`
  static String hashPassword(
    String password, {
    int iterations = defaultIterations,
    Uint8List? salt,
  }) {
    final effectiveSalt = salt ?? _generateSalt(saltLengthBytes);
    final derived = _pbkdf2Sha256(
      utf8.encode(password),
      effectiveSalt,
      iterations,
    );
    final saltB64 = base64Encode(effectiveSalt);
    final hashB64 = base64Encode(derived);
    return '$schemePrefix\$$iterations\$$saltB64\$$hashB64';
  }

  /// Indica si el hash almacenado corresponde al formato legacy SHA-256 sin sal
  /// y debe migrarse transparentemente a PBKDF2 tras autenticar al usuario.
  static bool isLegacyHash(String hashed) {
    if (hashed.startsWith('pbkdf2\$') || hashed.startsWith('pbkdf2_sha256\$')) {
      return false;
    }
    return _legacySha256Hex.hasMatch(hashed);
  }

  /// Verifica si una contraseña coincide con su hash (soporta PBKDF2 y legacy SHA-256).
  static bool verifyPassword(String password, String hashed) {
    if (hashed.startsWith('pbkdf2\$') || hashed.startsWith('pbkdf2_sha256\$')) {
      final parts = hashed.split('\$');
      if (parts.length != 4) return false;
      final iterations = int.tryParse(parts[1]);
      if (iterations == null || iterations <= 0) return false;
      try {
        final salt = base64Decode(parts[2]);
        final expectedHash = base64Decode(parts[3]);
        if (salt.isEmpty || expectedHash.isEmpty) return false;
        final actualHash = _pbkdf2Sha256(
          utf8.encode(password),
          salt,
          iterations,
        );
        return _constantTimeEquals(actualHash, expectedHash);
      } catch (_) {
        return false;
      }
    }

    // Compatibilidad retroactiva para contraseñas en SHA-256 hexadecimal sin sal
    final legacyDigest = sha256.convert(utf8.encode(password)).toString();
    return _constantTimeEquals(
      utf8.encode(legacyDigest.toLowerCase()),
      utf8.encode(hashed.toLowerCase()),
    );
  }

  /// A recovery code has high random entropy (24 chars from 32-symbol alphabet),
  /// so a one-way SHA-256 digest is sufficient and avoids storing plaintext.
  static String hashRecoveryCode(String code) {
    final normalized = code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  static Uint8List _generateSalt(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  /// Implementación PBKDF2-HMAC-SHA256 (RFC 2898) para 1 bloque de 256 bits (32 bytes).
  static Uint8List _pbkdf2Sha256(
    List<int> passwordBytes,
    List<int> salt,
    int iterations,
  ) {
    final hmac = Hmac(sha256, passwordBytes);
    final initialInput = Uint8List(salt.length + 4);
    initialInput.setRange(0, salt.length, salt);
    initialInput[salt.length] = 0;
    initialInput[salt.length + 1] = 0;
    initialInput[salt.length + 2] = 0;
    initialInput[salt.length + 3] = 1; // Block index 1 (big-endian)

    var u = Uint8List.fromList(hmac.convert(initialInput).bytes);
    final out = Uint8List.fromList(u);

    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

