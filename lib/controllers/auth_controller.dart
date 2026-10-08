import 'package:flutter/material.dart';
import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _service;

  AuthController(this._service);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Usuario? get currentUser => _service.currentUser;

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

  Future<bool> createAdmin(String nombre, String username, String password) async {
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

  void logout() {
    _service.logout();
    notifyListeners();
  }
}
