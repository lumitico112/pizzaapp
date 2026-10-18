# KIMI PIZZA — Casos de prueba: compras, proveedores, cuentas por pagar, activos, mermas y reportes

## Compras

### TC-01 Compra de insumo pagada
Dado un insumo existente.
Registrar 10 unidades por S/ 50.
Esperado:
- una compra;
- costo unitario S/ 5;
- stock +10;
- sin cuenta por pagar.

### TC-02 Doble toque en guardar compra
Pulsar Guardar dos veces rápidamente.
Esperado: una sola compra y un solo movimiento de stock.

### TC-03 Compra a crédito con adelanto
Total S/ 100, adelanto S/ 20.
Esperado: saldo S/ 80.

### TC-04 Compra a crédito sin adelanto
Total S/ 100, adelanto vacío/0.
Esperado: saldo S/ 100.

### TC-05 Compra de activo relacionada
Registrar activo comprado por S/ 1,000 desde una compra.
Esperado: una compra, un activo relacionado, costo S/ 1,000 y no una segunda compra duplicada.

### TC-06 Fecha histórica
Registrar compra con fecha anterior seleccionada en calendario.
Esperado: fecha operativa correcta y fecha técnica conservada según arquitectura.

## Proveedores

### TC-07 Proveedor nuevo
Registrar proveedor válido.
Esperado: aparece una sola vez.

### TC-08 Proveedor duplicado
Intentar registrar el mismo proveedor.
Esperado: mensaje “El proveedor ya existe.” y no se crea duplicado.

### TC-09 Proveedor usado en historial
Intentar eliminar proveedor con compras históricas.
Esperado: no romper referencias; desactivar o impedir eliminación según reglas.

## Cuentas por pagar

### TC-10 Pago parcial
Deuda S/ 100, aplicar S/ 30.
Esperado: estado parcialmente pagada y saldo S/ 70.

### TC-11 Pago total
Deuda S/ 100, aplicar S/ 100.
Esperado: estado pagada y saldo 0.

### TC-12 Sobrepago
Intentar aplicar pago mayor al saldo.
Esperado: rechazo o control explícito; nunca saldo negativo accidental.

## Activos

### TC-13 Activo en uso
Cambiar estado a En uso.
Esperado: estado persistido y visualización verde usando token de diseño.

### TC-14 Activo en reparación
Esperado: visualización amarilla.

### TC-15 Activo fuera de servicio
Esperado: visualización roja.

### TC-16 Alquiler anual
Seleccionar alquilado + anual.
Esperado: opción anual disponible y costo/periodicidad correctos.

## Mermas

### TC-17 Merma de insumo
Stock 10, merma 3.
Esperado: stock 7, una merma, un movimiento asociado.

### TC-18 Merma superior al stock
Stock 2, merma 3.
Esperado: rechazo o flujo de autorización/ajuste explícito; nunca stock negativo accidental.

### TC-19 Merma desde insumo y desde módulo merma
Registrar desde un origen y verificar en módulo de mermas.
Esperado: un único registro de dominio, no duplicado.

### TC-20 Sobrante no es merma
Preparar 10, vender 7, conservar 3 para mañana.
Esperado: disponibilidad trasladable, sin registro de merma.

### TC-21 Sobrante convertido en merma
De las 3 restantes, registrar 3 como merma.
Esperado: disponibilidad utilizable 0 y una merma de 3.

## Reportes

### TC-22 Compra reflejada
Registrar compra.
Esperado: reporte de compras se actualiza sin cálculo paralelo.

### TC-23 Stock reflejado
Registrar compra y merma.
Esperado: reporte de inventario coincide con movimientos.

### TC-24 Cuenta por pagar reflejada
Registrar compra a crédito y pago parcial.
Esperado: reporte muestra original, pago y saldo correctos.

### TC-25 Reporte de mermas
Registrar mermas de distintos motivos.
Esperado: filtros y totales coinciden con registros.

### TC-26 Activos
Registrar activos de diferentes condiciones.
Esperado: reporte lista adquisición, fecha, costo y estado correctamente.

## Regresión transversal

### TC-27 Compra → inventario → preparación → venta
Registrar compra de insumo suficiente para una preparación, preparar, vender.
Esperado: cada transición ocurre una sola vez y no hay doble descuento.

### TC-28 Compra a crédito → caja
Registrar compra a crédito con adelanto.
Esperado: la lógica de caja y cuentas por pagar distingue el pago realizado del saldo pendiente.

### TC-29 Reintento después de error de red
Guardar una compra, simular timeout y reintentar.
Esperado: no duplicar transacciones si el backend dispone de idempotencia.

### TC-30 Corrección/anulación
Anular una operación según permisos.
Esperado: mantener trazabilidad y aplicar movimiento compensatorio si corresponde; no editar silenciosamente el historial.
