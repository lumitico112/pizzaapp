# Compras ocasionales y busqueda de insumos - Diseno tecnico

**Estado:** Fase 1 cerrada (inspeccion y diseno, sin cambios de codigo de produccion).

**Fecha:** 19/10/2026.

**Objetivo:** permitir buscar insumos existentes en "Nueva compra" y registrar compras ocasionales que no crean insumos ni modifican inventario, manteniendo caja, gastos, cuentas por pagar, reportes y auditoria.

---

## 1. Resumen ejecutivo

El flujo actual de compras ya resuelve correctamente la compra inventariable al contado y a credito:

- la entrada de stock se escribe con `StockMovementWriter.recordIngredient` dentro de la transaccion;
- el gasto de contado y el adelanto de credito se registran en `Gastos` y, si hay caja abierta, en `MovimientosCaja`;
- la deuda se registra en `CuentasPorPagar` y sus pagos en `PagosCuentaPorPagar`;
- la edicion y eliminacion usan IDs explicitos y dejan auditoria en `LogAuditoria`.

La compra ocasional puede reutilizar esos mismos efectos financieros, pero **no existe hoy una entidad que represente la compra ocasional completa**. `Gastos` no tiene cantidad, unidad ni una identidad propia de compra; `CuentasPorPagar` solo existe en el caso de credito y no tiene categoria de compra. Sin una entidad cabecera, el historial, la edicion y la eliminacion dependerian de heuristicas por descripcion, monto o categoria, lo que contradice el espiritu de `RN-01` y `RN-02` (vinculos por ID explicito).

**Decision:** se requiere una migracion aditiva **v27** con una tabla cabecera `ComprasOcasionales` y dos columnas de vinculo (`Gastos.compra_ocasional_id` y `CuentasPorPagar.compra_ocasional_id`). No se crea ningun insumo, no se escribe `AjustesStock` y no se modifica `Insumos.stock_actual` para una compra ocasional.

---

## 2. Flujo actual verificado

### 2.1 Formulario y coordinacion

- `lib/screens/compras/compra_form_screen.dart` usa un `DropdownButtonFormField<int>` con todos los insumos activos. El formulario captura fecha, insumo, cantidad, costo total, proveedor, comprobante, nota, contado/credito, adelanto y cuotas.
- La pantalla llama a `ComprasController.registrarCompra` o `ComprasController.corregirCompra`.
- `ComprasController` traduce los textos a numeros y delega en `CompraService`.
- `CompraService` agrega el usuario autenticado y llama a `PurchaseRepository`.
- `PurchaseRepository` es el unico punto que abre transacciones para compras y cuentas por pagar.

### 2.2 Compra al contado

`PurchaseRepository.registrarCompra`:

1. valida cantidad, costo y metodo de pago;
2. llama a `StockMovementWriter.recordIngredient` con `movementType = 'comprado'`; el writer inserta `AjustesStock` y actualiza `Insumos.stock_actual` en la misma transaccion;
3. busca una sesion de caja abierta solo si la fecha del gasto es hoy;
4. inserta un `Gastos` con categoria `Compras`, descripcion `Compra: ...`, `insumo_id`, `compra_movimiento_id` y `sesion_caja_id` si aplica;
5. si hay sesion abierta, inserta `MovimientosCaja` con `tipo = 'compra'` y el `compra_movimiento_id`;
6. registra `AuditLogWriter` con la accion `compra_directa`.

No hay un segundo descuento o incremento de stock fuera de esa transaccion.

### 2.3 Compra a credito

`PurchaseRepository.registrarCompraPorPagar`:

1. valida cantidad, costo, adelanto y cuotas;
2. registra la entrada de stock igual que la compra al contado;
3. inserta `CuentasPorPagar` con `insumo_id`, `cantidad`, `costo_total`, `monto_pagado = adelanto`, `adelanto`, `proveedor`, `motivo`, `factura_ruta`, `cuotas` y `compra_movimiento_id`;
4. si hay adelanto, inserta `PagosCuentaPorPagar` con nota `Adelanto de compra` y llama a `_recordPaymentFinancials`;
5. `_recordPaymentFinancials` inserta un `Gastos` con categoria `Cuentas por Pagar` y, si hay caja abierta, un `MovimientosCaja` con `tipo = 'salida'`; luego actualiza el pago con `gasto_id` y `movimiento_caja_id` exactos;
6. registra auditoria `compra_a_credito`.

