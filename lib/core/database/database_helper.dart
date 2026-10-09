import 'dart:convert';
import 'dart:math';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'db_seeder.dart';
import 'db_schema.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  final _secureStorage = const FlutterSecureStorage();
  final String _keySecureStorage = 'db_encryption_key';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pizzaapp_secure.db');
    return _database!;
  }

  Future<String> _getEncryptionKey() async {
    String? key = await _secureStorage.read(key: _keySecureStorage);
    if (key == null) {
      // Generar una clave segura aleatoria de 32 bytes (256 bits)
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      key = base64UrlEncode(values);
      await _secureStorage.write(key: _keySecureStorage, value: key);
    }
    return key;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Obtener la clave de encriptaciÃ³n del almacenamiento seguro
    final password = await _getEncryptionKey();

    final database = await openDatabase(
      path,
      version: 10,
      password: password,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE VariantesProducto ADD COLUMN imagen TEXT');
          } catch (e) {}
        }
        if (oldVersion < 3) {
          await db.execute('CREATE TABLE CategoriasInsumo (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL)');
          await db.insert('CategoriasInsumo', {'nombre': 'ingrediente'});
          await db.insert('CategoriasInsumo', {'nombre': 'empaque'});
        }
        if (oldVersion < 10) {
          try { await db.execute('ALTER TABLE VariantesProducto ADD COLUMN imagen TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE VariantesProducto ADD COLUMN stock INTEGER DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN condicion TEXT DEFAULT "Comprado"'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN metodo_pago TEXT DEFAULT "Contado"'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN cuotas INTEGER DEFAULT 1'); } catch (_) {}
          try { await db.execute('ALTER TABLE ActivosFijos ADD COLUMN cantidad INTEGER DEFAULT 1'); } catch (_) {}
          try { await db.execute('ALTER TABLE Mermas ADD COLUMN variante_id INTEGER'); } catch (_) {}
          try { await db.execute('ALTER TABLE CuentasPorPagar ADD COLUMN monto_pagado REAL DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE CuentasPorPagar ADD COLUMN cuotas INTEGER DEFAULT 1'); } catch (_) {}
          try { await db.execute('ALTER TABLE CuentasPorPagar ADD COLUMN adelanto REAL DEFAULT 0'); } catch (_) {}
          
          await db.execute('CREATE TABLE IF NOT EXISTS CategoriasActivo (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL)');
          try {
            await db.insert('CategoriasActivo', {'nombre': 'Maquinaria'});
            await db.insert('CategoriasActivo', {'nombre': 'Muebles'});
            await db.insert('CategoriasActivo', {'nombre': 'Tecnología'});
            await db.insert('CategoriasActivo', {'nombre': 'Otros'});
          } catch (_) {}
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS CuentasPorPagar (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fecha TEXT NOT NULL,
              insumo_id INTEGER NOT NULL,
              cantidad REAL NOT NULL,
              costo_total REAL NOT NULL,
              proveedor TEXT,
              factura_ruta TEXT,
              motivo TEXT,
              pagado INTEGER DEFAULT 0,
              monto_pagado REAL DEFAULT 0,
              fecha_pago TEXT,
              usuario_id INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS PreparacionDiaria (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fecha TEXT NOT NULL,
              usuario_id INTEGER,
              nota TEXT,
              created_at TEXT DEFAULT (datetime('now'))
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ItemsPreparacion (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              preparacion_id INTEGER NOT NULL,
              variante_id INTEGER NOT NULL,
              cantidad_preparada INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ActivosFijos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nombre TEXT NOT NULL,
              categoria TEXT,
              costo REAL DEFAULT 0,
              fecha_adquisicion TEXT,
              estado TEXT DEFAULT 'Bueno',
              observaciones TEXT,
              foto_ruta TEXT,
              activo INTEGER DEFAULT 1
            )
          ''');
        }
      },
    );



    
    // --- HACKY AUTO-PATCH PARA HOT RESTART ---
    for (final patch in DbSchema.hotRestartPatches) {
      try {
        await database.execute(patch);
      } catch (_) {}
    }

    // Seed datos predefinidos (idempotente)
    final seeder = DbSeeder(database);
    await seeder.seedAll();
    
    return database;

  }

  Future _createDB(Database db, int version) async {
    for (final table in DbSchema.initialTables) {
      await db.execute(table);
    }

    // Insertar datos de configuraciÃƒÂ³n por defecto
    await db.insert('Configuracion', {'clave': 'moneda', 'valor': 'PEN'});
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}












