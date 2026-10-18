import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Arnés de pruebas en memoria con `sqflite_common_ffi` para la Fase 1 y posteriores.
class TestDbHarness {
  static bool _ffiInitialized = false;

  static Future<Database> openFreshInMemoryDb({
    bool seed = false,
    bool singleInstance = true,
  }) async {
    if (!_ffiInitialized) {
      sqfliteFfiInit();
      _ffiInitialized = true;
    }
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseHelper.databaseVersion,
        singleInstance: singleInstance,
      ),
    );
    await DatabaseHelper.instance.initializeTestSchema(db, seed: seed);
    DatabaseHelper.setTestDatabase(db);
    return db;
  }

  static Future<void> closeDb(Database db) async {
    DatabaseHelper.setTestDatabase(null);
    await db.close();
  }
}
