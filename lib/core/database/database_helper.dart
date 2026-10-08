import 'dart:convert';
import 'dart:math';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'db_seeder.dart';

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
    try { await database.execute('''
      CREATE TABLE IF NOT EXISTS Proveedores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        email TEXT,
        direccion TEXT,
        notas TEXT,
        activo INTEGER DEFAULT 1
      )
    '''); } catch (_) {}
    try { await database.execute('ALTER TABLE Insumos ADD COLUMN contenido_paquete INTEGER DEFAULT 1'); } catch (_) {}
    try { await database.execute('ALTER TABLE DetalleVenta ADD COLUMN promocion_id INTEGER'); } catch (_) {}
    try { await database.execute('CREATE TABLE IF NOT EXISTS CategoriasActivo (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL)'); } catch (_) {}
    try { await database.execute('ALTER TABLE VariantesProducto ADD COLUMN imagen TEXT'); } catch (_) {}
    try { await database.execute('ALTER TABLE VariantesProducto ADD COLUMN stock INTEGER DEFAULT 0'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN condicion TEXT DEFAULT "Comprado"'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN metodo_pago TEXT DEFAULT "Contado"'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN cuotas INTEGER DEFAULT 1'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN cantidad INTEGER DEFAULT 1'); } catch (_) {}
    try { await database.execute('ALTER TABLE Mermas ADD COLUMN variante_id INTEGER'); } catch (_) {}
    try { await database.execute('ALTER TABLE CuentasPorPagar ADD COLUMN monto_pagado REAL DEFAULT 0'); } catch (_) {}
    try { await database.execute('ALTER TABLE CuentasPorPagar ADD COLUMN cuotas INTEGER DEFAULT 1'); } catch (_) {}
    try { await database.execute('ALTER TABLE CuentasPorPagar ADD COLUMN adelanto REAL DEFAULT 0'); } catch (_) {}
    try { await database.execute('ALTER TABLE Usuarios ADD COLUMN correo TEXT'); } catch (_) {}
    try { await database.execute('ALTER TABLE Usuarios ADD COLUMN bloqueado INTEGER DEFAULT 0'); } catch (_) {}
    try { await database.execute('ALTER TABLE Usuarios ADD COLUMN recovery_code TEXT'); } catch (_) {}
    try { await database.execute('ALTER TABLE ActivosFijos ADD COLUMN frecuencia_alquiler TEXT'); } catch (_) {}
    try { await database.execute('ALTER TABLE ItemsPreparacion ADD COLUMN notas TEXT'); } catch (_) {}
    try { await database.execute('ALTER TABLE ItemsPreparacion ADD COLUMN sobrante INTEGER DEFAULT 0'); } catch (_) {}
    try { await database.execute('ALTER TABLE ItemsPreparacion ADD COLUMN enviado_merma INTEGER DEFAULT 0'); } catch (_) {}
    try { await database.execute('ALTER TABLE ItemsPreparacion ADD COLUMN llevado_manana INTEGER DEFAULT 0'); } catch (_) {}
    try { await database.execute('''
      CREATE TABLE IF NOT EXISTS Transformaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variante_origen_id INTEGER,
        variante_destino_id INTEGER,
        insumo_adicional_id INTEGER,
        cantidad_insumo REAL
      )
    '''); } catch (_) {}
    try { await database.execute('''
      CREATE TABLE IF NOT EXISTS Recetas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variante_id INTEGER NOT NULL,
        insumo_id INTEGER NOT NULL,
        cantidad REAL NOT NULL,
        unidad_medida TEXT NOT NULL,
        UNIQUE(variante_id, insumo_id),
        FOREIGN KEY(variante_id) REFERENCES VariantesProducto(id),
        FOREIGN KEY(insumo_id) REFERENCES Insumos(id)
      )
    '''); } catch (_) {}

    try { await database.execute('''
      CREATE TABLE IF NOT EXISTS SesionesCaja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha_apertura TEXT NOT NULL,
        monto_apertura REAL DEFAULT 0,
        estado TEXT DEFAULT 'abierta',
        fecha_cierre TEXT,
        total_efectivo_sistema REAL DEFAULT 0,
        total_yape_plin REAL DEFAULT 0,
        efectivo_contado REAL DEFAULT 0,
        diferencia REAL DEFAULT 0,
        total_gastos REAL DEFAULT 0,
        nota TEXT
      )
    '''); } catch (_) {}
    
    try { await database.execute('''
      CREATE TABLE IF NOT EXISTS MovimientosCaja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sesion_caja_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        metodo_pago TEXT,
        monto REAL NOT NULL,
        descripcion TEXT,
        fecha TEXT NOT NULL
      )
    '''); } catch (_) {}

    
    // Seed datos predefinidos (idempotente)
    final seeder = DbSeeder(database);
    await seeder.seedAll();
    
    return database;

  }

  Future _createDB(Database db, int version) async {
    // 1. ConfiguraciÃƒÂ³n del negocio
    await db.execute('''
      CREATE TABLE Configuracion (
        clave TEXT PRIMARY KEY,
        valor TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Proveedores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        email TEXT,
        direccion TEXT,
        notas TEXT,
        activo INTEGER DEFAULT 1
      )
    ''');

    // 2. Usuarios
    await db.execute('''
      CREATE TABLE Usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        correo TEXT,
        password_hash TEXT NOT NULL,
        rol TEXT NOT NULL CHECK(rol IN ('admin','empleado')),
        foto_ruta TEXT,
        activo INTEGER DEFAULT 1,
        bloqueado INTEGER DEFAULT 0,
        recovery_code TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // 3. Categorias de productos
    await db.execute('''
      CREATE TABLE Categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        icono TEXT,
        orden INTEGER DEFAULT 0
      )
    ''');

    // 4. Insumos (Ingredientes, cajas, bebidas, etc.)
    await db.execute('''
      CREATE TABLE CategoriasInsumo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      )''');
    
    await db.execute('''
      CREATE TABLE Insumos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo_insumo TEXT,
        unidad_medida TEXT NOT NULL,
        contenido_paquete INTEGER DEFAULT 1,
        rendimiento_por_unidad REAL DEFAULT 1,
        costo_por_unidad REAL DEFAULT 0,
        stock_actual REAL DEFAULT 0,
        stock_minimo REAL DEFAULT 0,
        foto_ruta TEXT,
        activo INTEGER DEFAULT 1
      )
    ''');

    // 5. Productos
    await db.execute('''
      CREATE TABLE Productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        categoria_id INTEGER REFERENCES Categorias(id),
        descripcion TEXT,
        foto_ruta TEXT,
        tipo_preparacion TEXT DEFAULT 'momento'
          CHECK(tipo_preparacion IN ('anticipado','momento','ambos')),
        bebida_cortesia_insumo_id INTEGER REFERENCES Insumos(id),
        activo INTEGER DEFAULT 1
      )
    ''');

    // 6. Variantes de producto
    await db.execute('''
      CREATE TABLE VariantesProducto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL REFERENCES Productos(id),
        nombre_variante TEXT NOT NULL,
        precio_venta REAL NOT NULL,
        costo_estimado_manual REAL DEFAULT 0,
        empaque_insumo_id INTEGER REFERENCES Insumos(id)
      )
    ''');

    // 7. Consumo Estimado
    await db.execute('''
      CREATE TABLE ConsumoEstimadoInsumo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variante_id INTEGER NOT NULL REFERENCES VariantesProducto(id),
        insumo_id INTEGER NOT NULL REFERENCES Insumos(id),
        cantidad_estimada REAL NOT NULL
      )
    ''');

    // 8. Promociones
    await db.execute('''
      CREATE TABLE Promociones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        imagen_ruta TEXT,
        tipo TEXT NOT NULL CHECK(tipo IN ('descuento_porcentaje','descuento_monto','2x1','combo')),
        valor_descuento REAL DEFAULT 0,
        fecha_inicio TEXT,
        fecha_fin TEXT,
        activa INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE PromocionVariantes (
        promo_id INTEGER REFERENCES Promociones(id),
        variante_id INTEGER REFERENCES VariantesProducto(id),
        PRIMARY KEY (promo_id, variante_id)
      )
    ''');

    // 9. Ventas
    await db.execute('''
      CREATE TABLE Ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        hora TEXT NOT NULL,
        usuario_id INTEGER REFERENCES Usuarios(id),
        metodo_pago TEXT NOT NULL CHECK(metodo_pago IN ('efectivo','yape','plin','tarjeta','mixto')),
        monto_recibido REAL,
        vuelto REAL,
        promocion_id INTEGER REFERENCES Promociones(id),
        subtotal REAL NOT NULL,
        descuento REAL DEFAULT 0,
        total REAL NOT NULL,
        anulada INTEGER DEFAULT 0,
        nota TEXT
      )
    ''');

    // 10. Detalle Venta
    await db.execute('''
      CREATE TABLE DetalleVenta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL REFERENCES Ventas(id),
        variante_id INTEGER NOT NULL REFERENCES VariantesProducto(id),
        promocion_id INTEGER,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        descuento REAL DEFAULT 0
      )
    ''');

    // 11. Activos del negocio
    await db.execute('''
      CREATE TABLE Activos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        categoria TEXT,
        descripcion TEXT,
        foto_ruta TEXT,
        tipo_adquisicion TEXT NOT NULL CHECK(tipo_adquisicion IN ('comprado','prestado','alquilado')),
        valor_estimado REAL DEFAULT 0,
        fecha_adquisicion TEXT,
        activo INTEGER DEFAULT 1,
        fecha_baja TEXT,
        motivo_baja TEXT
      )
    ''');

    // 12. Gastos
    await db.execute('''
      CREATE TABLE Gastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        categoria TEXT NOT NULL,
        descripcion TEXT,
        monto REAL NOT NULL,
        foto_recibo_ruta TEXT,
        insumo_id INTEGER REFERENCES Insumos(id),
        activo_id INTEGER REFERENCES Activos(id),
        usuario_id INTEGER REFERENCES Usuarios(id)
      )
    ''');

    // 13. Ajustes Stock
    await db.execute('''
      CREATE TABLE AjustesStock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        insumo_id INTEGER NOT NULL REFERENCES Insumos(id),
        cantidad_ajuste REAL NOT NULL,
        tipo_adquisicion TEXT CHECK(tipo_adquisicion IN ('comprado','regalado','alquilado','merma','ajuste')),
        costo_unitario REAL DEFAULT 0,
        motivo TEXT,
        usuario_id INTEGER REFERENCES Usuarios(id)
      )
    ''');

    // 14. Merma
    await db.execute('''
      CREATE TABLE Merma (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        usuario_id INTEGER REFERENCES Usuarios(id),
        tipo TEXT NOT NULL CHECK(tipo IN ('quemado','vencido','daÃ±ado','otro')),
        descripcion TEXT,
        insumo_id INTEGER REFERENCES Insumos(id),
        variante_id INTEGER REFERENCES VariantesProducto(id),
        cantidad REAL DEFAULT 0,
        foto_ruta TEXT
      )
    ''');

    // 15. Cierre Caja
    await db.execute('''
      CREATE TABLE CierreCaja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL UNIQUE,
        usuario_id INTEGER REFERENCES Usuarios(id),
        total_efectivo_sistema REAL DEFAULT 0,
        total_transferencia_sistema REAL DEFAULT 0,
        efectivo_contado REAL DEFAULT 0,
        transferencias_contadas REAL DEFAULT 0,
        diferencia_efectivo REAL DEFAULT 0,
        diferencia_transferencia REAL DEFAULT 0,
        nota TEXT,
        cerrado_en TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS SesionesCaja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha_apertura TEXT NOT NULL,
        monto_apertura REAL DEFAULT 0,
        estado TEXT DEFAULT 'abierta',
        fecha_cierre TEXT,
        total_efectivo_sistema REAL DEFAULT 0,
        total_yape_plin REAL DEFAULT 0,
        efectivo_contado REAL DEFAULT 0,
        diferencia REAL DEFAULT 0,
        total_gastos REAL DEFAULT 0,
        nota TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS MovimientosCaja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sesion_caja_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        metodo_pago TEXT,
        monto REAL NOT NULL,
        descripcion TEXT,
        fecha TEXT NOT NULL
      )
    ''');

    // 16. Historial Precios
    await db.execute('''
      CREATE TABLE HistorialPreciosInsumo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        insumo_id INTEGER NOT NULL REFERENCES Insumos(id),
        costo_por_unidad REAL NOT NULL,
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE HistorialPreciosVariante (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variante_id INTEGER NOT NULL REFERENCES VariantesProducto(id),
        precio_venta REAL NOT NULL,
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT
      )
    ''');

    // 17. Notas y AuditorÃ­a
    await db.execute('''
      CREATE TABLE NotasDia (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL UNIQUE,
        nota TEXT NOT NULL,
        usuario_id INTEGER REFERENCES Usuarios(id),
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE LogAuditoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL DEFAULT (datetime('now')),
        usuario_id INTEGER REFERENCES Usuarios(id),
        accion TEXT NOT NULL,
        detalle TEXT
      )
    ''');
    // Tablas nuevas
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
        cantidad_preparada INTEGER NOT NULL DEFAULT 0,
        notas TEXT,
        sobrante INTEGER DEFAULT 0,
        enviado_merma INTEGER DEFAULT 0,
        llevado_manana INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Transformaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variante_origen_id INTEGER,
        variante_destino_id INTEGER,
        insumo_adicional_id INTEGER,
        cantidad_insumo REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Recetas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variante_id INTEGER NOT NULL,
        insumo_id INTEGER NOT NULL,
        cantidad REAL NOT NULL,
        unidad_medida TEXT NOT NULL,
        UNIQUE(variante_id, insumo_id),
        FOREIGN KEY(variante_id) REFERENCES VariantesProducto(id),
        FOREIGN KEY(insumo_id) REFERENCES Insumos(id)
      )
    ''');

    
        // 9. Activos Fijos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ActivosFijos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          categoria TEXT,
          costo REAL DEFAULT 0,
          fecha_adquisicion TEXT,
          estado TEXT DEFAULT 'En uso',
          observaciones TEXT,
          foto_ruta TEXT,
          activo INTEGER DEFAULT 1,
          condicion TEXT DEFAULT 'Comprado',
          metodo_pago TEXT DEFAULT 'Contado',
          cuotas INTEGER DEFAULT 1,
          cantidad INTEGER DEFAULT 1,
          frecuencia_alquiler TEXT
        )
    ''');

    // Insertar datos de configuraciÃƒÂ³n por defecto
    await db.insert('Configuracion', {'clave': 'moneda', 'valor': 'PEN'});
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}