La deuda total no se registra como gasto en el momento de la compra: se registra como obligacion. Los pagos (adelanto y abonos posteriores) son los que generan gasto y movimiento de caja. Ese es el comportamiento actual y se conserva para las compras ocasionales a credito.

### 2.4 Edicion y eliminacion

- `corregirCompra` conserva el registro original, registra la diferencia de cantidad como movimiento compensatorio y actualiza gasto, movimiento de caja, cuenta por pagar y adelanto en la misma transaccion.
- `RN-01` exige recalcular `monto_pagado = adelanto_actualizado + SUM(abonos posteriores)` y rechazar `nuevo_total < monto_pagado`.
- `eliminarCompra` revierte stock, elimina pagos, gastos, movimientos, cuenta por pagar y ajustes de stock, siempre por IDs explicitos.
- `eliminarGasto` bloquea gastos de compras (`categoria = 'Compras'`) y gastos de abonos de deuda (`PagosCuentaPorPagar` o categoria `Cuentas por Pagar`). La anulacion de un abono solo se permite desde Cuentas por Pagar.

### 2.5 Gastos y cuentas por pagar

- `Gastos` es la fuente de verdad del egreso. Tiene `fecha`, `categoria`, `descripcion`, `monto`, `foto_recibo_ruta`, `insumo_id`, `activo_fijo_id`, `compra_movimiento_id`, `sesion_caja_id` y `movimiento_caja_id`.
- `CuentasPorPagar` acepta `insumo_id NULL` y `activo_fijo_id NULL` desde la v23. `getCuentasPorPagar` usa `COALESCE(i.nombre, a.nombre, c.motivo, 'Activo/Insumo')`, por lo que una cuenta ocasional puede mostrarse con su `motivo`.
- `getGastosRaw` devuelve todos los gastos para la bandeja generica; la pantalla de Compras alterna entre historial de compras y bandeja de gastos.
- `PagosCuentaPorPagar` guarda `gasto_id`, `movimiento_caja_id` y la nota del pago. La anulacion de un abono usa esos IDs y revierte la deuda.

### 2.6 Reportes, dashboard y caja

- `ReportesRepository.getTotalGastos` suma `Gastos` y excluye exactamente `Compras`, `Activos Fijos` y `Cuentas por Pagar`. Cualquier otra categoria, incluida una categoria ocasional valida, entra en el total.
- `VentaRepository.getResumenHoy` y `DashboardService` suman todos los `Gastos` del dia, sin filtrar categoria.
- `getGastosHoy` hace `LEFT JOIN Insumos` y `LEFT JOIN AjustesStock`; si no hay insumo, la descripcion del gasto sigue siendo visible.
- `CashCloseSummary.calculate` considera salidas los tipos `salida`, `compra` y `gasto`; clasifica efectivo/digital con `CashPaymentMethod`. Una compra ocasional de contado debe usar `tipo = 'salida'` para entrar en el arqueo.
- `CajaRepository._gastosDelCiclo` suma todos los `Gastos` con `sesion_caja_id` de la sesion, sin importar la categoria.

---

## 3. Evaluacion del modelo actual

| Necesidad | Modelo actual | Resultado |
|---|---|---|
| Compra ocasional al contado sin stock | `Gastos` + `MovimientosCaja` | Representable a nivel financiero |
| Compra ocasional a credito sin stock | `CuentasPorPagar` + `PagosCuentaPorPagar` | Representable a nivel de deuda |
| Descripcion, cantidad, unidad, categoria y metodo en una sola identidad | No existe cabecera comun | No representable sin heuristicas |
| Historial que distinga insumo vs ocasional | `AjustesStock` solo contiene insumos | No representable de forma fiable |
| Edicion y eliminacion por ID exacto | No hay ID de compra ocasional | No representable de forma fiable |
| Evitar duplicados de `Gastos`/`MovimientosCaja` | No hay vinculo inverso desde `Gastos` | Riesgo alto |

Alternativas descartadas:

