# Flujo de ventas

## Venta normal

1. Abrir módulo de ventas.
2. Filtrar categorías o promociones.
3. Seleccionar producto.
4. Abrir modal.
5. Mostrar imagen, precio editable, cantidad y subtotal.
6. Agregar al carrito.
7. Seleccionar otros productos si corresponde.
8. Calcular total.
9. Presionar cobrar.
10. Seleccionar efectivo o Yape/Plin.
11. Validar operación.
12. Registrar venta.
13. Registrar método de pago.
14. Consumir disponibilidad/preparación/inventario según reglas.
15. Actualizar caja.
16. Generar boleta PDF.
17. Guardar PDF.
18. Mostrar confirmación sonora/visual.

## Precio personalizado

El precio editable aplica solo a la línea de venta. No modifica el catálogo.

## Efectivo

`Se pagó con` es opcional.

Si existe monto recibido:
vuelto = monto recibido - total.

Si no existe monto recibido, no mostrar vuelto.

## Yape/Plin

La imagen QR proviene de configuración administrativa. El vendedor no debe volver a seleccionarla en cada venta.

## Cortesías

Una bebida marcada como cortesía:
- precio de venta = 0 para el cobro;
- queda registrada;
- consume la existencia correspondiente;
- se sirve en vaso según regla de capacidad/rendimiento.

## Historial

El historial debe permitir consultar hoy, ayer, semana pasada, mensual e histórico, y acceder a la boleta persistida.

## Ventas anteriores

Permite registrar ventas de fechas anteriores. El precio es editable para esa operación y no afecta el precio base.
