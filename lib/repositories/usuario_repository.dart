import 'package:pizzaapp/core/database/database_helper.dart';
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
