import 'package:flutter/material.dart';
import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _service;
  final VoidCallback? onLogout;

  AuthController(this._service, {this.onLogout});

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

  void logout() {
    _service.logout();
    onLogout?.call();
    notifyListeners();
  }
}
