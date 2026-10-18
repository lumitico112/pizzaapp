import 'package:pizzaapp/core/database/audit_log_writer.dart';
import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/repositories/usuario_repository.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';
import 'package:pizzaapp/services/auth_service.dart';

class UsuarioService {
  final UsuarioRepository _repository;
  final AuthService _authService;

  UsuarioService(this._repository, this._authService);

  Future<List<Usuario>> obtenerUsuarios({bool incluirInactivos = false}) async {
    final db = await _repository.dbHelper.database;
    final res = await db.query(
      'Usuarios',
      where: incluirInactivos ? null : 'activo = 1',
    );
    return res.map((e) => Usuario.fromMap(e)).toList();
  }

  Future<Usuario?> obtenerUsuario(int id) async {
    final db = await _repository.dbHelper.database;
    final res = await db.query('Usuarios', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return Usuario.fromMap(res.first);
    return null;
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

      final db = await _repository.dbHelper.database;
      final existing = await db.query(
        'Usuarios',
        where: 'username = ?',
        whereArgs: [username],
      );
      if (existing.isNotEmpty) throw Exception('El usuario ya existe.');

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

      final db = await _repository.dbHelper.database;
      await db.update(
        'Usuarios',
        updatedUser.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> cambiarEstadoBloqueo(int id, bool bloqueado) async {
    final admin = _authService.currentUser;
    if (admin?.rol != 'admin') throw Exception('Solo admin.');
    if (admin?.id == id) {
      throw Exception('No puedes bloquearte a ti mismo.');
    }
    final db = await _repository.dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        'Usuarios',
        {'bloqueado': bloqueado ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      await AuditLogWriter.record(
        txn,
        userId: admin?.id,
        action: bloqueado ? 'USUARIO_BLOQUEAR' : 'USUARIO_DESBLOQUEAR',
        detail: bloqueado
            ? 'Bloqueo temporal de usuario ID $id'
            : 'Desbloqueo de usuario ID $id',
      );
    });
  }

  Future<void> cambiarEstadoActivo(int id, bool activo) async {
    final admin = _authService.currentUser;
    if (admin?.rol != 'admin') throw Exception('Solo admin.');
    if (!activo && admin?.id == id) {
      throw Exception('No puedes darte de baja a ti mismo.');
    }
    final db = await _repository.dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        'Usuarios',
        {'activo': activo ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      await AuditLogWriter.record(
        txn,
        userId: admin?.id,
        action: activo ? 'USUARIO_REACTIVAR' : 'USUARIO_BAJA',
        detail: activo
            ? 'Reactivación de usuario ID $id'
            : 'Baja lógica de usuario ID $id',
      );
    });
  }

  Future<void> darDeBaja(int id) async {
    await cambiarEstadoActivo(id, false);
  }

  Future<void> reactivarUsuario(int id) async {
    await cambiarEstadoActivo(id, true);
  }
}
