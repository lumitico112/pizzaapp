import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/core/utils/hash_utils.dart';

class UsuarioRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<bool> adminExists() async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM Usuarios WHERE rol = 'admin'")
    );
    return (count ?? 0) > 0;
  }

  Future<int> createUsuario(Usuario usuario) async {
    final db = await dbHelper.database;
    return await db.insert('Usuarios', usuario.toMap());
  }

  Future<Usuario?> authenticate(String username, String password) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Usuarios',
      where: 'username = ? AND activo = 1',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      final usuario = Usuario.fromMap(maps.first);
      if (HashUtils.verifyPassword(password, usuario.passwordHash)) {
        return usuario;
      }
    }
    return null;
  }

  Future<List<Usuario>> getAllUsuarios() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('Usuarios', where: 'activo = 1');
    return maps.map((map) => Usuario.fromMap(map)).toList();
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
