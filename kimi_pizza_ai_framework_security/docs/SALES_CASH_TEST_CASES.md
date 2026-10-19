# Casos de prueba — Ventas, Pagos y Caja

## Venta normal

1. Abrir caja.
2. Seleccionar un producto preparado.
3. Agregar 2 unidades.
4. Cambiar temporalmente el precio.
5. Cobrar en efectivo.
6. Introducir monto suficiente.
7. Verificar vuelto.
8. Confirmar venta.

Esperado: una sola venta, precio histórico correcto, caja actualizada, disponibilidad/stock actualizado una sola vez y boleta persistida.

## Pago en efectivo sin monto recibido

Esperado: se permite si el negocio lo contempla; no mostrar vuelto porque `Se pagó con` quedó vacío.

## Pago insuficiente

Introducir monto menor al total.

Esperado: impedir cobro y mostrar validación.

## Yape/Plin

Seleccionar Yape/Plin.

Esperado: aparece el QR configurado por administrador, puede ampliarse, no se modifica la configuración y la venta queda registrada como transferencia.

## Sin QR configurado

Intentar pagar con Yape/Plin sin QR.

Esperado: mensaje claro y bloqueo del paso que requiera QR hasta que exista una configuración válida.

## Precio especial

Producto base S/ 25; venta S/ 20.

Esperado: `SaleItem.unitPrice = 20`; producto sigue en S/ 25.

## Bebida de cortesía

Agregar una bebida marcada como cortesía.

Esperado: precio 0, línea registrada, consumo de recurso correcto y caja sin incremento por esa línea.

## Carrito múltiple

Agregar producto A, producto B y producto C.

Esperado: un único cobro consolidado; no crear pagos parciales por accidente.

## Doble toque en Cobrar

Presionar Cobrar repetidamente mientras procesa.

Esperado: una sola operación persistida.

## Error de PDF después del cobro

Simular fallo de generación/guardado del PDF después de que la venta ya fue persistida.

Esperado: no duplicar la venta al reintentar; marcar el documento para recuperación.

## Historial

Consultar hoy, ayer, semana pasada, mensual e historial.

Esperado: los filtros usan la fecha correcta de la venta.

## Caja normal

Abrir caja, registrar efectivo, registrar Yape/Plin, registrar gasto, hacer arqueo y cerrar.

Esperado: balance y diferencia correctos.

## Cierre a las 00:30

Abrir 01/10 y cerrar 02/10 a las 00:30.

Esperado: el ciclo operativo sigue siendo el iniciado el 01/10.

## Reapertura excepcional

Con caja cerrada, intentar vender.

Esperado: bloqueo hasta autorización. Registrar apertura excepcional, usuario, fecha/hora y motivo.

## Doble cierre

Presionar Cerrar caja dos veces.

Esperado: una sola sesión cerrada.
