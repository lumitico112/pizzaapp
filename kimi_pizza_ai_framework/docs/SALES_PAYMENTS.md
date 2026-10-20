# KIMI PIZZA — Reglas críticas de Ventas y Pagos

## 1. Objetivo

Definir una única fuente de verdad y un flujo consistente para seleccionar productos, editar precios de una venta, usar carrito, aplicar promociones y cortesías, cobrar, registrar el método de pago, actualizar inventario, generar la boleta y alimentar caja/reportes.

## 2. Entidades principales

- `Sale`: cabecera de venta.
- `SaleItem`: línea de venta.
- `Payment`: pago asociado a una venta.
- `Product`: producto comercial.
- `ProductVariant`: variante comercial cuando corresponda.
- `Promotion`: agrupación/oferta comercial.
- `PreparationAvailability`: disponibilidad preparada para el ciclo/día.
- `ReceiptDocument`: documento PDF generado y persistido.

No crear otra entidad que represente la misma venta o el mismo pago sin una razón arquitectónica documentada.

## 3. Carrito

La venta normal debe seguir:

`Selección -> modal -> cantidad/precio -> agregar -> carrito -> cobrar`.

Cada `SaleItem` debe conservar al menos:
- producto/variante o promoción de origen;
- cantidad;
- precio unitario aplicado en esa venta;
- subtotal;
- indicador de cortesía cuando corresponda;
- referencia suficiente para auditoría.

El precio editado en una venta es un **snapshot del precio aplicado a esa operación**. Nunca debe modificar el precio base de `Product` o `ProductVariant`.

## 4. Precio editable

El vendedor puede vender a un precio distinto al precio habitual.

Ejemplo:
- precio base: S/ 25;
- precio de esta venta: S/ 20.

Persistir S/ 20 en `SaleItem.unitPrice` y conservar el precio base de catálogo sin modificaciones.

## 5. Cantidad y subtotal

`subtotal = cantidad * precioUnitarioAplicado`.

La cantidad debe validarse según la unidad y disponibilidad vendible.

Los importes monetarios deben manejarse con una estrategia consistente que evite errores de coma flotante. La lógica monetaria debe estar centralizada.

## 6. Promociones

Una promoción es una entidad comercial independiente.

Puede incluir productos e insumos según las reglas definidas para KIMI PIZZA.

El precio de una promoción debe aplicarse a la operación sin sobrescribir el precio base de los componentes de catálogo.

La aplicación debe impedir inconsistencias como cobrar dos veces un componente incluido en una promoción.

## 7. Bebidas de cortesía

Cuando un producto de la categoría Bebidas tenga habilitada la modalidad `De cortesía`:

- el precio cobrado es 0;
- la línea debe permanecer registrada en la venta;
- no debe alterar el precio normal del producto;
- debe registrar que fue cortesía;
- debe consumir el recurso correspondiente según la regla de inventario;
- la entrega de cortesía corresponde al vaso, no a la venta de una botella completa al cliente.

La UI debe distinguir claramente una bebida normal de una cortesía.

### Bebida vendida por vaso

La variante de categoría Bebidas cuyo nombre incluye `Vaso` representa una porción vendible, no una botella completa. Su receta por unidad debe contener el volumen servido en ml/litros y el insumo del vaso. La venta normal y la cortesía consumen ambos componentes desde la receta; no dependen del stock de producto preparado. Si falta volumen o vaso en la receta, el cobro debe rechazarse antes de confirmar inventario.

Si el insumo del vaso se compra por paquetes, `contenido_paquete` define cuántas unidades contiene. La receta usa una unidad y el conversor lo transforma a fracción de paquete.

## 8. Validación antes de cobrar

Antes de confirmar una venta:
1. validar que exista una sesión de caja abierta;
2. validar autenticación/autorización;
3. validar carrito no vacío;
4. validar cantidades válidas;
5. validar precios válidos;
6. validar disponibilidad vendible/stock según el modelo de preparación;
7. validar método de pago;
8. validar que no exista un doble envío de la operación.

## 9. Efectivo

Si el método es efectivo:

- mostrar `Se pagó con` como campo opcional;
- si el usuario introduce un monto, calcular `vuelto = pago - total`;
- si no introduce monto, no mostrar vuelto;
- si el pago introducido es menor al total, impedir el cobro y mostrar validación clara;
- registrar el monto recibido cuando exista;
- alimentar automáticamente las ventas en efectivo de caja.

## 10. Yape/Plin

Yape y Plin se manejan bajo un único método visible: `Yape/Plin`.

