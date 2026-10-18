# DOCUMENTACIÓN TÉCNICA Y CONTRATOS DE API — KIMI PIZZA
**Documento:** API-TECH-2026-V2.0  
**Proyecto:** KIMI PIZZA — Core Software Components & Service Interfaces  
**Nivel de Audiencia:** Arquitectos de Software, Desarrolladores Flutter y Agentes Autónomos de IA  
**Estado:** Contratos Técnicos Oficiales (Day-0 Baseline)  

---

## 1. INTRODUCCIÓN

Este documento define la interfaz pública, contratos de métodos, firmas de tipos, modelos de datos y protocolos de excepción para cada una de las capas del sistema KIMI PIZZA. Cualquier componente o módulo nuevo debe respetar estas firmas e invariantes.

---

## 2. CONTRATOS DE REPOSITORIOS (DATA LAYER)

### 2.1 `UsuarioRepository`
Responsable de la persistencia y autenticación de usuarios y administradores.

```dart
abstract class IUsuarioRepository {
  /// Verifica si existe al menos un usuario administrador registrado en el sistema.
  Future<bool> adminExists();

  /// Registra el administrador maestro inicial (Onboarding).
  /// Retorna el ID del usuario insertado.
  Future<int> createInitialAdmin({
    required String username,
    required String passwordHash,
    required String salt,
    required String nombreCompleto,
    required String recoveryCodeHash,
    String? correo,
    String? fotoPath,
  });

  /// Busca un usuario activo por su nombre de usuario (username).
  Future<Usuario?> findByUsername(String username);

  /// Actualiza la contraseña de un usuario mediante el flujo de recuperación.
  Future<void> updatePassword(int usuarioId, String newPasswordHash, String newSalt);

  /// Lista todos los usuarios colaboradores activos.
  Future<List<Usuario>> listUsuarios({bool soloActivos = true});
}
```

### 2.2 `InsumoRepository`
Responsable del inventario de materia prima, stock mínimo y costos unitarios.

```dart
abstract class IInsumoRepository {
  /// Obtiene la lista completa de insumos ordenados por categoría y nombre.
  Future<List<Insumo>> getInsumos();

  /// Inserta un nuevo insumo con su unidad base y stock inicial.
  Future<int> insertInsumo(Insumo insumo);

  /// Actualiza datos descriptivos o umbral mínimo de un insumo.
  Future<void> updateInsumo(Insumo insumo);

  /// Modifica el stock de forma atómica dentro de una transacción.
  /// [delta] puede ser positivo (compra) o negativo (preparación/merma).
  Future<void> ajustarStock(int insumoId, double delta, {dynamic txn});

  /// Actualiza el costo unitario promedio ponderado tras una compra.
  Future<void> actualizarCostoUnitario(int insumoId, double nuevoCostoUnitario, {dynamic txn});
}
```

### 2.3 `VentaRepository`
Responsable de la persistencia atómica de órdenes de venta, deducción de stock y trazabilidad de comprobantes.

```dart
abstract class IVentaRepository {
  /// Registra una venta completa en una única transacción SQLite (ACID):
  /// 1. Inserta orden en `ventas`.
  /// 2. Inserta ítems en `detalle_ventas`.
  /// 3. Descuenta stock físico de `variantes_producto`.
  /// 4. Inserta movimiento de caja en `movimientos_caja`.
  /// Retorna el ID de la venta creada.
  Future<int> registrarVentaCompleta({
    required Venta venta,
    required List<DetalleVenta> detalles,
    required int sesionCajaId,
    required int usuarioId,
  });

  /// Consulta el historial reciente de ventas para visualización y reimpresión de boletas.
  Future<List<Venta>> getHistorialVentas({int limit = 50, int offset = 0});

  /// Reconstruye una venta con sus detalles a partir de la base de datos.
  Future<Map<String, dynamic>?> getVentaConDetalles(int ventaId);

  /// Obtiene el resumen de ventas del día o del ciclo operativo actual.
  Future<ResumenVentasHoy> getResumenHoy(String cicloOperativo);
}
```

