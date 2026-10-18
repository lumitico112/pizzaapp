import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/core/database/audit_log_writer.dart';
import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' show DatabaseExecutor;

class UsuarioRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<bool> adminExists({DatabaseExecutor? executor}) async {
    final db = executor ?? await dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM Usuarios WHERE rol = 'admin'"),
    );
    return (count ?? 0) > 0;
  }

  Future<int> createUsuario(
    Usuario usuario, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await dbHelper.database;
    return await db.insert('Usuarios', usuario.toMap());
  }

  Future<List<Usuario>> getUsuarios({bool incluirInactivos = false}) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'Usuarios',
      where: incluirInactivos ? null : 'activo = 1',
    );
    return res.map((e) => Usuario.fromMap(e)).toList();
  }

  Future<Usuario?> getUsuario(int id) async {
    final db = await dbHelper.database;
    final res = await db.query('Usuarios', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return Usuario.fromMap(res.first);
    return null;
  }

  Future<bool> usernameExists(String username) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'Usuarios',
      where: 'username = ?',
      whereArgs: [username],
    );
    return res.isNotEmpty;
  }

  Future<void> updateUsuario(Usuario usuario) async {
    final db = await dbHelper.database;
    await db.update(
      'Usuarios',
      usuario.toMap(),
      where: 'id = ?',
      whereArgs: [usuario.id],
    );
  }

  Future<Usuario?> authenticate(String username, String password) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Usuarios',
      where: 'username = ? AND activo = 1 AND COALESCE(bloqueado, 0) = 0',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      final usuario = Usuario.fromMap(maps.first);
      if (HashUtils.verifyPassword(password, usuario.passwordHash)) {
        if (usuario.id != null && HashUtils.isLegacyHash(usuario.passwordHash)) {
          final upgradedHash = HashUtils.hashPassword(password);
          await db.update(
            'Usuarios',
            {'password_hash': upgradedHash},
            where: 'id = ?',
            whereArgs: [usuario.id],
          );
          return Usuario(
            id: usuario.id,
            nombre: usuario.nombre,
            username: usuario.username,
            correo: usuario.correo,
            passwordHash: upgradedHash,
            recoveryCode: usuario.recoveryCode,
            rol: usuario.rol,
            fotoRuta: usuario.fotoRuta,
            activo: usuario.activo,
            bloqueado: usuario.bloqueado,
            createdAt: usuario.createdAt,
          );
        }
        return usuario;
      }
    }
    return null;
  }

  Future<List<Usuario>> getAllUsuarios() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Usuarios',
      where: 'activo = 1',
    );
    return maps.map((map) => Usuario.fromMap(map)).toList();
  }

  Future<Usuario?> findActiveAdmin(String username) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'Usuarios',
      where: "username = ? AND rol = 'admin' AND activo = 1 AND bloqueado = 0",
      whereArgs: [username.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : Usuario.fromMap(rows.first);
  }

  Future<void> saveRecoveryCode(int userId, String codeHash) async {
    final db = await dbHelper.database;
    await db.update(
      'Usuarios',
      {'recovery_code': codeHash},
      where:
          "id = ? AND rol = 'admin' AND activo = 1 AND COALESCE(bloqueado, 0) = 0",
      whereArgs: [userId],
    );
  }

  Future<void> updateAdminPassword(int userId, String passwordHash) async {
    final db = await dbHelper.database;
    await db.update(
      'Usuarios',
      {'password_hash': passwordHash},
      where: "id = ? AND rol = 'admin' AND activo = 1 AND bloqueado = 0",
      whereArgs: [userId],
    );
  }

  /// Cambia el bloqueo y audita dentro de la MISMA transacción (RN-11).
  Future<void> updateBloqueo(
    int id, {
    required bool bloqueado,
    required int? adminId,
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        'Usuarios',
        {'bloqueado': bloqueado ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      await AuditLogWriter.record(
        txn,
        userId: adminId,
        action: bloqueado ? 'USUARIO_BLOQUEAR' : 'USUARIO_DESBLOQUEAR',
        detail: bloqueado
            ? 'Bloqueo temporal de usuario ID $id'
            : 'Desbloqueo de usuario ID $id',
      );
    });
  }

  /// Cambia el estado activo y audita dentro de la MISMA transacción (RN-11).
  Future<void> updateActivo(
    int id, {
    required bool activo,
    required int? adminId,
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        'Usuarios',
        {'activo': activo ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      await AuditLogWriter.record(
        txn,
        userId: adminId,
        action: activo ? 'USUARIO_REACTIVAR' : 'USUARIO_BAJA',
        detail: activo
            ? 'Reactivación de usuario ID $id'
            : 'Baja lógica de usuario ID $id',
      );
    });
  }
}

class Sqflite {
  static int? firstIntValue(List<Map<String, Object?>> list) {
    if (list.isNotEmpty) {
      final firstRow = list.first;
      if (firstRow.isNotEmpty) {
        return firstRow.values.first as int?;
      }
    }
    return null;
  }
}
