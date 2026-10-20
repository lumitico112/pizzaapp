import 'dart:convert';
import 'dart:math';

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'db_seeder.dart';
import 'db_schema.dart';

/// Acceso a la base cifrada (SQLCipher) y PRAGMAs vigentes de la conexión:
/// - `foreign_keys = ON`: integridad referencial activa desde la v23 (C-07);
///   todos los caminos de apertura (`_initDB.onOpen` e `initializeTestSchema`)
///   la habilitan.
/// - `busy_timeout = 5000`: ante un bloqueo de escritura de otra conexión,
///   se espera hasta 5 segundos antes de reportar `SQLITE_BUSY` (H-13).
/// - `journal_mode`: el valor por defecto del motor (delete en archivo,
///   memory en pruebas). WAL NO se habilita: interactúa con el respaldo
///   portátil `.kpzbackup` y la decisión F14 lo mantiene deshabilitado.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static const int databaseVersion = 27;
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
    final password = await _getEncryptionKey();

    final database = await openDatabase(
      path,
      version: databaseVersion,
      password: password,
      onCreate: (db, version) async {
        await _createDB(db, version, runSeeder: true);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await upgradeDatabase(db, oldVersion, newVersion, runSeeder: true);
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        // PRAGMA busy_timeout = 5000 retorna una fila con el timeout. En Android (SQLCipher),
        // db.execute() lanza "Queries can be performed using SQLiteDatabase query or rawQuery methods only".
        // Por eso se debe invocar con rawQuery.
        await db.rawQuery('PRAGMA busy_timeout = 5000');
      },
    );

    return database;
  }

  /// Permite inyectar una base de datos en memoria (`sqflite_common_ffi`) en pruebas.
  static void setTestDatabase(Database? db) {
    _database = db;
  }

  /// Inicializa el esquema completo v27 con triggers, índices y los PRAGMAs
  /// de conexión (`foreign_keys = ON`, `busy_timeout = 5000`).
  Future<void> initializeTestSchema(
    Database database, {
    bool seed = false,
  }) async {
    await _createDB(database, databaseVersion, runSeeder: seed);
    await database.execute('PRAGMA foreign_keys = ON');
    await database.rawQuery('PRAGMA busy_timeout = 5000');
  }

  /// Ejecuta las migraciones lineales de versión (`oldVersion` -> `newVersion`).
  Future<void> upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion, {
    bool runSeeder = false,
  }) async {
    if (oldVersion < 2) {
      await _ensureColumn(db, 'VariantesProducto', 'imagen', 'TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS CategoriasInsumo (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL)',
      );
      await db.insert('CategoriasInsumo', {'nombre': 'ingrediente'});
      await db.insert('CategoriasInsumo', {'nombre': 'empaque'});
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS CuentasPorPagar (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha TEXT NOT NULL,
          insumo_id INTEGER REFERENCES Insumos(id),
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
    if (oldVersion < 10) {
      await _ensureColumn(db, 'VariantesProducto', 'imagen', 'TEXT');
      await _ensureColumn(
        db,
        'VariantesProducto',
        'stock',
        'INTEGER DEFAULT 0',
      );
      await _ensureColumn(
        db,
        'ActivosFijos',
        'condicion',
        'TEXT DEFAULT "Comprado"',
      );
      await _ensureColumn(
        db,
        'ActivosFijos',
        'metodo_pago',
        'TEXT DEFAULT "Contado"',
      );
      await _ensureColumn(
        db,
        'ActivosFijos',
        'cuotas',
        'INTEGER DEFAULT 1',
      );
      await _ensureColumn(
        db,
        'ActivosFijos',
        'cantidad',
        'INTEGER DEFAULT 1',
      );
      await _ensureColumn(db, 'Merma', 'variante_id', 'INTEGER');
      await _ensureColumn(
        db,
        'CuentasPorPagar',
        'monto_pagado',
        'REAL DEFAULT 0',
      );
      await _ensureColumn(
        db,
        'CuentasPorPagar',
        'cuotas',
        'INTEGER DEFAULT 1',
      );
      await _ensureColumn(
        db,
        'CuentasPorPagar',
        'adelanto',
        'REAL DEFAULT 0',
      );
      await db.execute(DbSchema.createCategoriasActivo);
    }
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE AjustesStock_nuevo (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha TEXT NOT NULL,
          insumo_id INTEGER NOT NULL REFERENCES Insumos(id),
          cantidad_ajuste REAL NOT NULL,
          tipo_adquisicion TEXT CHECK(tipo_adquisicion IN (
            'comprado','regalado','alquilado','merma','ajuste',
            'consumo','reversion_consumo'
          )),
          costo_unitario REAL DEFAULT 0,
          motivo TEXT,
          usuario_id INTEGER REFERENCES Usuarios(id)
        )
      ''');
      await db.execute('''
        INSERT INTO AjustesStock_nuevo
          (id, fecha, insumo_id, cantidad_ajuste, tipo_adquisicion,
           costo_unitario, motivo, usuario_id)
        SELECT id, fecha, insumo_id, cantidad_ajuste, tipo_adquisicion,
               costo_unitario, motivo, usuario_id
        FROM AjustesStock
      ''');
      await db.execute('DROP TABLE AjustesStock');
      await db.execute(
        'ALTER TABLE AjustesStock_nuevo RENAME TO AjustesStock',
      );
    }
    if (oldVersion < 12) {
      await _ensureColumn(
        db,
        'Gastos',
        'activo_fijo_id',
        'INTEGER REFERENCES ActivosFijos(id)',
      );
      await _ensureColumn(
        db,
        'CuentasPorPagar',
        'activo_fijo_id',
        'INTEGER REFERENCES ActivosFijos(id)',
      );
      await _ensureColumn(
        db,
        'CuentasPorPagar',
        'fecha_vencimiento',
        'TEXT',
      );
      await db.execute('''
        UPDATE Gastos
        SET activo_fijo_id = activo_id
        WHERE activo_fijo_id IS NULL
          AND activo_id IS NOT NULL
          AND categoria = 'Activos Fijos'
          AND EXISTS (SELECT 1 FROM ActivosFijos a WHERE a.id = Gastos.activo_id)
      ''');
      await db.execute(DbSchema.createPagosCuentaPorPagar);
      await db.execute('''
        UPDATE CuentasPorPagar
        SET monto_pagado = costo_total
        WHERE pagado = 1 AND COALESCE(monto_pagado, 0) = 0
      ''');
      await db.execute('''
        INSERT INTO PagosCuentaPorPagar
          (cuenta_id, fecha, monto, metodo_pago, nota, legado)
        SELECT id, COALESCE(fecha_pago, fecha), monto_pagado,
               'otro', 'Saldo previo al historial de pagos', 1
        FROM CuentasPorPagar
        WHERE COALESCE(monto_pagado, 0) > 0
      ''');
    }
    if (oldVersion < 13) {
      await _ensureColumn(
        db,
        'SesionesCaja',
        'transferencias_contadas',
        'REAL NOT NULL DEFAULT 0',
      );
      await _ensureColumn(
        db,
        'SesionesCaja',
        'diferencia_efectivo',
        'REAL NOT NULL DEFAULT 0',
      );
      await _ensureColumn(
        db,
        'SesionesCaja',
        'diferencia_transferencia',
        'REAL NOT NULL DEFAULT 0',
      );
      await _ensureColumn(
        db,
        'SesionesCaja',
        'total_esperado',
        'REAL NOT NULL DEFAULT 0',
      );
      await _ensureColumn(
        db,
        'SesionesCaja',
        'usuario_apertura_id',
        'INTEGER REFERENCES Usuarios(id)',
      );
      await _ensureColumn(
        db,
        'SesionesCaja',
        'usuario_cierre_id',
        'INTEGER REFERENCES Usuarios(id)',
      );
    }
    if (oldVersion < 14) {
      for (final column in const {
        'descripcion': 'TEXT',
        'precio': 'REAL NOT NULL DEFAULT 0',
        'dias_semana': 'TEXT',
        'hora_inicio': 'TEXT',
        'hora_fin': 'TEXT',
      }.entries) {
        await _ensureColumn(db, 'Promociones', column.key, column.value);
      }
      await db.execute(DbSchema.createPromocionItems);
      await _ensureColumn(
        db,
        'PromocionItems',
        'cantidad',
        'INTEGER NOT NULL DEFAULT 1',
      );
      await _ensureColumn(
        db,
        'PromocionItems',
        'insumo_id',
        'INTEGER REFERENCES Insumos(id)',
      );
      final legacyPromoTable = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'PromocionVariantes'",
      );
      if (legacyPromoTable.isNotEmpty) {
        await db.execute('''
          INSERT OR IGNORE INTO PromocionItems (promocion_id, variante_id, cantidad)
          SELECT promo_id, variante_id, 1 FROM PromocionVariantes
          WHERE promo_id IS NOT NULL AND variante_id IS NOT NULL
        ''');
      }
      await _ensureColumn(
        db,
        'DetalleVenta',
        'es_cortesia',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _ensureColumn(
        db,
        'Productos',
        'bebida_cortesia_insumo_id',
        'INTEGER REFERENCES Insumos(id)',
      );
      await _ensureColumn(
        db,
        'Productos',
        'bebida_cortesia_cantidad',
        'REAL NOT NULL DEFAULT 1',
      );
      final detailInfo = await db.rawQuery('PRAGMA table_info(DetalleVenta)');
      final variantColumns = detailInfo
          .where((c) => c['name'] == 'variante_id')
          .toList();
      final variantColumn = variantColumns.isEmpty
          ? null
          : variantColumns.first;
      if (variantColumn != null &&
          (variantColumn['notnull'] as int? ?? 0) == 1) {
        await db.execute('''
          CREATE TABLE DetalleVenta_nuevo (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            venta_id INTEGER NOT NULL REFERENCES Ventas(id),
            variante_id INTEGER REFERENCES VariantesProducto(id),
            promocion_id INTEGER,
            es_cortesia INTEGER NOT NULL DEFAULT 0,
            cantidad INTEGER NOT NULL,
            precio_unitario REAL NOT NULL,
            descuento REAL DEFAULT 0
          )
        ''');
        await db.execute('''
          INSERT INTO DetalleVenta_nuevo
            (id, venta_id, variante_id, promocion_id, es_cortesia, cantidad, precio_unitario, descuento)
          SELECT id, venta_id, variante_id, promocion_id, 0, cantidad, precio_unitario, descuento
          FROM DetalleVenta
        ''');
        await db.execute('DROP TABLE DetalleVenta');
        await db.execute(
          'ALTER TABLE DetalleVenta_nuevo RENAME TO DetalleVenta',
        );
      }
    }
    if (oldVersion < 15) {
      await _ensureColumn(
        db,
        'MovimientosCaja',
        'venta_id',
        'INTEGER REFERENCES Ventas(id)',
      );
      await _ensureColumn(
        db,
        'MovimientosCaja',
        'compra_movimiento_id',
        'INTEGER REFERENCES AjustesStock(id)',
      );
      await _ensureColumn(
        db,
        'Gastos',
        'compra_movimiento_id',
        'INTEGER REFERENCES AjustesStock(id)',
      );
      await _ensureColumn(
        db,
        'CuentasPorPagar',
        'compra_movimiento_id',
        'INTEGER REFERENCES AjustesStock(id)',
      );
      await _ensureColumn(
        db,
        'Transformaciones',
        'rendimiento',
        'REAL NOT NULL DEFAULT 1',
      );
      await _ensureColumn(db, 'Transformaciones', 'unidad_insumo', 'TEXT');
      await _ensureColumn(
        db,
        'Transformaciones',
        'activa',
        'INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute(DbSchema.createTransformacionInsumos);
      await db.execute(DbSchema.createMovimientosStockPreparado);
      await db.execute('''
        INSERT INTO MovimientosStockPreparado (fecha, variante_id, cantidad, tipo, motivo)
        SELECT datetime('now'), vp.id, vp.stock, 'saldo_inicial', 'Saldo existente al habilitar historial de inventario preparado'
        FROM VariantesProducto vp
        WHERE COALESCE(vp.stock, 0) <> 0
          AND NOT EXISTS (
            SELECT 1 FROM MovimientosStockPreparado m
            WHERE m.variante_id = vp.id AND m.tipo = 'saldo_inicial'
          )
      ''');
    }
    if (oldVersion < 16) {
      await _ensureColumn(
        db,
        'VariantesProducto',
        'active',
        'INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (oldVersion < 17) {
      await db.execute(DbSchema.createCorreccionesCompra);
    }
    if (oldVersion < 18) {
      await _ensureColumn(
        db,
        'SesionesCaja',
        'transferencias_apertura',
        'REAL NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 19) {
      await _ensureColumn(
        db,
        'Gastos',
        'sesion_caja_id',
        'INTEGER REFERENCES SesionesCaja(id)',
      );
    }
    if (oldVersion < 20) {
      await _ensureColumn(
        db,
        'SesionesCaja',
        'total_gastos_ciclo',
        'REAL NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 21) {
      await _ensureColumn(
        db,
        'Productos',
        'deriva_de_producto_id',
        'INTEGER REFERENCES Productos(id)',
      );
      await _ensureColumn(
        db,
        'VariantesProducto',
        'variante_base_id',
        'INTEGER REFERENCES VariantesProducto(id)',
      );
      await _ensureColumn(
        db,
        'AjustesStock',
        'proveedor_id',
        'INTEGER REFERENCES Proveedores(id)',
      );
      await _ensureColumn(
        db,
        'CuentasPorPagar',
        'proveedor_id',
        'INTEGER REFERENCES Proveedores(id)',
      );
    }
    if (oldVersion < 22) {
      await _ensureColumn(db, 'Gastos', 'created_at', 'TEXT');
      await db.execute('''
        UPDATE Gastos
        SET created_at = COALESCE(
          (SELECT m.fecha FROM MovimientosCaja m
           WHERE Gastos.compra_movimiento_id IS NOT NULL
             AND m.compra_movimiento_id = Gastos.compra_movimiento_id
           ORDER BY m.id DESC LIMIT 1),
          (SELECT m.fecha FROM MovimientosCaja m
           WHERE Gastos.sesion_caja_id IS NOT NULL
             AND m.sesion_caja_id = Gastos.sesion_caja_id
             AND m.tipo IN ('salida', 'compra')
             AND ABS(m.monto - Gastos.monto) < 0.011
           ORDER BY m.id DESC LIMIT 1),
          (SELECT p.fecha FROM PagosCuentaPorPagar p
           WHERE p.gasto_id = Gastos.id
           ORDER BY p.id DESC LIMIT 1),
          substr(Gastos.fecha, 1, 10) || 'T00:00:00'
        )
        WHERE created_at IS NULL OR created_at = ''
      ''');
    }
    if (oldVersion < 23) {
      await _migrateToV23(db);
    }
    if (oldVersion < 24) {
      // H-05: vínculo explícito Gasto -> MovimientoCaja para eliminar salidas
      // manuales de caja por ID exacto (sin heurística difusa monto/fecha).
      await _ensureColumn(
        db,
        'Gastos',
        'movimiento_caja_id',
        'INTEGER REFERENCES MovimientosCaja(id)',
      );
    }
    if (oldVersion < 25) {
      // H-03: demanda no satisfecha por falta de stock preparado. La tabla se
      // alimenta desde ventas fallidas y la consume SugerenciasAlgoritmo.
      await db.execute(DbSchema.createFaltantesPreparacion);
      await db.execute(DbSchema.indexFaltantesPreparacion);
    }
    if (oldVersion < 26) {
      // Fase 2: identificar ventas retroactivas y vincular el consumo de
      // insumos con la venta exacta para poder revertirlo sin heurísticas.
      await _ensureColumn(
        db,
        'Ventas',
        'es_historica',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('''
        UPDATE Ventas
        SET es_historica = 1
        WHERE COALESCE(es_historica, 0) = 0
          AND COALESCE(nota, '') LIKE '%REGISTRO HIST%'
      ''');
      await _ensureColumn(
        db,
        'AjustesStock',
        'venta_id',
        'INTEGER REFERENCES Ventas(id)',
      );
      for (final index in DbSchema.indexesV26) {
        await db.execute(index);
      }
    }
    if (oldVersion < 27 && newVersion >= 27) {
      // Fase 3: compras ocasionales sin inventario. La cabecera se crea antes
      // que las columnas de vínculo para que las FK queden satisfechas.
      await db.execute(DbSchema.createComprasOcasionales);
      await _ensureColumn(
        db,
        'Gastos',
        'compra_ocasional_id',
        'INTEGER REFERENCES ComprasOcasionales(id)',
      );
      await _ensureColumn(
        db,
        'CuentasPorPagar',
        'compra_ocasional_id',
        'INTEGER REFERENCES ComprasOcasionales(id)',
      );
      for (final index in DbSchema.indexesV27) {
        await db.execute(index);
      }
    }

    if (runSeeder) {
      final seeder = DbSeeder(db);
      await seeder.seedAll();
    }
  }

  /// Migración consolidada v23 (C-06, C-07, C-08, C-09, C-12, C-13):
  /// - Garantiza todas las tablas y columnas que antes dependían de `hotRestartPatches`
  /// - Migra `CuentasPorPagar.insumo_id` a `INTEGER NULL` para activos fijos a crédito
  /// - Sanea referencias foráneas huérfanas para habilitar `PRAGMA foreign_keys = ON`
  /// - Registra triggers de validación y los índices `IDX_*`
  Future<void> _migrateToV23(Database db) async {
    for (final tableSql in [
      DbSchema.createProveedores,
      DbSchema.createCategoriasActivo,
      DbSchema.createPromocionItems,
      DbSchema.createSesionesCaja,
      DbSchema.createMovimientosCaja,
      DbSchema.createCuentasPorPagarV23,
      DbSchema.createPagosCuentaPorPagar,
      DbSchema.createPreparacionDiaria,
      DbSchema.createItemsPreparacion,
      DbSchema.createTransformaciones,
      DbSchema.createTransformacionInsumos,
      DbSchema.createMovimientosStockPreparado,
      DbSchema.createCorreccionesCompra,
      DbSchema.createRecetas,
      DbSchema.createActivosFijos,
      DbSchema.createFaltantesPreparacion,
    ]) {
      final safeSql = tableSql.replaceFirst(
        RegExp(r'CREATE\s+TABLE\s+(?!IF\s+NOT\s+EXISTS)', caseSensitive: false),
        'CREATE TABLE IF NOT EXISTS ',
      );
      await db.execute(safeSql);
    }

    await _ensureColumn(db, 'Insumos', 'contenido_paquete', 'INTEGER DEFAULT 1');
    await _ensureColumn(db, 'DetalleVenta', 'promocion_id', 'INTEGER');
    await _ensureColumn(db, 'VariantesProducto', 'imagen', 'TEXT');
    await _ensureColumn(db, 'VariantesProducto', 'stock', 'INTEGER DEFAULT 0');
    await _ensureColumn(
      db,
      'VariantesProducto',
      'active',
      'INTEGER NOT NULL DEFAULT 1',
    );
    await _ensureColumn(
      db,
      'VariantesProducto',
      'variante_base_id',
      'INTEGER REFERENCES VariantesProducto(id)',
    );
    await _ensureColumn(
      db,
      'Productos',
      'deriva_de_producto_id',
      'INTEGER REFERENCES Productos(id)',
    );
    await _ensureColumn(
      db,
      'ActivosFijos',
      'condicion',
      'TEXT DEFAULT "Comprado"',
    );
    await _ensureColumn(
      db,
      'ActivosFijos',
      'metodo_pago',
      'TEXT DEFAULT "Contado"',
    );
    await _ensureColumn(db, 'ActivosFijos', 'cuotas', 'INTEGER DEFAULT 1');
    await _ensureColumn(db, 'ActivosFijos', 'cantidad', 'INTEGER DEFAULT 1');
    await _ensureColumn(db, 'ActivosFijos', 'frecuencia_alquiler', 'TEXT');
    await _ensureColumn(db, 'Merma', 'variante_id', 'INTEGER');
    await _ensureColumn(db, 'Usuarios', 'correo', 'TEXT');
    await _ensureColumn(db, 'Usuarios', 'bloqueado', 'INTEGER DEFAULT 0');
    await _ensureColumn(db, 'Usuarios', 'recovery_code', 'TEXT');
    await _ensureColumn(db, 'ItemsPreparacion', 'notas', 'TEXT');
    await _ensureColumn(
      db,
      'ItemsPreparacion',
      'sobrante',
      'INTEGER DEFAULT 0',
    );
    await _ensureColumn(
      db,
      'ItemsPreparacion',
      'enviado_merma',
      'INTEGER DEFAULT 0',
    );
    await _ensureColumn(
      db,
      'ItemsPreparacion',
      'llevado_manana',
      'INTEGER DEFAULT 0',
    );
    await _ensureColumn(
      db,
      'ItemsPreparacion',
      'resuelto',
      'INTEGER DEFAULT 0',
    );
    await _ensureColumn(
      db,
      'Transformaciones',
      'rendimiento',
      'REAL NOT NULL DEFAULT 1',
    );
    await _ensureColumn(db, 'Transformaciones', 'unidad_insumo', 'TEXT');
    await _ensureColumn(
      db,
      'Transformaciones',
      'activa',
      'INTEGER NOT NULL DEFAULT 1',
    );
    await _ensureColumn(
      db,
      'MovimientosCaja',
      'venta_id',
      'INTEGER REFERENCES Ventas(id)',
    );
    await _ensureColumn(
      db,
      'MovimientosCaja',
      'compra_movimiento_id',
      'INTEGER REFERENCES AjustesStock(id)',
    );
    await _ensureColumn(
      db,
      'Gastos',
      'activo_fijo_id',
      'INTEGER REFERENCES ActivosFijos(id)',
    );
    await _ensureColumn(
      db,
      'Gastos',
      'compra_movimiento_id',
      'INTEGER REFERENCES AjustesStock(id)',
    );
    await _ensureColumn(
      db,
      'Gastos',
      'sesion_caja_id',
      'INTEGER REFERENCES SesionesCaja(id)',
    );
    await _ensureColumn(db, 'Gastos', 'created_at', 'TEXT');
    await _ensureColumn(
      db,
      'SesionesCaja',
      'transferencias_apertura',
      'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      'SesionesCaja',
      'total_gastos_ciclo',
      'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      'SesionesCaja',
      'transferencias_contadas',
      'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      'SesionesCaja',
      'diferencia_efectivo',
      'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      'SesionesCaja',
      'diferencia_transferencia',
      'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      'SesionesCaja',
      'total_esperado',
      'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      'SesionesCaja',
      'usuario_apertura_id',
      'INTEGER REFERENCES Usuarios(id)',
    );
    await _ensureColumn(
      db,
      'SesionesCaja',
      'usuario_cierre_id',
      'INTEGER REFERENCES Usuarios(id)',
    );
    await _ensureColumn(
      db,
      'AjustesStock',
      'proveedor_id',
      'INTEGER REFERENCES Proveedores(id)',
    );
    await _ensureColumn(
      db,
      'CuentasPorPagar',
      'monto_pagado',
      'REAL DEFAULT 0',
    );
    await _ensureColumn(db, 'CuentasPorPagar', 'cuotas', 'INTEGER DEFAULT 1');
    await _ensureColumn(db, 'CuentasPorPagar', 'adelanto', 'REAL DEFAULT 0');
    await _ensureColumn(
      db,
      'CuentasPorPagar',
      'activo_fijo_id',
      'INTEGER REFERENCES ActivosFijos(id)',
    );
    await _ensureColumn(db, 'CuentasPorPagar', 'fecha_vencimiento', 'TEXT');
    await _ensureColumn(
      db,
      'CuentasPorPagar',
      'compra_movimiento_id',
      'INTEGER REFERENCES AjustesStock(id)',
    );
    await _ensureColumn(
      db,
      'CuentasPorPagar',
      'proveedor_id',
      'INTEGER REFERENCES Proveedores(id)',
    );

    // Reconstruir CuentasPorPagar si insumo_id tenía NOT NULL (C-09)
    final cxpInfo = await db.rawQuery('PRAGMA table_info(CuentasPorPagar)');
    final insumoCol = cxpInfo.where((c) => c['name'] == 'insumo_id').toList();
    if (insumoCol.isNotEmpty &&
        (insumoCol.first['notnull'] as int? ?? 0) == 1) {
      await db.execute('DROP TRIGGER IF EXISTS validar_cuenta_por_pagar_insert');
      await db.execute('DROP TRIGGER IF EXISTS validar_cuenta_por_pagar_update');
      await db.execute('''
        CREATE TABLE CuentasPorPagar_nuevo (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha TEXT NOT NULL,
          insumo_id INTEGER REFERENCES Insumos(id),
          cantidad REAL NOT NULL,
          costo_total REAL NOT NULL,
          proveedor TEXT,
          proveedor_id INTEGER REFERENCES Proveedores(id),
          factura_ruta TEXT,
          motivo TEXT,
          pagado INTEGER DEFAULT 0,
          monto_pagado REAL NOT NULL DEFAULT 0 CHECK(monto_pagado >= 0),
          fecha_pago TEXT,
          usuario_id INTEGER REFERENCES Usuarios(id),
          cuotas INTEGER DEFAULT 1,
          adelanto REAL DEFAULT 0,
          activo_fijo_id INTEGER REFERENCES ActivosFijos(id),
          fecha_vencimiento TEXT,
          compra_movimiento_id INTEGER REFERENCES AjustesStock(id)
        )
      ''');
      await db.execute('''
        INSERT INTO CuentasPorPagar_nuevo (
          id, fecha, insumo_id, cantidad, costo_total, proveedor, proveedor_id,
          factura_ruta, motivo, pagado, monto_pagado, fecha_pago, usuario_id,
          cuotas, adelanto, activo_fijo_id, fecha_vencimiento, compra_movimiento_id
        )
        SELECT
          id, fecha,
          CASE WHEN insumo_id IS NULL OR insumo_id <= 0 THEN NULL ELSE insumo_id END,
          CASE WHEN COALESCE(cantidad, 0) <= 0 THEN 1 ELSE cantidad END,
          CASE WHEN COALESCE(costo_total, 0) <= 0 THEN 0.01 ELSE costo_total END,
          proveedor, proveedor_id, factura_ruta, motivo,
          COALESCE(pagado, 0),
          MAX(0, COALESCE(monto_pagado, 0)),
          fecha_pago, usuario_id,
          CASE WHEN COALESCE(cuotas, 0) < 1 THEN 1 ELSE cuotas END,
          COALESCE(adelanto, 0),
          activo_fijo_id, fecha_vencimiento, compra_movimiento_id
        FROM CuentasPorPagar
      ''');
      await db.execute('DROP TABLE CuentasPorPagar');
      await db.execute(
        'ALTER TABLE CuentasPorPagar_nuevo RENAME TO CuentasPorPagar',
      );
    }

    await db.execute(
      'UPDATE Insumos SET stock_actual = 0.0 WHERE stock_actual IS NULL',
    );
    await db.execute(
      'UPDATE Insumos SET costo_por_unidad = 0.0 WHERE costo_por_unidad IS NULL',
    );

    await cleanOrphanForeignKeys(db);

    for (final trigger in DbSchema.triggers) {
      await db.execute(trigger);
    }
    for (final index in DbSchema.indexes) {
      await db.execute(index);
    }
  }

  /// Limpia referencias foráneas huérfanas para garantizar que `PRAGMA foreign_key_check` devuelva 0 filas.
  Future<void> cleanOrphanForeignKeys(DatabaseExecutor db) async {
    // 1. Convertir centinela insumo_id <= 0 a NULL en CuentasPorPagar
    await db.execute(
      'UPDATE CuentasPorPagar SET insumo_id = NULL WHERE insumo_id IS NOT NULL AND insumo_id <= 0',
    );

    // 2. Poner en NULL columnas FK anulables cuyo padre no exista
    const nullableFkCleanup = <List<String>>[
      ['Productos', 'categoria_id', 'Categorias'],
      ['Productos', 'bebida_cortesia_insumo_id', 'Insumos'],
      ['Productos', 'deriva_de_producto_id', 'Productos'],
      ['VariantesProducto', 'empaque_insumo_id', 'Insumos'],
      ['VariantesProducto', 'variante_base_id', 'VariantesProducto'],
      ['PromocionItems', 'variante_id', 'VariantesProducto'],
      ['PromocionItems', 'insumo_id', 'Insumos'],
      ['Ventas', 'usuario_id', 'Usuarios'],
      ['Ventas', 'promocion_id', 'Promociones'],
      ['DetalleVenta', 'variante_id', 'VariantesProducto'],
      ['Gastos', 'insumo_id', 'Insumos'],
      ['Gastos', 'activo_id', 'Activos'],
      ['Gastos', 'activo_fijo_id', 'ActivosFijos'],
      ['Gastos', 'compra_movimiento_id', 'AjustesStock'],
      ['Gastos', 'usuario_id', 'Usuarios'],
      ['Gastos', 'sesion_caja_id', 'SesionesCaja'],
      ['Gastos', 'movimiento_caja_id', 'MovimientosCaja'],
      ['AjustesStock', 'proveedor_id', 'Proveedores'],
      ['AjustesStock', 'venta_id', 'Ventas'],
      ['AjustesStock', 'usuario_id', 'Usuarios'],
      ['Merma', 'usuario_id', 'Usuarios'],
      ['Merma', 'insumo_id', 'Insumos'],
      ['Merma', 'variante_id', 'VariantesProducto'],
      ['CierreCaja', 'usuario_id', 'Usuarios'],
      ['SesionesCaja', 'usuario_apertura_id', 'Usuarios'],
      ['SesionesCaja', 'usuario_cierre_id', 'Usuarios'],
      ['MovimientosCaja', 'venta_id', 'Ventas'],
      ['MovimientosCaja', 'compra_movimiento_id', 'AjustesStock'],
      ['NotasDia', 'usuario_id', 'Usuarios'],
      ['LogAuditoria', 'usuario_id', 'Usuarios'],
      ['CuentasPorPagar', 'insumo_id', 'Insumos'],
      ['CuentasPorPagar', 'proveedor_id', 'Proveedores'],
      ['CuentasPorPagar', 'usuario_id', 'Usuarios'],
      ['CuentasPorPagar', 'activo_fijo_id', 'ActivosFijos'],
      ['CuentasPorPagar', 'compra_movimiento_id', 'AjustesStock'],
      ['PagosCuentaPorPagar', 'usuario_id', 'Usuarios'],
      ['PagosCuentaPorPagar', 'sesion_caja_id', 'SesionesCaja'],
      ['PagosCuentaPorPagar', 'gasto_id', 'Gastos'],
      ['PagosCuentaPorPagar', 'movimiento_caja_id', 'MovimientosCaja'],
      ['PreparacionDiaria', 'usuario_id', 'Usuarios'],
      ['Transformaciones', 'variante_origen_id', 'VariantesProducto'],
      ['Transformaciones', 'variante_destino_id', 'VariantesProducto'],
      ['Transformaciones', 'insumo_adicional_id', 'Insumos'],
      ['MovimientosStockPreparado', 'usuario_id', 'Usuarios'],
      ['CorreccionesCompra', 'ajuste_stock_id', 'AjustesStock'],
      ['CorreccionesCompra', 'usuario_id', 'Usuarios'],
    ];

    final columnsByTable = <String, Set<String>>{};
    for (final rule in nullableFkCleanup) {
      final table = rule[0];
      final column = rule[1];
      final parent = rule[2];
      final columns = columnsByTable[table] ??
          (await db.rawQuery('PRAGMA table_info($table)'))
              .map((info) => info['name'] as String)
              .toSet();
      columnsByTable[table] = columns;
      // Tolerante a columnas aún no migradas (p. ej. Gastos.movimiento_caja_id
      // se agrega en la v24, después de ejecutarse esta limpieza de la v23).
      if (!columns.contains(column)) continue;
      await db.execute('''
        UPDATE $table
        SET $column = NULL
        WHERE $column IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM $parent p WHERE p.id = $table.$column)
      ''');
    }

    // 3. Eliminar filas detalle huérfanas con FK NOT NULL hacia padres inexistentes
    const notNullFkCleanup = <List<String>>[
      ['DetalleVenta', 'venta_id', 'Ventas'],
      ['PromocionItems', 'promocion_id', 'Promociones'],
      ['PromocionVariantes', 'promo_id', 'Promociones'],
      ['PromocionVariantes', 'variante_id', 'VariantesProducto'],
      ['Recetas', 'variante_id', 'VariantesProducto'],
      ['Recetas', 'insumo_id', 'Insumos'],
      ['ConsumoEstimadoInsumo', 'variante_id', 'VariantesProducto'],
      ['ConsumoEstimadoInsumo', 'insumo_id', 'Insumos'],
      ['TransformacionInsumos', 'transformacion_id', 'Transformaciones'],
      ['TransformacionInsumos', 'insumo_id', 'Insumos'],
      ['PagosCuentaPorPagar', 'cuenta_id', 'CuentasPorPagar'],
      ['CorreccionesCompra', 'compra_movimiento_id', 'AjustesStock'],
      ['MovimientosStockPreparado', 'variante_id', 'VariantesProducto'],
      ['FaltantesPreparacion', 'variante_id', 'VariantesProducto'],
      ['AjustesStock', 'insumo_id', 'Insumos'],
      ['VariantesProducto', 'producto_id', 'Productos'],
      ['HistorialPreciosInsumo', 'insumo_id', 'Insumos'],
      ['HistorialPreciosVariante', 'variante_id', 'VariantesProducto'],
      ['ItemsPreparacion', 'preparacion_id', 'PreparacionDiaria'],
      ['ItemsPreparacion', 'variante_id', 'VariantesProducto'],
      ['MovimientosCaja', 'sesion_caja_id', 'SesionesCaja'],
    ];

    for (final rule in notNullFkCleanup) {
      final table = rule[0];
      final column = rule[1];
      final parent = rule[2];
      await db.execute('''
        DELETE FROM $table
        WHERE NOT EXISTS (SELECT 1 FROM $parent p WHERE p.id = $table.$column)
      ''');
    }
  }

  Future<void> _ensureColumn(
    Database database,
    String table,
    String column,
    String definition,
  ) async {
    final tableRows = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [table],
    );
    if (tableRows.isEmpty) return;

    final columns = await database.rawQuery('PRAGMA table_info($table)');
    if (columns.any((item) => item['name'] == column)) return;
    await database.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<void> _createDB(
    Database db,
    int version, {
    bool runSeeder = false,
  }) async {
    for (final table in DbSchema.initialTables) {
      await db.execute(table);
    }
    for (final trigger in DbSchema.triggers) {
      await db.execute(trigger);
    }
    for (final index in DbSchema.indexes) {
      await db.execute(index);
    }
    for (final index in DbSchema.indexesV26) {
      await db.execute(index);
    }
    for (final index in DbSchema.indexesV27) {
      await db.execute(index);
    }

    await db.insert('Configuracion', {'clave': 'moneda', 'valor': 'PEN'});

    if (runSeeder) {
      final seeder = DbSeeder(db);
      await seeder.seedAll();
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
