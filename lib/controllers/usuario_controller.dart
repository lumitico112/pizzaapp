import 'package:flutter/material.dart';
import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/services/usuario_service.dart';
import 'dart:math';

class UsuarioController extends ChangeNotifier {
  final UsuarioService _service;

  UsuarioController(this._service);

  List<Usuario> _usuarios = [];
  bool _isLoading = false;
  String? _error;

  List<Usuario> get usuarios => _usuarios;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUsuarios() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _usuarios = await _service.obtenerUsuarios();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Usuario?> getUsuario(int id) async {
    return await _service.obtenerUsuario(id);
  }

  Future<bool> guardarUsuario({
    int? id,
    required String nombre,
    required String username,
    String? correo,
    String? password,
    String? rol,
    String? fotoRuta,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.guardarUsuario(
        id: id,
        nombre: nombre,
        username: username,
        correo: correo,
        password: password,
        rol: rol,
        fotoRuta: fotoRuta,
      );
      await loadUsuarios();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleBloqueo(int id, bool bloqueadoActual) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.cambiarEstadoBloqueo(id, !bloqueadoActual);
      await loadUsuarios();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> darDeBaja(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.darDeBaja(id);
      await loadUsuarios();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String simularEnvioRecuperacion(String email) {
    final code = (1000 + Random().nextInt(9000)).toString();
    // En una app real esto actualizaría la BD y enviaría correo
    return code;
  }
}