### 2.4 `CajaRepository`
Responsable de las sesiones de caja, arqueo ciego, trazabilidad de gastos y balance financiero.

```dart
abstract class ICajaRepository {
  /// Obtiene la sesión de caja actualmente abierta, o null si la caja está cerrada.
  Future<SesionCaja?> getSesionAbierta();

  /// Abre una nueva sesión de caja asignando el ciclo operativo correspondiente.
  Future<int> abrirCaja({
    required double montoApertura,
    required int usuarioId,
    required String cicloOperativo,
  });

  /// Registra el cierre de caja con los valores del arqueo ciego y calcula la diferencia.
  Future<void> cerrarCaja({
    required int sesionId,
    required int usuarioCierreId,
    required double efectivoContado,
    required String? notaCierre,
  });

  /// Inserta un movimiento manual de entrada o salida de efectivo.
  Future<int> insertMovimiento(MovimientoCaja movimiento);

  /// Obtiene todos los movimientos asociados a una sesión de caja específica.
  Future<List<MovimientoCaja>> getMovimientosPorSesion(int sesionId);

  /// Reapertura excepcional autorizada por administrador con motivo registrado.
  Future<void> reabrirCajaExcepcional(int sesionId, int adminId, String motivo);
}
```

---

## 3. CONTRATOS DE SERVICIOS DE DOMINIO (DOMAIN LAYER)

### 3.1 `ConversionesHelper`
Utilidad canónica pura para la conversión bidireccional de magnitudes físicas.

```dart
class ConversionesHelper {
  /// Convierte una cantidad de una unidad de medida a otra compatible.
  /// Lanza [ArgumentError] si las magnitudes físicas son incompatibles.
  static double convertir(
    double cantidad,
    String unidadOrigen,
    String unidadDestino, {
    double factorPaquete = 1.0,
  });

  /// Determina si dos unidades de medida pertenecen a la misma dimensión física.
  static bool sonCompatibles(String unidadA, String unidadB);
}
```

### 3.2 `SugerenciasService`
Motor algorítmico heurístico para la planificación de cocina.

```dart
class SugerenciasService {
  /// Calcula la lista de sugerencias de preparación para el ciclo actual.
  /// Combina:
  /// - Promedio de ventas históricas del mismo día de la semana (últimas 4 semanas).
  /// - Faltantes registrados en el último turno (cantidades preparadas en negativo).
  /// - Sobrantes válidos trasladados desde el turno anterior.
  Future<List<SugerenciaItem>> calcularSugerencias({
    required String cicloOperativoActual,
    required int diaDeLaSemana, // 1 = Lunes, 7 = Domingo
  });
}
```

### 3.3 `PosService`
Coordinador del flujo de cobro, validación de stock y emisión de tickets.

```dart
class PosService {
  /// Orquesta el proceso de venta:
  /// 1. Valida que la sesión de caja esté abierta.
  /// 2. Valida stock suficiente para cada variante en el carrito.
  /// 3. Normaliza método de pago (ej. 'yape/plin' -> 'yape').
  /// 4. Invoca VentaRepository.registrarVentaCompleta.
  /// 5. Invoca PdfService.generarBoletaPDF y guarda en /boletas/boleta_{id}.pdf.
  /// Retorna la ruta absoluta del archivo PDF generado.
  Future<String?> registrarVenta({
    required List<CartItem> carrito,
    required String metodoPago,
    required double montoRecibido,
    required double descuento,
    required String? nota,
    required SesionCaja sesionActiva,
    required Usuario usuarioActual,
  });

  /// Obtiene la boleta en PDF existente en disco o la recrea desde la base de datos si falta.
  Future<String?> obtenerORecrearBoletaPDF(int ventaId);
}
```

### 3.4 `PdfService`
Motor de generación de documentos de alta fidelidad estética.

