# Activos y cuentas por pagar: flujo, reglas de negocio y límites

## Arquitectura aplicada

Activos vive en `lib/features/assets` con entidad y reglas en `domain`, coordinación en `application`, persistencia en `data` y UI/estado en `presentation`. Cuentas por pagar vive en `lib/features/purchases`; el saldo y la regla de abono están en `domain`, con un caso de uso y un contrato de repositorio. Los archivos de las rutas globales anteriores quedan como exportaciones de compatibilidad mientras se migra el resto de la app.

## Activos (`BR-AST`)

- Las categorías iniciales incluyen Maquinaria, Muebles, Tecnología, Vehículos, Electrodomésticos y Otros. La inicialización crea las categorías faltantes sin duplicar las ya existentes.
- Las adquisiciones válidas son comprado, alquilado, prestado y regalado. La base nueva y las reglas del caso de uso validan esas opciones.
- Un regalo o préstamo no crea egreso ni movimiento de caja. Alquilar registra el costo ingresado como egreso de alquiler; la aplicación no crea cobros periódicos automáticos.
- Una compra a contado genera egreso y movimiento de caja. Una compra al crédito crea una cuenta única por el costo total, conserva adelanto y número de cuotas, y enlaza los pagos con el activo.
- **Integridad referencial (`C-07` / `C-09`):** Los activos no se registran como insumos y nunca alteran el stock de ingredientes. En `CuentasPorPagar`, un activo fijo comprado a crédito debe almacenar `insumo_id = NULL` y `activo_fijo_id` apuntando al activo (prohibido usar el valor centinela `insumo_id = 0`).
- Reparaciones, cambios de estado, registro y baja lógica generan auditoría; reparación, egreso y movimiento de caja se guardan juntos. En `AssetController`, el estado `_isLoading` debe restablecerse siempre dentro de un bloque `finally` (`C-29`).
- `Total invertido` suma activos comprados; no suma préstamos, regalos ni alquileres.

## Compras, edición y cuentas por pagar (`RN-01`, `RN-02` / `C-01`, `C-02`)

- La compra de insumo, su movimiento de stock, gasto, movimiento de caja cuando existe una sesión abierta y auditoría se guardan en una sola transacción.
- Las compras a crédito guardan total, adelanto, método del adelanto, cantidad de cuotas y saldo. Cada abono crea un registro en `PagosCuentaPorPagar` con fecha, importe, método y nota, enlazado por ID explícito a `Gastos` y a `MovimientosCaja`.
- **Edición de compra a crédito con abonos previos (`RN-01` / `C-01`):**
  - Se permite corregir una compra a crédito que ya tenga abonos en `PagosCuentaPorPagar`, recalculando siempre `monto_pagado = adelanto_actualizado + SUM(PagosCuentaPorPagar)` y `saldo_pendiente = nuevo_total - monto_pagado`.
  - Si `nuevo_total < monto_pagado`, la operación se rechaza con excepción de negocio.
  - Al editar el adelanto inicial, nunca se duplica el registro en `Gastos` ni en `MovimientosCaja`; se ajusta únicamente la diferencia sobre el registro vinculado por ID.
- **Bloqueo de eliminación directa de gastos vinculados (`RN-02` / `C-02`):**
  - Queda bloqueada la eliminación desde la bandeja genérica de Gastos para cualquier registro originado por una compra o por un abono de `CuentasPorPagar`.
  - La anulación de un abono solo puede ejecutarse desde el módulo de **Cuentas por Pagar**, revirtiendo atómicamente la deuda en `CuentasPorPagar`, el abono en `PagosCuentaPorPagar`, el `Gasto` y el `MovimientoCaja` mediante IDs explícitos (prohibido borrar `MovimientosCaja` por coincidencia difusa de monto/fecha).
- Las deudas antiguas con `monto_pagado` se migran como un único pago legado. No se inventan fechas, métodos ni abonos históricos que la base anterior no conservaba.
- La caja solo recibe el movimiento cuando hay una sesión abierta. Si se registra un gasto fuera de una sesión, el gasto y la deuda quedan guardados, pero no se atribuyen a un cierre de caja.