- **Crear un `Insumo` oculto:** viola la regla de no crear inventario y contamina recetas, reportes de stock y busquedas.
- **Usar `ActivosFijos` como cabecera:** mezcla consumibles con activos, exige condicion/estado y altera el modulo de activos.
- **Guardar todo en `Gastos`:** no tiene cantidad/unidad y en credito no existe un gasto por el total de la compra; la edicion obligaria a parsear texto.
- **Guardar solo en `CuentasPorPagar`:** no cubre contado y contamina la bandeja de deudas con compras ya pagadas.

**Conclusion:** la migracion v27 se justifica para cumplir integridad, trazabilidad y edicion/eliminacion exactas.

---

## 4. Esquema propuesto v27

### 4.1 Tabla cabecera

```sql
CREATE TABLE ComprasOcasionales (
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
```

### 4.2 Columnas de vinculo

```sql
ALTER TABLE Gastos
  ADD COLUMN compra_ocasional_id INTEGER REFERENCES ComprasOcasionales(id);

ALTER TABLE CuentasPorPagar
  ADD COLUMN compra_ocasional_id INTEGER REFERENCES ComprasOcasionales(id);
```

- `Gastos.compra_ocasional_id` identifica el gasto de contado y cada gasto de pago de una compra ocasional a credito.
- `CuentasPorPagar.compra_ocasional_id` identifica la deuda de una compra ocasional a credito.
- Ambas columnas son `NULL` para todo el historial existente; no hay backfill ni perdida de datos.

### 4.3 Indices

```sql
CREATE INDEX IF NOT EXISTS IDX_ComprasOcasionales_fecha
  ON ComprasOcasionales(fecha);
CREATE INDEX IF NOT EXISTS IDX_Gastos_compra_ocasional
  ON Gastos(compra_ocasional_id);
CREATE INDEX IF NOT EXISTS IDX_CuentasPorPagar_compra_ocasional
  ON CuentasPorPagar(compra_ocasional_id);
```

La v27 queda con **38 tablas, 28 indices `IDX_*` y 4 triggers**, manteniendo `PRAGMA foreign_key_check` en 0 filas.

### 4.4 Migracion y creacion canonica

- `DatabaseHelper.databaseVersion = 27`.
- `DbSchema.initialTables` incluye `createComprasOcasionales` antes de `createGastos` y `createCuentasPorPagar`.
- `DbSchema.createGastos` y `DbSchema.createCuentasPorPagar` incluyen `compra_ocasional_id`.
- `DbSchema.indexesV27` contiene los tres indices; `_createDB` los ejecuta.
- `upgradeDatabase`: si `oldVersion < 27`, crea la tabla, agrega las dos columnas con `_ensureColumn` y crea los indices.
- No se modifica `AjustesStock` ni `Insumos`.
- `test/schema_equivalence_test.dart` se actualiza a v27 y a los nuevos conteos; se agrega `test/migracion_v27_test.dart` con una base v26 que migra sin perder filas y con `foreign_key_check` limpio.

---

## 5. Flujos transaccionales propuestos

### 5.1 Compra ocasional al contado

Todo dentro de `db.transaction`:

1. Validar descripcion no vacia, cantidad > 0, costo > 0, categoria permitida y metodo de pago oficial.
2. Insertar la cabecera `ComprasOcasionales`.
3. Resolver la sesion de caja abierta solo si la fecha operativa es hoy, igual que la compra inventariable.
4. Insertar `Gastos`:
   - `fecha` en formato dia;
   - `created_at`;
   - `categoria` elegida por el usuario (validada para no usar una categoria reservada de reportes);
   - `descripcion` estructurada: `Compra ocasional - <categoria>: <descripcion> (<cantidad> <unidad>)`;
   - `monto = costo_total`;
   - `foto_recibo_ruta`, `usuario_id`, `sesion_caja_id`;
   - `compra_ocasional_id = cabecera.id`.
5. Si hay sesion abierta, insertar `MovimientosCaja` con `tipo = 'salida'`, `metodo_pago`, `monto`, `descripcion` y `fecha`; luego actualizar `Gastos.movimiento_caja_id` con el ID exacto.
6. Registrar `AuditLogWriter` con `compra_ocasional_registrada`.
7. No llamar a `StockMovementWriter`, no insertar `AjustesStock`, no actualizar `Insumos`.

### 5.2 Compra ocasional a credito