```dart
class PdfService {
  /// Genera una boleta de venta en formato ticket (80mm o A5) y la almacena persistentemente.
  Future<File> generarBoletaTicket({
    required Venta venta,
    required List<DetalleVenta> detalles,
    required Map<String, dynamic> configEmpresa,
  });

  /// Genera un informe financiero ejecutivo en formato A4 con P&L y gráficos/tablas.
  Future<File> generarReporteFinanciero({
    required ReporteData reporte,
    required String rangoFechas,
    required Map<String, dynamic> configEmpresa,
  });
}
```

---

## 4. CONTRATOS DE CONTROLADORES (PRESENTATION STATE)

### 4.1 `PosController` (`ChangeNotifier`)
```dart
class PosController extends ChangeNotifier {
  List<CartItem> get carrito;
  double get subtotal;
  double get total;
  double get descuento;
  bool get isLoading;
  String? get error;

  void agregarProducto(VarianteProducto variante, {int cantidad = 1});
  void agregarPromocion(Promocion promocion);
  void decrementarItem(int index);
  void removerItem(int index);
  void aplicarDescuento(double monto);
  void marcarItemCortesia(int index, bool esCortesia);
  void limpiarCarrito();

  /// Ejecuta el cobro y retorna la ruta del archivo PDF generado o null si falló.
  Future<String?> procesarCobro({
    required String metodoPago,
    required double montoRecibido,
    String? nota,
  });
}
```

### 4.2 `CajaController` (`ChangeNotifier`)
```dart
class CajaController extends ChangeNotifier {
  SesionCaja? get sesionActual;
  bool get tieneCajaAbierta => sesionActual != null && sesionActual!.estado == 'abierta';
  List<MovimientoCaja> get movimientos;
  bool get isLoading;
  String? get error;

  Future<void> cargarSesionActiva();
  Future<void> abrirCaja(double montoApertura);
  Future<void> registrarMovimientoManual({
    required String tipo, // 'entrada' | 'salida'
    required String descripcion,
    required double monto,
    required String metodoPago,
  });
  Future<void> cerrarCaja({
    required double efectivoContado,
    String? nota,
  });
  Future<void> reabrirCajaExcepcional(String motivo);
}
```

---

## 5. MODELOS DE DATOS Y SERIALIZACIÓN (MAP/JSON)

### 5.1 Entidad `Venta`
```dart
class Venta {
  final int? id;
  final String fecha;
  final String cicloOperativo;
  final int sesionCajaId;
  final int usuarioId;
  final double subtotal;
  final double descuento;
  final double total;
  final String metodoPago;
  final double? montoRecibido;
  final double vuelto;
  final String? boletaPdfPath;
  final String? nota;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'fecha': fecha,
    'ciclo_operativo': cicloOperativo,
    'sesion_caja_id': sesionCajaId,
    'usuario_id': usuarioId,
    'subtotal': subtotal,
    'descuento': descuento,
    'total': total,
    'metodo_pago': metodoPago,
    'monto_recibido': montoRecibido,
    'vuelto': vuelto,
    'boleta_pdf_path': boletaPdfPath,
    'nota': nota,
  };

  factory Venta.fromMap(Map<String, dynamic> map) => Venta(
    id: map['id'] as int?,
    fecha: map['fecha'] as String,
    cicloOperativo: map['ciclo_operativo'] as String,
    sesionCajaId: map['sesion_caja_id'] as int,
    usuarioId: map['usuario_id'] as int,
    subtotal: (map['subtotal'] as num).toDouble(),
    descuento: (map['descuento'] as num?)?.toDouble() ?? 0.0,
    total: (map['total'] as num).toDouble(),
    metodoPago: map['metodo_pago'] as String,
    montoRecibido: (map['monto_recibido'] as num?)?.toDouble(),
    vuelto: (map['vuelto'] as num?)?.toDouble() ?? 0.0,
    boletaPdfPath: map['boleta_pdf_path'] as String?,
    nota: map['nota'] as String?,
  );
}
```
