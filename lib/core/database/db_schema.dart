class DbSchema {
  // 1. Configuracion del negocio
  static const String createConfiguracion = '''
      CREATE TABLE Configuracion (
        clave TEXT PRIMARY KEY,
        valor TEXT
      )
    ''';

  static const String createProveedores = '''
      CREATE TABLE Proveedores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        email TEXT,
        direccion TEXT,
        notas TEXT,
        activo INTEGER DEFAULT 1
      )
    ''';

  // 2. Usuarios
  static const String createUsuarios = '''
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
    ''';

  // 3. Categorias de productos
  static const String createCategorias = '''
      CREATE TABLE Categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        icono TEXT,
        orden INTEGER DEFAULT 0
      )
    ''';

  // 4. Insumos
  static const String createCategoriasInsumo = '''
      CREATE TABLE CategoriasInsumo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      )''';

  static const String createInsumos = '''
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
    ''';

  // 5. Productos
  static const String createProductos = '''
      CREATE TABLE Productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        categoria_id INTEGER REFERENCES Categorias(id),
        descripcion TEXT,
        foto_ruta TEXT,
        tipo_preparacion TEXT DEFAULT 'momento'
          CHECK(tipo_preparacion IN ('anticipado','momento','ambos')),
        bebida_cortesia_insumo_id INTEGER REFERENCES Insumos(id),
        bebida_cortesia_cantidad REAL NOT NULL DEFAULT 1,
        deriva_de_producto_id INTEGER REFERENCES Productos(id),
        activo INTEGER DEFAULT 1
      )
    ''';

  // 6. Variantes de producto
  static const String createVariantesProducto = '''
      CREATE TABLE VariantesProducto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL REFERENCES Productos(id),
        nombre_variante TEXT NOT NULL,
        precio_venta REAL NOT NULL,
        costo_estimado_manual REAL DEFAULT 0,
        empaque_insumo_id INTEGER REFERENCES Insumos(id),
        imagen TEXT,
        stock INTEGER DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        variante_base_id INTEGER REFERENCES VariantesProducto(id)
      )
    ''';

  // 7. Consumo Estimado
  static const String createConsumoEstimadoInsumo = '''
      CREATE TABLE ConsumoEstimadoInsumo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variante_id INTEGER NOT NULL REFERENCES VariantesProducto(id),
        insumo_id INTEGER NOT NULL REFERENCES Insumos(id),
        cantidad_estimada REAL NOT NULL
      )
    ''';

  // 8. Promociones
  static const String createPromociones = '''
      CREATE TABLE Promociones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        imagen_ruta TEXT,
        tipo TEXT NOT NULL CHECK(tipo IN ('descuento_porcentaje','descuento_monto','2x1','combo')),
        valor_descuento REAL DEFAULT 0,
        fecha_inicio TEXT,
        fecha_fin TEXT,
        descripcion TEXT,
        precio REAL NOT NULL DEFAULT 0,
        dias_semana TEXT,
        hora_inicio TEXT,
        hora_fin TEXT,
        activa INTEGER DEFAULT 1
      )
    ''';

  static const String createPromocionVariantes = '''
      CREATE TABLE PromocionVariantes (
        promo_id INTEGER REFERENCES Promociones(id),
        variante_id INTEGER REFERENCES VariantesProducto(id),
        PRIMARY KEY (promo_id, variante_id)
      )
    ''';

  static const String createPromocionItems = '''
      CREATE TABLE IF NOT EXISTS PromocionItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        promocion_id INTEGER NOT NULL REFERENCES Promociones(id),
        variante_id INTEGER REFERENCES VariantesProducto(id),
        insumo_id INTEGER REFERENCES Insumos(id),
        cantidad INTEGER NOT NULL DEFAULT 1
      )
    ''';

  // 9. Ventas
  static const String createVentas = '''
      CREATE TABLE Ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        hora TEXT NOT NULL,
        usuario_id INTEGER REFERENCES Usuarios(id),
        metodo_pago TEXT NOT NULL CHECK(metodo_pago IN ('efectivo','yape','plin','tarjeta','mixto','cortesia','yape/plin')),
        monto_recibido REAL,
        vuelto REAL,
        promocion_id INTEGER REFERENCES Promociones(id),
        subtotal REAL NOT NULL,
        descuento REAL DEFAULT 0,
        total REAL NOT NULL,
        anulada INTEGER DEFAULT 0,
        es_historica INTEGER NOT NULL DEFAULT 0,
        nota TEXT
      )
    ''';

  // 10. Detalle Venta
  static const String createDetalleVenta = '''
      CREATE TABLE DetalleVenta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL REFERENCES Ventas(id),
        variante_id INTEGER REFERENCES VariantesProducto(id),
        promocion_id INTEGER,
        es_cortesia INTEGER NOT NULL DEFAULT 0,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        descuento REAL DEFAULT 0
      )
    ''';

  // 11. Activos del negocio
  static const String createActivos = '''
      CREATE TABLE Activos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        categoria TEXT,
        descripcion TEXT,
        foto_ruta TEXT,
        tipo_adquisicion TEXT NOT NULL CHECK(tipo_adquisicion IN ('comprado','prestado','alquilado','regalado')),
        valor_estimado REAL DEFAULT 0,
        fecha_adquisicion TEXT,
        activo INTEGER DEFAULT 1,
        fecha_baja TEXT,
        motivo_baja TEXT
      )
    ''';

  // 11b. Compras ocasionales (egresos sin inventario)
  static const String createComprasOcasionales = '''
      CREATE TABLE IF NOT EXISTS ComprasOcasionales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        cantidad REAL NOT NULL CHECK(cantidad > 0),
        unidad_medida TEXT,
        costo_total REAL NOT NULL CHECK(costo_total > 0),
        categoria TEXT NOT NULL,
        proveedor TEXT,
        proveedor_id INTEGER REFERENCES Proveedores(id),
        factura_ruta TEXT,
        es_por_pagar INTEGER NOT NULL DEFAULT 0 CHECK(es_por_pagar IN (0, 1)),
        adelanto REAL NOT NULL DEFAULT 0 CHECK(adelanto >= 0 AND adelanto <= costo_total),
        cuotas INTEGER NOT NULL DEFAULT 1 CHECK(cuotas >= 1),
        metodo_pago TEXT,
        usuario_id INTEGER REFERENCES Usuarios(id),
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      )
    ''';

  // 12. Gastos
  static const String createGastos = '''
      CREATE TABLE Gastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        categoria TEXT NOT NULL,
        descripcion TEXT,
        monto REAL NOT NULL,
        foto_recibo_ruta TEXT,
        insumo_id INTEGER REFERENCES Insumos(id),
        activo_id INTEGER REFERENCES Activos(id),
        activo_fijo_id INTEGER REFERENCES ActivosFijos(id),
        compra_movimiento_id INTEGER REFERENCES AjustesStock(id),
        usuario_id INTEGER REFERENCES Usuarios(id),
        sesion_caja_id INTEGER REFERENCES SesionesCaja(id),
        movimiento_caja_id INTEGER REFERENCES MovimientosCaja(id),
        compra_ocasional_id INTEGER REFERENCES ComprasOcasionales(id)
      )
    ''';

  // 13. Ajustes Stock
  static const String createAjustesStock = '''
      CREATE TABLE AjustesStock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        insumo_id INTEGER NOT NULL REFERENCES Insumos(id),
        cantidad_ajuste REAL NOT NULL,
        tipo_adquisicion TEXT CHECK(tipo_adquisicion IN ('comprado','regalado','alquilado','merma','ajuste','consumo','reversion_consumo')),
        costo_unitario REAL DEFAULT 0,
        motivo TEXT,
        proveedor_id INTEGER REFERENCES Proveedores(id),
        venta_id INTEGER REFERENCES Ventas(id),
        usuario_id INTEGER REFERENCES Usuarios(id)
      )
    ''';

  // 14. Merma
  static const String createMerma = '''
      CREATE TABLE Merma (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        usuario_id INTEGER REFERENCES Usuarios(id),
        tipo TEXT NOT NULL CHECK(tipo IN ('quemado','vencido','dañado','otro')),
        descripcion TEXT,
        insumo_id INTEGER REFERENCES Insumos(id),
        variante_id INTEGER REFERENCES VariantesProducto(id),
        cantidad REAL DEFAULT 0,
        foto_ruta TEXT
      )
    ''';

  // 15. Cierre Caja
  static const String createCierreCaja = '''
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
    ''';

  static const String createSesionesCaja = '''
      CREATE TABLE IF NOT EXISTS SesionesCaja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha_apertura TEXT NOT NULL,
        monto_apertura REAL DEFAULT 0,
        transferencias_apertura REAL NOT NULL DEFAULT 0,
        estado TEXT DEFAULT 'abierta',
        fecha_cierre TEXT,
        total_efectivo_sistema REAL DEFAULT 0,
        total_yape_plin REAL DEFAULT 0,
        efectivo_contado REAL DEFAULT 0,
        diferencia REAL DEFAULT 0,
        total_gastos REAL DEFAULT 0,
        total_gastos_ciclo REAL NOT NULL DEFAULT 0,
        nota TEXT,
        transferencias_contadas REAL NOT NULL DEFAULT 0,
        diferencia_efectivo REAL NOT NULL DEFAULT 0,
        diferencia_transferencia REAL NOT NULL DEFAULT 0,
        total_esperado REAL NOT NULL DEFAULT 0,
        usuario_apertura_id INTEGER REFERENCES Usuarios(id),
        usuario_cierre_id INTEGER REFERENCES Usuarios(id)
      )
    ''';

  static const String createMovimientosCaja = '''
      CREATE TABLE IF NOT EXISTS MovimientosCaja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sesion_caja_id INTEGER NOT NULL REFERENCES SesionesCaja(id),
        venta_id INTEGER REFERENCES Ventas(id),
        compra_movimiento_id INTEGER REFERENCES AjustesStock(id),
        tipo TEXT NOT NULL,
        metodo_pago TEXT,
        monto REAL NOT NULL,
        descripcion TEXT,
        fecha TEXT NOT NULL
      )
    ''';

  // 16. Historial Precios
  static const String createHistorialPreciosInsumo = '''
      CREATE TABLE HistorialPreciosInsumo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        insumo_id INTEGER NOT NULL REFERENCES Insumos(id),
        costo_por_unidad REAL NOT NULL,
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT
      )
    ''';

  static const String createHistorialPreciosVariante = '''
      CREATE TABLE HistorialPreciosVariante (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variante_id INTEGER NOT NULL REFERENCES VariantesProducto(id),
        precio_venta REAL NOT NULL,
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT
      )
    ''';

  // 17. Notas y Auditoria
  static const String createNotasDia = '''
      CREATE TABLE NotasDia (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL UNIQUE,
        nota TEXT NOT NULL,
        usuario_id INTEGER REFERENCES Usuarios(id),
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''';

  static const String createLogAuditoria = '''
      CREATE TABLE LogAuditoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL DEFAULT (datetime('now')),
        usuario_id INTEGER REFERENCES Usuarios(id),
        accion TEXT NOT NULL,
        detalle TEXT
      )
    ''';

  static const String createCuentasPorPagar = '''
      CREATE TABLE IF NOT EXISTS CuentasPorPagar (
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
        compra_movimiento_id INTEGER REFERENCES AjustesStock(id),
        compra_ocasional_id INTEGER REFERENCES ComprasOcasionales(id)
      )
    ''';

  /// Forma v23 de CuentasPorPagar, sin `compra_ocasional_id`. La migración
  /// consolidada v23 corre antes de que exista `ComprasOcasionales`; la v27
  /// agrega la columna con `_ensureColumn`.
  static const String createCuentasPorPagarV23 = '''
      CREATE TABLE IF NOT EXISTS CuentasPorPagar (
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
    ''';

  static const String createPagosCuentaPorPagar = '''
      CREATE TABLE IF NOT EXISTS PagosCuentaPorPagar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cuenta_id INTEGER NOT NULL REFERENCES CuentasPorPagar(id),
        fecha TEXT NOT NULL,
        monto REAL NOT NULL CHECK(monto > 0),
        metodo_pago TEXT NOT NULL DEFAULT 'efectivo' CHECK(metodo_pago IN ('efectivo','yape','plin','yape/plin','otro')),
        nota TEXT,
        usuario_id INTEGER REFERENCES Usuarios(id),
        sesion_caja_id INTEGER REFERENCES SesionesCaja(id),
        gasto_id INTEGER REFERENCES Gastos(id),
        movimiento_caja_id INTEGER REFERENCES MovimientosCaja(id),
        legado INTEGER NOT NULL DEFAULT 0 CHECK(legado IN (0,1))
      )
    ''';

  static const String createPreparacionDiaria = '''
      CREATE TABLE IF NOT EXISTS PreparacionDiaria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        usuario_id INTEGER REFERENCES Usuarios(id),
        nota TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''';

  static const String createItemsPreparacion = '''
      CREATE TABLE IF NOT EXISTS ItemsPreparacion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        preparacion_id INTEGER NOT NULL REFERENCES PreparacionDiaria(id),
        variante_id INTEGER NOT NULL REFERENCES VariantesProducto(id),
        cantidad_preparada INTEGER NOT NULL DEFAULT 0,
        notas TEXT,
        sobrante INTEGER DEFAULT 0,
        enviado_merma INTEGER DEFAULT 0,
        llevado_manana INTEGER DEFAULT 0,
        resuelto INTEGER DEFAULT 0
      )
    ''';

  static const String createTransformaciones = '''
      CREATE TABLE IF NOT EXISTS Transformaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variante_origen_id INTEGER REFERENCES VariantesProducto(id),
        variante_destino_id INTEGER REFERENCES VariantesProducto(id),
        insumo_adicional_id INTEGER REFERENCES Insumos(id),
        cantidad_insumo REAL,
        rendimiento REAL NOT NULL DEFAULT 1,
        unidad_insumo TEXT,
        activa INTEGER NOT NULL DEFAULT 1
      )
    ''';

  static const String createTransformacionInsumos = '''
      CREATE TABLE IF NOT EXISTS TransformacionInsumos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transformacion_id INTEGER NOT NULL REFERENCES Transformaciones(id) ON DELETE CASCADE,
        insumo_id INTEGER NOT NULL REFERENCES Insumos(id),
        cantidad REAL NOT NULL CHECK(cantidad > 0),
        unidad_medida TEXT NOT NULL
      )
    ''';

  static const String createMovimientosStockPreparado = '''
      CREATE TABLE IF NOT EXISTS MovimientosStockPreparado (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        variante_id INTEGER NOT NULL REFERENCES VariantesProducto(id),
        cantidad REAL NOT NULL CHECK(cantidad <> 0),
        tipo TEXT NOT NULL,
        referencia_id INTEGER,
        motivo TEXT,
        usuario_id INTEGER REFERENCES Usuarios(id)
      )
    ''';

  static const String createFaltantesPreparacion = '''
      CREATE TABLE IF NOT EXISTS FaltantesPreparacion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variante_id INTEGER NOT NULL REFERENCES VariantesProducto(id),
        fecha TEXT NOT NULL,
        cantidad INTEGER NOT NULL CHECK(cantidad > 0),
        motivo TEXT,
        created_at TEXT
      )
    ''';

  /// Índice del algoritmo de sugerencias (consulta por variante + fecha).
  static const String indexFaltantesPreparacion =
      'CREATE INDEX IF NOT EXISTS IDX_FaltantesPreparacion_variante_fecha ON FaltantesPreparacion(variante_id, fecha)';

  static const String createCorreccionesCompra = '''
      CREATE TABLE IF NOT EXISTS CorreccionesCompra (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        compra_movimiento_id INTEGER NOT NULL REFERENCES AjustesStock(id),
        ajuste_stock_id INTEGER REFERENCES AjustesStock(id),
        cantidad_anterior REAL NOT NULL,
        costo_unitario_anterior REAL NOT NULL,
        cantidad_nueva REAL NOT NULL,
        costo_unitario_nuevo REAL NOT NULL,
        motivo TEXT,
        fecha TEXT NOT NULL,
        usuario_id INTEGER REFERENCES Usuarios(id)
      )
    ''';

  static const String createRecetas = '''
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
    ''';

  static const String createCategoriasActivo = '''
      CREATE TABLE IF NOT EXISTS CategoriasActivo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      )
    ''';

  static const String createActivosFijos = '''
      CREATE TABLE IF NOT EXISTS ActivosFijos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          categoria TEXT,
          costo REAL DEFAULT 0,
          fecha_adquisicion TEXT,
          estado TEXT NOT NULL DEFAULT 'En uso' CHECK(estado IN ('En uso','En reparación','Fuera de servicio')),
          observaciones TEXT,
          foto_ruta TEXT,
          activo INTEGER DEFAULT 1,
          condicion TEXT NOT NULL DEFAULT 'Comprado' CHECK(condicion IN ('Comprado','Alquilado','Prestado','Regalado')),
          metodo_pago TEXT NOT NULL DEFAULT 'Contado' CHECK(metodo_pago IN ('Contado','Crédito')),
          cuotas INTEGER NOT NULL DEFAULT 1 CHECK(cuotas > 0),
          cantidad INTEGER NOT NULL DEFAULT 1 CHECK(cantidad > 0),
          frecuencia_alquiler TEXT
        )
    ''';

  static const List<String> initialTables = [
    createConfiguracion,
    createProveedores,
    createUsuarios,
    createCategorias,
    createCategoriasInsumo,
    createCategoriasActivo,
    createInsumos,
    createProductos,
    createVariantesProducto,
    createConsumoEstimadoInsumo,
    createPromociones,
    createPromocionVariantes,
    createPromocionItems,
    createVentas,
    createDetalleVenta,
    createActivos,
    createActivosFijos,
    createComprasOcasionales,
    createGastos,
    createAjustesStock,
    createMerma,
    createCierreCaja,
    createSesionesCaja,
    createMovimientosCaja,
    createHistorialPreciosInsumo,
    createHistorialPreciosVariante,
    createNotasDia,
    createLogAuditoria,
    createCuentasPorPagar,
    createPagosCuentaPorPagar,
    createPreparacionDiaria,
    createItemsPreparacion,
    createTransformaciones,
    createTransformacionInsumos,
    createMovimientosStockPreparado,
    createFaltantesPreparacion,
    createCorreccionesCompra,
    createRecetas,
  ];

  static const List<String> triggers = [
    '''
      CREATE TRIGGER IF NOT EXISTS validar_activo_fijo_insert
      BEFORE INSERT ON ActivosFijos
      WHEN NEW.condicion NOT IN ('Comprado','Alquilado','Prestado','Regalado')
        OR NEW.cantidad < 1
        OR (NEW.condicion = 'Comprado' AND NEW.metodo_pago NOT IN ('Contado','Crédito'))
        OR NEW.cuotas < 1
      BEGIN
        SELECT RAISE(ABORT, 'Datos de adquisición de activo no válidos');
      END
    ''',
    '''
      CREATE TRIGGER IF NOT EXISTS validar_activo_fijo_update
      BEFORE UPDATE OF condicion, metodo_pago, cuotas, cantidad ON ActivosFijos
      WHEN NEW.condicion NOT IN ('Comprado','Alquilado','Prestado','Regalado')
        OR NEW.cantidad < 1
        OR (NEW.condicion = 'Comprado' AND NEW.metodo_pago NOT IN ('Contado','Crédito'))
        OR NEW.cuotas < 1
      BEGIN
        SELECT RAISE(ABORT, 'Datos de adquisición de activo no válidos');
      END
    ''',
    '''
      CREATE TRIGGER IF NOT EXISTS validar_cuenta_por_pagar_insert
      BEFORE INSERT ON CuentasPorPagar
      WHEN NEW.costo_total <= 0 OR NEW.cantidad <= 0 OR NEW.cuotas < 1
        OR COALESCE(NEW.monto_pagado, 0) < 0
        OR COALESCE(NEW.monto_pagado, 0) > NEW.costo_total
      BEGIN
        SELECT RAISE(ABORT, 'Datos de cuenta por pagar no válidos');
      END
    ''',
    '''
      CREATE TRIGGER IF NOT EXISTS validar_cuenta_por_pagar_update
      BEFORE UPDATE OF costo_total, cantidad, cuotas, monto_pagado ON CuentasPorPagar
      WHEN NEW.costo_total <= 0 OR NEW.cantidad <= 0 OR NEW.cuotas < 1
        OR COALESCE(NEW.monto_pagado, 0) < 0
        OR COALESCE(NEW.monto_pagado, 0) > NEW.costo_total
      BEGIN
        SELECT RAISE(ABORT, 'Datos de cuenta por pagar no válidos');
      END
    ''',
  ];

  /// 24 índices estratégicos base de lectura y claves foráneas (C-12 / C-16).
  static const List<String> indexes = [
    'CREATE INDEX IF NOT EXISTS IDX_Productos_categoria_activo ON Productos(categoria_id, activo)',
    'CREATE INDEX IF NOT EXISTS IDX_Productos_deriva_de ON Productos(deriva_de_producto_id)',
    'CREATE INDEX IF NOT EXISTS IDX_VariantesProducto_producto_active ON VariantesProducto(producto_id, active)',
    'CREATE INDEX IF NOT EXISTS IDX_VariantesProducto_base ON VariantesProducto(variante_base_id)',
    'CREATE INDEX IF NOT EXISTS IDX_Recetas_variante ON Recetas(variante_id)',
    'CREATE INDEX IF NOT EXISTS IDX_Recetas_insumo ON Recetas(insumo_id)',
    'CREATE INDEX IF NOT EXISTS IDX_PromocionItems_promocion ON PromocionItems(promocion_id)',
    'CREATE INDEX IF NOT EXISTS IDX_Ventas_fecha_anulada ON Ventas(fecha, anulada)',
    'CREATE INDEX IF NOT EXISTS IDX_Ventas_usuario ON Ventas(usuario_id)',
    'CREATE INDEX IF NOT EXISTS IDX_DetalleVenta_venta ON DetalleVenta(venta_id)',
    'CREATE INDEX IF NOT EXISTS IDX_DetalleVenta_variante ON DetalleVenta(variante_id)',
    'CREATE INDEX IF NOT EXISTS IDX_SesionesCaja_estado_apertura ON SesionesCaja(estado, fecha_apertura)',
    'CREATE INDEX IF NOT EXISTS IDX_MovimientosCaja_sesion_tipo ON MovimientosCaja(sesion_caja_id, tipo)',
    'CREATE INDEX IF NOT EXISTS IDX_MovimientosCaja_venta ON MovimientosCaja(venta_id)',
    'CREATE INDEX IF NOT EXISTS IDX_MovimientosCaja_compra ON MovimientosCaja(compra_movimiento_id)',
    'CREATE INDEX IF NOT EXISTS IDX_Gastos_fecha ON Gastos(fecha)',
    'CREATE INDEX IF NOT EXISTS IDX_Gastos_sesion_caja ON Gastos(sesion_caja_id)',
    'CREATE INDEX IF NOT EXISTS IDX_Gastos_compra_movimiento ON Gastos(compra_movimiento_id)',
    'CREATE INDEX IF NOT EXISTS IDX_AjustesStock_insumo_fecha ON AjustesStock(insumo_id, fecha)',
    'CREATE INDEX IF NOT EXISTS IDX_AjustesStock_tipo_fecha ON AjustesStock(tipo_adquisicion, fecha)',
    'CREATE INDEX IF NOT EXISTS IDX_CuentasPorPagar_pagado_fecha ON CuentasPorPagar(pagado, fecha)',
    'CREATE INDEX IF NOT EXISTS IDX_CuentasPorPagar_compra_movimiento ON CuentasPorPagar(compra_movimiento_id)',
    'CREATE INDEX IF NOT EXISTS IDX_PagosCuentaPorPagar_cuenta ON PagosCuentaPorPagar(cuenta_id)',
    indexFaltantesPreparacion,
  ];

  /// Índices incorporados en la v26. Se mantienen fuera de [indexes] porque la
  /// migración v23 (que los recorre en bases legadas) corre antes de que exista
  /// la columna `AjustesStock.venta_id`.
  static const String indexAjustesStockVenta =
      'CREATE INDEX IF NOT EXISTS IDX_AjustesStock_venta_id ON AjustesStock(venta_id)';

  static const List<String> indexesV26 = [indexAjustesStockVenta];

  /// Índices incorporados en la v27 para la cabecera ocasional y sus vínculos
  /// financieros. Se ejecutan después de crear las columnas de la v27.
  static const List<String> indexesV27 = [
    'CREATE INDEX IF NOT EXISTS IDX_ComprasOcasionales_fecha ON ComprasOcasionales(fecha)',
    'CREATE INDEX IF NOT EXISTS IDX_Gastos_compra_ocasional ON Gastos(compra_ocasional_id)',
    'CREATE INDEX IF NOT EXISTS IDX_CuentasPorPagar_compra_ocasional ON CuentasPorPagar(compra_ocasional_id)',
  ];
}