Al seleccionarlo:
- mostrar el QR configurado por un administrador;
- permitir ampliar el QR;
- no pedir al vendedor que seleccione nuevamente la imagen;
- registrar el método de pago;
- registrar el total transferido en la venta.

Si no existe QR configurado, el sistema debe informar la situación y no inventar una imagen.

## 11. Atomicidad lógica del cobro

El cobro debe comportarse como una única operación de negocio:

`validar -> registrar venta -> registrar pago -> consumir disponibilidad/stock -> actualizar caja -> generar/persistir boleta -> confirmar`.

Si una etapa crítica falla, la aplicación no debe dejar una venta parcialmente registrada como si estuviera completa.

Cuando la arquitectura lo permita, las operaciones persistentes deben utilizar transacciones en backend/base de datos.

## 12. Doble cobro / doble tap

El botón `Cobrar` debe entrar en estado de envío y bloquear acciones repetidas hasta recibir resultado.

También debe existir protección de idempotencia en backend cuando corresponda.

## 13. PDF de boleta

Una venta cobrada correctamente debe generar un PDF de boleta.

El documento debe:
- guardar su referencia persistente;
- quedar asociado a la venta;
- poder visualizarse después;
- poder descargarse según la plataforma;
- no depender exclusivamente de un archivo temporal.

Si generar el PDF falla después de registrar una venta, el sistema debe conservar la venta y marcar el estado documental para reintento o recuperación, en lugar de duplicar la venta.

Cuando el precio final incluye IGV al 18 %, el PDF presenta el subtotal con IGV incluido, base imponible e IGV desglosado (`IGV = total × 18 / 118`). Para pagos en efectivo con monto recibido, muestra `Pago con` y `Vuelto`; si el campo quedó vacío, no inventa un importe recibido ni un vuelto.

## 14. Historial

El módulo debe permitir consultar:
- hoy;
- ayer;
- semana pasada;
- mensual;
- historial.

Los filtros deben representar la fecha de la venta, no la fecha del último acceso.

Cada venta histórica debe poder abrir su boleta persistida.

## 15. Ventas anteriores

El registro de ventas anteriores sirve para completar histórico sin alterar el catálogo actual.

Debe permitir:
- seleccionar fecha histórica;
- seleccionar productos/variantes;
- registrar cantidades;
- registrar el precio histórico aplicado.

La operación debe identificarse como histórica/retroactiva cuando el modelo lo requiera para auditoría.

No debe modificar preparaciones de días presentes de forma accidental.

Tampoco mueve la caja operativa actual. Sus importes alimentan el reporte por
fecha y el ajuste histórico del ciclo cerrado correspondiente; el arqueo de ese
ciclo conserva su cierre original y muestra el ajuste por separado (ver
`CASH_FLOW.md`, sección 14).

## 16. Preparación y ventas

La venta consume la disponibilidad preparada según el modelo de dominio documentado en `PRODUCT_RECIPES_INVENTORY_PREPARATION.md`.

No volver a descontar la receta completa en la venta si esa receta ya fue consumida al preparar.

Las transformaciones deben ser consumidas desde la misma disponibilidad lógica, evitando duplicación.

## 17. Impacto en caja

Cada venta confirmada debe alimentar:
- ventas en efectivo, si aplica;
- ventas Yape/Plin, si aplica;
- total vendido;
- reportes.

Una venta cancelada o fallida no debe aparecer como cobrada.

## 18. Estados recomendados

La venta debería manejar estados explícitos, por ejemplo:
- `draft` o carrito local;
- `processing`;
- `completed`;
- `cancelled`;
- `failed` cuando exista un intento no completado.

No representar estados críticos solo con booleanos dispersos si una máquina de estados más clara es necesaria.

## 19. Auditoría

Para modificaciones sensibles conservar, según backend:
- usuario;
- fecha/hora;
- precio base y aplicado cuando sea relevante;
- método de pago;
- cambios manuales;
- motivo de precio especial cuando el negocio lo requiera.

## 20. Criterios de aceptación

Una venta normal debe:
- agregarse al carrito;
- permitir precio especial sin cambiar catálogo;
- cobrar en efectivo o Yape/Plin;
- actualizar caja;
- actualizar disponibilidad/stock una sola vez;
- generar y guardar boleta;
- aparecer en historial.

Una cortesía debe:
- cobrar S/ 0;
- quedar registrada;
- descontar el recurso correcto;
- no modificar el precio base.

Un doble tap no debe crear dos ventas.
