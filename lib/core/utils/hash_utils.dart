import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtils {
  /// Hashea una contraseña usando SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifica si una contraseña coincide con su hash
  static bool verifyPassword(String password, String hashed) {
    return hashPassword(password) == hashed;
  }
}
