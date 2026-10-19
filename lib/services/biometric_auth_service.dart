import 'package:local_auth/local_auth.dart';

/// Envoltorio de `local_auth` para el acceso rápido con huella (FS-11).
///
/// Es un candado de conveniencia contra el acceso físico casual (límite
/// declarado S2 de la edición de seguridad): no protege un dispositivo con
/// root ni un APK modificado. Nunca sustituye a la contraseña como secreto:
/// solo autoriza restaurar una sesión ya recordada.
class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Verdadero solo si el dispositivo soporta biometría y tiene al menos una
  /// biometría enrolada. Cualquier fallo del plugin (escritorio o pruebas sin
  /// canal nativo) equivale a "no disponible".
  Future<bool> disponible() async {
    try {
      if (!await _localAuth.canCheckBiometrics) return false;
      final biometricos = await _localAuth.getAvailableBiometrics();
      return biometricos.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Lanza el diálogo biométrico. Devuelve `true` solo si la persona se
  /// autenticó; una cancelación o un error devuelven `false` sin excepción.
  Future<bool> autenticar({
    String reason = 'Confirma tu identidad para entrar en Kimi Pizza POS',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on LocalAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
