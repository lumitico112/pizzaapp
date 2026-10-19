import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';
import 'package:pizzaapp/services/auth_service.dart';

class UsuarioService {
  final UsuarioRepository _repository;
  final AuthService _authService;

  UsuarioService(this._repository, this._authService);

  Future<List<Usuario>> obtenerUsuarios({bool incluirInactivos = false}) async {
    return _repository.getUsuarios(incluirInactivos: incluirInactivos);
  }

  Future<Usuario?> obtenerUsuario(int id) async {
    return _repository.getUsuario(id);
  }

  Future<void> guardarUsuario({
    int? id,
    required String nombre,
    required String username,
    String? correo,
    String? password, // Solo si es nuevo o quiere cambiar
    String? rol,
    String? fotoRuta,
  }) async {
    final currentUser = _authService.currentUser;
    final isAdmin = currentUser?.rol == 'admin';

    // Validación de permisos
    if (!isAdmin && currentUser?.id != id) {
      throw Exception('No tienes permisos para editar otro usuario.');
    }

    if (id == null) {
      // CREAR (Solo Admin)
      if (!isAdmin) {
        throw Exception('Solo el administrador puede crear usuarios.');
      }
      if (password == null || password.length < 6) {
        throw Exception('Contraseña requerida (mínimo 6 caracteres).');
      }

      final usernameTaken = await _repository.usernameExists(username);
      if (usernameTaken) throw Exception('El usuario ya existe.');

      final hash = HashUtils.hashPassword(password);
      final newUser = Usuario(
        nombre: nombre.trim(),
        username: username.trim(),
        correo: correo?.trim(),
        passwordHash: hash,
        rol: rol ?? 'empleado',
        fotoRuta: fotoRuta,
      );
      await _repository.createUsuario(newUser);
    } else {
      // EDITAR
      final user = await obtenerUsuario(id);
      if (user == null) throw Exception('Usuario no encontrado.');

      String newHash = user.passwordHash;
      if (password != null && password.isNotEmpty) {
        if (password.length < 6) {
          throw Exception('La contraseña debe tener mínimo 6 caracteres.');
        }
        newHash = HashUtils.hashPassword(password);
      }

      final updatedUser = Usuario(
        id: id,
        nombre: isAdmin ? nombre.trim() : user.nombre,
        username: isAdmin ? username.trim() : user.username,
        correo: isAdmin ? correo?.trim() : user.correo,
        passwordHash: newHash,
        rol: isAdmin ? (rol ?? user.rol) : user.rol,
        fotoRuta: fotoRuta ?? user.fotoRuta,
        activo: user.activo,
        bloqueado: user.bloqueado,
        recoveryCode: user.recoveryCode,
      );

      await _repository.updateUsuario(updatedUser);
    }
  }

  Future<void> cambiarEstadoBloqueo(int id, bool bloqueado) async {
    final admin = _authService.currentUser;
    if (admin?.rol != 'admin') throw Exception('Solo admin.');
    if (admin?.id == id) {
      throw Exception('No puedes bloquearte a ti mismo.');
    }
    await _repository.updateBloqueo(
      id,
      bloqueado: bloqueado,
      adminId: admin?.id,
    );
  }

  Future<void> cambiarEstadoActivo(int id, bool activo) async {
    final admin = _authService.currentUser;
    if (admin?.rol != 'admin') throw Exception('Solo admin.');
    if (!activo && admin?.id == id) {
      throw Exception('No puedes darte de baja a ti mismo.');
    }
    await _repository.updateActivo(
      id,
      activo: activo,
      adminId: admin?.id,
    );
  }

  Future<void> darDeBaja(int id) async {
    await cambiarEstadoActivo(id, false);
  }

  Future<void> reactivarUsuario(int id) async {
    await cambiarEstadoActivo(id, true);
  }
}
