import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class ConfiguracionRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<void> saveConfig(
    String clave,
    String valor, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await dbHelper.database;
    await db.insert('Configuracion', {
      'clave': clave,
      'valor': valor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveConfigs(
    Map<String, String> values, {
    List<String> deleteKeys = const [],
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      for (final entry in values.entries) {
        await txn.insert('Configuracion', {
          'clave': entry.key,
          'valor': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final key in deleteKeys) {
        await txn.delete('Configuracion', where: 'clave = ?', whereArgs: [key]);
      }
    });
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

  /// Ejecuta `action` dentro de una transacción de la base de datos.
  Future<T> runTransaction<T>(
    Future<T> Function(DatabaseExecutor txn) action,
  ) async {
    final db = await dbHelper.database;
    return await db.transaction(action);
  }
}
