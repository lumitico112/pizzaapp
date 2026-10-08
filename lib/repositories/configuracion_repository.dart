import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class ConfiguracionRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<void> saveConfig(String clave, String valor) async {
    final db = await dbHelper.database;
    await db.insert(
      'Configuracion',
      {'clave': clave, 'valor': valor},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getConfig(String clave) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Configuracion',
      where: 'clave = ?',
      whereArgs: [clave],
    );

    if (maps.isNotEmpty) {
      return maps.first['valor'] as String;
    }
    return null;
  }
}