1. Validar `adelanto` entre 0 y `costo_total`, `cuotas >= 1` y metodo de pago si hay adelanto.
2. Insertar la cabecera.
3. Insertar `CuentasPorPagar` con:
   - `insumo_id = NULL`, `activo_fijo_id = NULL`, `compra_movimiento_id = NULL`;
   - `cantidad`, `costo_total`, `monto_pagado = adelanto`, `adelanto`, `cuotas`;
   - `proveedor`, `proveedor_id`, `factura_ruta`;
   - `motivo` estructurado con la descripcion ocasional;
   - `compra_ocasional_id = cabecera.id`.
4. Si `adelanto > 0`, insertar `PagosCuentaPorPagar` con nota `Adelanto de compra` y llamar a `_recordPaymentFinancials` con `compraOcasionalId` y la categoria ocasional. El helper existente debe aceptar esos dos datos opcionales; su comportamiento por defecto no cambia para compras normales.
5. Registrar auditoria.
6. No tocar stock.

Los abonos posteriores usan `aplicarPago`. Antes de crear el gasto, `aplicarPago` consulta `ComprasOcasionales` por `cuenta_id`; si existe, pasa `compraOcasionalId` y la categoria ocasional a `_recordPaymentFinancials`. Asi los pagos de una compra ocasional tambien aparecen en gastos y reportes, sin duplicar la deuda.

### 5.3 Edicion

`corregirCompraOcasional` recibe el ID de la cabecera y actualiza, en una sola transaccion:

- cabecera: fecha, descripcion, cantidad, unidad, costo, categoria, proveedor, comprobante, metodo y cuotas;
- si es contado: `Gastos` y `MovimientosCaja` vinculados por ID exacto; si cambia la fecha, se reasigna la sesion solo bajo las mismas reglas actuales;
- si es credito: `CuentasPorPagar`, adelanto y abonos posteriores;
- recalcula `monto_pagado = adelanto_actualizado + SUM(abonos posteriores)`;
- rechaza la operacion si `nuevo_total < monto_pagado`;
- si el adelanto cambia de 0 a positivo o viceversa, crea o elimina exactamente el pago, gasto y movimiento del adelanto, sin duplicar;
- registra auditoria `compra_ocasional_corregida`.

**Alcance de la primera entrega:** no se permite convertir una compra ocasional de contado a credito ni viceversa si ya existen pagos. La UI lo bloquea con un mensaje de negocio. La conversion completa queda como mejora posterior para no reescribir deuda con abonos sin una regla aprobada.

### 5.4 Eliminacion

`eliminarCompraOcasional(id)`:

1. carga la cabecera y sus vinculos;
2. elimina primero los hijos: `PagosCuentaPorPagar` (si es credito), luego `Gastos`, luego `MovimientosCaja` y luego `CuentasPorPagar`;
3. elimina la cabecera;
4. registra auditoria `compra_ocasional_eliminada`;
5. no revierte stock porque nunca lo modifico.

`eliminarGasto` debe bloquear cualquier `Gastos` con `compra_ocasional_id` no nulo y remitir al modulo de Compras. La anulacion de un abono de una compra ocasional sigue usando `anularPagoCuentaPorPagar`; como la nota del adelanto sigue siendo `Adelanto de compra`, la logica existente repone `adelanto = 0` y conserva la cabecera y la deuda restante.

### 5.5 Historial y bandeja de gastos

- `PurchaseRepository` expone `getComprasOcasionales` con la cabecera y los datos de deuda/pago.
- `CompraService.obtenerHistorialCompras` combina compras inventariables y ocasionales, ordena por fecha descendente y devuelve una lista unica.
- `Compra` agrega `esOcasional` y `compraOcasionalId` para que la tarjeta muestre un distintivo y el boton editar/eliminar sepa a que caso de uso llamar.
- `getGastosRaw` excluye `Gastos` con `compra_ocasional_id` no nulo para no duplicar la compra ocasional en la bandeja generica. Los gastos ocasionales siguen existiendo para caja, dashboard y reportes.
- La tarjeta de historial ocasional muestra `descripcion`, cantidad/unidad, categoria, proveedor, comprobante y estado de pago. No muestra stock ni "reversion de stock".

### 5.6 Caja, reportes y cuentas por pagar

