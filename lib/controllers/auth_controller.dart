import 'package:flutter/material.dart';
import 'package:pizzaapp/core/storage/secure_auth_store.dart';
import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/services/auth_service.dart';
import 'package:pizzaapp/services/biometric_auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _service;
  final VoidCallback? onLogout;
  final SecureAuthStore _secureAuthStore;
  final BiometricAuthService _biometricAuth;

  AuthController(
    this._service, {
    this.onLogout,
    SecureAuthStore? secureAuthStore,
    BiometricAuthService? biometricAuth,
  }) : _secureAuthStore = secureAuthStore ?? SecureAuthStore(),
       _biometricAuth = biometricAuth ?? BiometricAuthService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Usuario? get currentUser => _service.currentUser;

  /// Verdadero si hay una sesión activa en memoria (usado por las guardas de
  /// ruta del router, H-08).
  bool get haySesion => _service.currentUser != null;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.login(username, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createAdmin(
    String nombre,
    String username,
    String password,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.createAdmin(nombre, username, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> generateRecoveryCode() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final code = await _service.createRecoveryCodeForCurrentAdmin();
      _isLoading = false;
      notifyListeners();
      return code;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> resetAdminPassword({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.resetAdminPassword(
        username: username,
        recoveryCode: recoveryCode,
        newPassword: newPassword,
      );
      await _revocarAccesoTrasReset(username);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  void updateCurrentUser(Usuario updated) {
    _service.updateCurrentUser(updated);
    notifyListeners();
  }

  /// Cierra la sesión en memoria y revoca el acceso rápido con huella
  /// (FS-11). El nombre recordado se conserva para autocompletar el login.
  Future<void> logout() async {
    _service.logout();
    onLogout?.call();
    notifyListeners();
    await _revocarAccesoHuella();
  }

  /// Lee el usuario recordado para autocompletar el login (solo nombre e id;
  /// nunca la contraseña).
  Future<UsuarioRecordado?> leerUsuarioRecordado() => _secureAuthStore.leer();

  /// Persiste la decisión del checkbox "Recordar usuario" tras un login
  /// exitoso: guarda el usuario actual o borra el registro si no se marcó.
  /// Con [usarHuella] se habilita además el acceso rápido con huella; si no
  /// se marcó, se revoca el permiso sin borrar el nombre recordado.
  Future<void> actualizarUsuarioRecordado(
    bool recordar, {
    bool usarHuella = false,
  }) async {
    if (!recordar) {
      await _secureAuthStore.limpiar();
      return;
    }
    final usuario = _service.currentUser;
    final userId = usuario?.id;
    if (usuario == null || userId == null) return;
    await _secureAuthStore.guardar(
      username: usuario.username,
      userId: userId,
    );
    if (usarHuella) {
      await _secureAuthStore.habilitarAccesoHuella();
    } else {
      await _secureAuthStore.revocarAccesoHuella();
    }
  }

  /// Verdadero si el dispositivo tiene biometría disponible y enrolada.
  Future<bool> huellaDisponible() => _biometricAuth.disponible();

  /// Verdadero si puede ofrecerse el acceso rápido con huella (FS-11): hay
  /// permiso habilitado, usuario recordado y biometría disponible.
  Future<bool> puedeEntrarConHuella() async {
    try {
      if (!await _secureAuthStore.accesoHuellaHabilitado()) return false;
      if (await _secureAuthStore.leer() == null) return false;
      return await _biometricAuth.disponible();
    } catch (_) {
      return false;
    }
  }

  /// Acceso rápido (FS-11): pide la huella y, si es aceptada, restaura la
  /// sesión del usuario recordado revalidando `activo = 1 AND bloqueado = 0`.
  /// Si el usuario ya no es válido, revoca el permiso y pide la contraseña.
  Future<bool> entrarConHuella() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (!await _secureAuthStore.accesoHuellaHabilitado()) return false;
      final recordado = await _secureAuthStore.leer();
      if (recordado == null) {
        _error = 'No hay un usuario recordado. Inicia sesión con tu contraseña.';
        return false;
      }
      if (!await _biometricAuth.autenticar()) return false;
      await _service.loginRapido(recordado.userId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      await _revocarAccesoHuella();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Revoca el permiso de huella (mejor esfuerzo: un almacén no disponible
  /// no debe romper la sesión ni el cierre de sesión).
  Future<void> _revocarAccesoHuella() async {
    try {
      await _secureAuthStore.revocarAccesoHuella();
    } catch (_) {
      // Sin acceso al almacén seguro no hay permiso que revocar.
    }
  }

  /// Si se restablece la contraseña del usuario recordado, se revoca su
  /// acceso rápido: la próxima entrada debe usar la contraseña nueva.
  Future<void> _revocarAccesoTrasReset(String username) async {
    try {
      final recordado = await _secureAuthStore.leer();
      if (recordado == null || recordado.username != username.trim()) return;
      await _secureAuthStore.revocarAccesoHuella();
    } catch (_) {
      // El restablecimiento no debe fallar por el almacén de conveniencia.
    }
  }
}
