import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';

class AuthService {
  final UsuarioRepository _repository;
  Usuario? _currentUser;

  AuthService(this._repository);

  Usuario? get currentUser => _currentUser;

  Future<bool> checkAdminExists() async {
    return await _repository.adminExists();
  }

  Future<Usuario> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      throw Exception('Usuario y contraseña son requeridos.');
    }

    // El repositorio hace la validacion de hash contra SQLite
    final usuario = await _repository.authenticate(username.trim(), password);
    
    if (usuario == null) {
      throw Exception('Credenciales incorrectas o usuario inactivo.');
    }

    _currentUser = usuario;
    return usuario;
  }

  Future<Usuario> createAdmin(String nombre, String username, String password, {String? correo, String? fotoRuta}) async {
    if (nombre.trim().isEmpty || username.trim().isEmpty || password.isEmpty) {
      throw Exception('Todos los campos son obligatorios.');
    }
    
    if (password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres.');
    }

    final adminExists = await _repository.adminExists();
    if (adminExists) {
      throw Exception('Ya existe un administrador registrado en el sistema.');
    }

    final passwordHash = HashUtils.hashPassword(password);
    final admin = Usuario(
      nombre: nombre.trim(),
      username: username.trim(),
      passwordHash: passwordHash,
      rol: 'admin',
      activo: 1,
    );

    final id = await _repository.createUsuario(admin);
    final newUser = Usuario(
      id: id,
      nombre: admin.nombre,
      username: admin.username,
      passwordHash: admin.passwordHash,
      rol: admin.rol,
      activo: admin.activo,
    );
    
    _currentUser = newUser;
    return newUser;
  }

  void logout() {
    _currentUser = null;
  }
}