- **Caja:** la compra de contado usa `tipo = 'salida'` y la sesion abierta; `CashCloseSummary` ya la incluye. El adelanto de credito usa el mismo camino de `_recordPaymentFinancials`.
- **Reportes:** la categoria ocasional se valida para no ser `Compras`, `Activos Fijos` o `Cuentas por Pagar`; de ese modo `getTotalGastos` la incluye. No se agrega una formula nueva de reportes.
- **Dashboard:** `getGastosHoy` ya tolera `insumo_id NULL` y muestra la descripcion; no requiere cambio de calculo.
- **Cuentas por pagar:** `getCuentasPorPagar` ya usa `motivo` como nombre cuando no hay insumo ni activo. Se agrega `compra_ocasional_id` al modelo para mostrar el distintivo "Compra ocasional" en la pantalla de deudas.

---

## 6. Fase 2: busqueda de insumos

### 6.1 UI propuesta

Reemplazar el `DropdownButtonFormField<int>` de insumos por un campo de busqueda con sugerencias:

- `RawAutocomplete<Insumo>` o un `Autocomplete<Insumo>` con `optionsViewBuilder` propio.
- Estado: `_insumoSeleccionadoId`, `_busquedaInsumoCtrl`, `_focusInsumo`.
- Al escribir, filtrar en memoria `InsumoController.insumos` por nombre, tipo y unidad, sin distinguir mayusculas/minusculas; mostrar como maximo 8-12 coincidencias.
- Al seleccionar, fijar `_insumoSeleccionadoId` y ocultar sugerencias. El guardado sigue usando exactamente el mismo camino actual.
- En edicion, precargar el nombre del insumo actual; si ya no esta activo, mostrar el texto y permitir buscar otro.
- Mantener el boton `+` para crear un insumo y, al volver, recargar y seleccionar el mas reciente.
- Si la busqueda no tiene coincidencias, mostrar una accion clara: **"Registrar como compra ocasional"**.

No se agrega SQL ni se modifica el repositorio de insumos: el catalogo activo ya se carga en `InsumoController`.

### 6.2 Limite de la fase

La Fase 2 no cambia la persistencia. La accion "Registrar como compra ocasional" abre `CompraOcasionalFormScreen` en modo borrador: los campos se capturan, pero el boton Guardar queda deshabilitado con el aviso "Disponible al completar la Fase 3". No se crea ningun registro ocasional todavia.

### 6.3 Pruebas

- Un test unitario del filtro de busqueda (nombre, tipo, unidad, sin coincidencias).
- Un widget test del campo: escribir, seleccionar una coincidencia y verificar que se conserva el insumo seleccionado.
- Un widget test del estado sin coincidencias: aparece la accion "Registrar como compra ocasional".
- La suite existente de compras debe seguir pasando sin cambios.

---

## 7. Fase 3: persistencia de compras ocasionales

### 7.1 Archivos previstos

- `lib/core/database/db_schema.dart`
- `lib/core/database/database_helper.dart`
- `lib/features/purchases/domain/entities/compra_ocasional.dart`
- `lib/features/purchases/domain/rules/occasional_purchase_rules.dart`
- `lib/features/purchases/data/repositories/purchase_repository.dart`
- `lib/features/purchases/application/compra_service.dart`
- `lib/features/purchases/presentation/controllers/compras_controller.dart`
- `lib/screens/compras/compra_ocasional_form_screen.dart`
- `lib/models/cuenta_por_pagar.dart` (campo opcional `compraOcasionalId`)
- `test/compras_ocasionales_fase3_test.dart`
- `test/migracion_v27_test.dart`
- `test/schema_equivalence_test.dart` y conteos de `test/phase3_sqlite_consolidation_test.dart`

### 7.2 Pruebas obligatorias

