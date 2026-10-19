import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Datos mínimos del "usuario recordado" que se persisten entre sesiones.
///
/// Nunca incluye la contraseña: solo el nombre de usuario y su id.
class UsuarioRecordado {
  const UsuarioRecordado({required this.username, required this.userId});

  final String username;
  final int userId;
}

/// Persistencia del usuario recordado (FS-10) sobre `flutter_secure_storage`
/// (Keystore en Android / Keychain en iOS).
///
/// Regla dura de la edición de seguridad (S3): **nunca** se persiste la
/// contraseña. La ausencia de datos equivale a "no recordar usuario".
class SecureAuthStore {
  SecureAuthStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _claveUsername = 'auth_username';
  static const _claveUserId = 'auth_user_id';

  /// Guarda el usuario que acaba de iniciar sesión (solo nombre + id).
  Future<void> guardar({required String username, required int userId}) async {
    await _storage.write(key: _claveUsername, value: username);
    await _storage.write(key: _claveUserId, value: userId.toString());
  }

  /// Devuelve el usuario recordado, o `null` si no hay datos completos.
  Future<UsuarioRecordado?> leer() async {
    final username = await _storage.read(key: _claveUsername);
    final userIdRaw = await _storage.read(key: _claveUserId);
    if (username == null || username.isEmpty || userIdRaw == null) {
      return null;
    }
    final userId = int.tryParse(userIdRaw);
    if (userId == null) return null;
    return UsuarioRecordado(username: username, userId: userId);
  }

  /// Borra el usuario recordado (p. ej., al desmarcar "Recordar usuario").
  Future<void> limpiar() async {
    await _storage.delete(key: _claveUsername);
    await _storage.delete(key: _claveUserId);
  }
}
