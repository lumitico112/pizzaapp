import 'dart:math';

import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';

class AuthService {
  final UsuarioRepository _repository;
  final DateTime Function() _clock;
  Usuario? _currentUser;
  String? _generatedRecoveryCode;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(seconds: 30);
  static const _recoveryAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  AuthService(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  Usuario? get currentUser => _currentUser;
  int get failedAttempts => _failedAttempts;
  DateTime? get lockedUntil => _lockedUntil;

  void _checkRateLimit() {
    final until = _lockedUntil;
    if (until == null) return;
    final now = _clock();
    if (now.isBefore(until)) {
      final remaining = until.difference(now).inSeconds.clamp(1, 30);
      throw Exception(
        'Demasiados intentos fallidos. Espera $remaining segundos antes de volver a intentar.',
      );
    }
    _lockedUntil = null;
    _failedAttempts = 0;
  }

  void _recordFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= maxFailedAttempts) {
      _lockedUntil = _clock().add(lockoutDuration);
      throw Exception(
        'Demasiados intentos fallidos. Espera ${lockoutDuration.inSeconds} segundos antes de volver a intentar.',
      );
    }
  }

  void _resetFailedAttempts() {
    _failedAttempts = 0;
    _lockedUntil = null;
  }

  Future<int> authorizeAdminOperation(String password) async {
    final current = _currentUser;
    if (current == null || current.rol != 'admin' || password.isEmpty) {
      throw Exception(
        'La reapertura requiere autorización de la administradora.',
      );
    }
    final verified = await _repository.authenticate(current.username, password);
    if (verified == null ||
        verified.id != current.id ||
        verified.rol != 'admin') {
      throw Exception('La contraseña de autorización no es válida.');
    }
    return current.id!;
  }

  String? takeGeneratedRecoveryCode() {
    final code = _generatedRecoveryCode;
    _generatedRecoveryCode = null;
    return code;
  }

  Future<bool> checkAdminExists() async {
    return await _repository.adminExists();
  }

  Future<Usuario> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      throw Exception('Usuario y contraseña son requeridos.');
    }

    _checkRateLimit();

    // El repositorio hace la validacion de hash contra SQLite
    final usuario = await _repository.authenticate(username.trim(), password);

    if (usuario == null) {
      _recordFailedAttempt();
      throw Exception('Credenciales incorrectas o usuario inactivo.');
    }

    _resetFailedAttempts();
    _currentUser = usuario;
    return usuario;
  }

  Future<Usuario> createAdmin(
    String nombre,
    String username,
    String password, {
    String? correo,
    String? fotoRuta,
    dynamic executor,
  }) async {
    if (nombre.trim().isEmpty || username.trim().isEmpty || password.isEmpty) {
      throw Exception('Todos los campos son obligatorios.');
    }

    if (password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres.');
    }

    final adminExists = await _repository.adminExists(executor: executor);
    if (adminExists) {
      throw Exception('Ya existe un administrador registrado en el sistema.');
    }

    final recoveryCode = _generateRecoveryCode();
    _generatedRecoveryCode = recoveryCode;
    final passwordHash = HashUtils.hashPassword(password);
    final admin = Usuario(
      nombre: nombre.trim(),
      username: username.trim(),
      correo: correo?.trim(),
      passwordHash: passwordHash,
      recoveryCode: HashUtils.hashRecoveryCode(recoveryCode),
      rol: 'admin',
      fotoRuta: fotoRuta,
      activo: 1,
    );

    final id = await _repository.createUsuario(admin, executor: executor);
    final newUser = Usuario(
      id: id,
      nombre: admin.nombre,
      username: admin.username,
      correo: admin.correo,
      passwordHash: admin.passwordHash,
      recoveryCode: admin.recoveryCode,
      rol: admin.rol,
      fotoRuta: admin.fotoRuta,
      activo: admin.activo,
    );

    _currentUser = newUser;
    return newUser;
  }

  Future<String> createRecoveryCodeForCurrentAdmin() async {
    final user = _currentUser;
    if (user == null || user.rol != 'admin' || user.id == null) {
      throw Exception(
        'Inicia sesión como administradora para configurar la recuperación.',
      );
    }
    final code = _generateRecoveryCode();
    await _repository.saveRecoveryCode(
      user.id!,
      HashUtils.hashRecoveryCode(code),
    );
    _currentUser = Usuario(
      id: user.id,
      nombre: user.nombre,
      username: user.username,
      correo: user.correo,
      passwordHash: user.passwordHash,
      rol: user.rol,
      fotoRuta: user.fotoRuta,
      activo: user.activo,
      bloqueado: user.bloqueado,
      recoveryCode: HashUtils.hashRecoveryCode(code),
      createdAt: user.createdAt,
    );
    return code;
  }

  Future<void> resetAdminPassword({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) async {
    if (username.trim().isEmpty || recoveryCode.trim().isEmpty) {
      throw Exception('Escribe el usuario y la clave de rescate.');
    }
    if (newPassword.length < 8) {
      throw Exception('La nueva contraseña debe tener al menos 8 caracteres.');
    }
    _checkRateLimit();
    final admin = await _repository.findActiveAdmin(username);
    if (admin == null ||
        admin.recoveryCode == null ||
        HashUtils.hashRecoveryCode(recoveryCode) != admin.recoveryCode) {
      _recordFailedAttempt();
      throw Exception('Usuario o clave de rescate incorrectos.');
    }
    _resetFailedAttempts();
    await _repository.updateAdminPassword(
      admin.id!,
      HashUtils.hashPassword(newPassword),
    );
  }

  String _generateRecoveryCode() {
    final random = Random.secure();
    final chars = List.generate(
      24,
      (_) => _recoveryAlphabet[random.nextInt(_recoveryAlphabet.length)],
    ).join();
    return '${chars.substring(0, 6)}-${chars.substring(6, 12)}-${chars.substring(12, 18)}-${chars.substring(18)}';
  }

  void updateCurrentUser(Usuario updated) {
    if (_currentUser?.id == updated.id) {
      _currentUser = updated;
    }
  }

  void logout() {
    _currentUser = null;
  }
}