1. Contado con caja abierta: crea cabecera, un `Gastos`, un `MovimientosCaja`; no crea `AjustesStock`; no cambia `Insumos.stock_actual`.
2. Contado sin caja abierta: crea cabecera y `Gastos` sin movimiento; al abrir una sesion del dia, el gasto se asigna a la sesion segun la logica existente.
3. Credito sin adelanto: crea cabecera y `CuentasPorPagar` con `insumo_id`, `activo_fijo_id` y `compra_movimiento_id` nulos; no crea gasto ni movimiento.
4. Credito con adelanto: crea un solo pago, un solo gasto y un solo movimiento; `monto_pagado` coincide con el adelanto.
5. Abono posterior: actualiza el saldo y crea exactamente un gasto y un movimiento, vinculados a la compra ocasional.
6. Edicion con abonos: recalcula el saldo y no duplica filas; `nuevo_total < monto_pagado` se rechaza.
7. Edicion del adelanto: actualiza el gasto/movimiento existente por ID; no crea duplicados.
8. Eliminacion de contado y de credito: borra cabecera, gastos, movimientos, pagos y cuenta por pagar en el orden correcto; auditoria presente.
9. `eliminarGasto` bloquea un gasto ocasional y remite a Compras.
10. Anulacion del adelanto desde CxP: repone `adelanto = 0`, conserva la cabecera y la deuda restante.
11. Reportes: una compra ocasional aparece en `getTotalGastos` y no se excluye por categoria.
12. Caja: el arqueo incluye la salida ocasional en efectivo/digital.
13. Migracion v26 -> v27: filas existentes intactas, columnas nuevas en `NULL`, `foreign_key_check` en 0.
14. Equivalencia de esquema: base nueva v27 vs base v26 migrada a v27, mismas tablas, columnas, indices y triggers.

---

## 8. Fase 4: integracion y experiencia de usuario

- Punto de entrada "Nueva compra" con dos modalidades claras: **Insumo inventariable** y **Compra ocasional**. Puede ser una pantalla de seleccion o un selector en el flujo; la compra ocasional no debe presentarse como insumo con stock.
- Formulario ocasional con descripcion, cantidad, unidad opcional, costo, categoria, fecha, proveedor, comprobante, metodo de pago, credito, adelanto y cuotas.
- Confirmaciones breves y errores de negocio comprensibles.
- Historial con distintivo "Compra ocasional", sin acciones de stock.
- Edicion y eliminacion de la compra ocasional desde el historial, con confirmacion que no mencione reversion de stock.
- Cuentas por pagar con distintivo de compra ocasional y descripcion legible.
- Bandeja generica de gastos sin filas duplicadas de compras ocasionales.
- No se agrega "Crear como insumo" en esta fase: mezclaria el registro ocasional con inventario. Si se evalua despues, debe ser una accion explicita que cree un insumo y convierta la compra, con migracion de vinculos y auditoria.

---

## 9. Riesgos y mitigaciones

| Riesgo | Mitigacion |
|---|---|
| Deriva de esquema entre base nueva y migrada | Actualizar `DbSchema`, `onUpgrade`, `schema_equivalence_test` y agregar `migracion_v27_test` |
| Duplicar `Gastos` o `MovimientosCaja` | Una sola transaccion, IDs exactos, `_isLoading` en controlador y pruebas de doble envio |
| Borrar una compra ocasional desde la bandeja generica | `eliminarGasto` bloquea `compra_ocasional_id` no nulo y remite a Compras |
| Deuda con abonos inconsistente | Recalcular `monto_pagado` con la suma real; rechazar total menor al pagado; no permitir conversion de modalidad en v1 |
| Orden de borrado con foreign keys | Pagos -> gastos -> movimientos -> cuenta por pagar -> cabecera; probar con `foreign_key_check` |
| Gasto ocasional fuera del arqueo | Usar `tipo = 'salida'` y `sesion_caja_id`; probar efectivo y digital |
| Categoria ocasional excluida de reportes | Validar que no sea `Compras`, `Activos Fijos` o `Cuentas por Pagar`; probar `getTotalGastos` |
| Compra ocasional invisible en deudas | Usar `motivo` descriptivo y `compra_ocasional_id`; probar `getCuentasPorPagar` |
| Jornada despues de medianoche | Reutilizar la regla actual de sesion activa y fecha operativa; no crear una jornada paralela |
| Perdida de datos por migracion | Migracion aditiva, columnas nullable, sin backfill destructivo, prueba de filas existentes |

---

## 10. Verificacion de cierre de la Fase 1

Comandos ejecutados en el estado actual del repositorio, sin implementar aun la mejora:

```powershell
flutter test --no-pub
flutter analyze --no-pub
```

Resultados:

- `flutter test --no-pub`: **167/167 pruebas aprobadas** (`All tests passed!`).
- `flutter analyze --no-pub`: **0 issues** (`No issues found!`, 86.0 s).

No se modifico codigo de produccion en esta fase. El arbol de trabajo conserva los cambios previos de las fases ya cerradas; esta fase solo agrega este documento.
