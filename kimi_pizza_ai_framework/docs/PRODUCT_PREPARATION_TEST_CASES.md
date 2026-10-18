# KIMI PIZZA — Casos de prueba de Productos, Recetas, Insumos y Preparación

## A. Recetas

| ID | Caso | Esperado |
|---|---|---|
| REC-01 | Agregar insumo nuevo | Se agrega una sola vez |
| REC-02 | Agregar mismo insumo | Se rechaza con mensaje claro |
| REC-03 | Receta usa 100 g y stock está en kg | Consumo interno = 0.1 kg |
| REC-04 | Receta usa 250 ml y stock está en L | Consumo interno = 0.25 L |
| REC-05 | Paquete de 50; receta usa 5 unidades | El movimiento descuenta 0.1 paquete del stock configurado en paquetes |
| REC-06 | Dos variantes usan los mismos insumos y cantidades diferentes | Cada receta mantiene su cantidad por `variante_id` |
| REC-07 | Vender variante `Vaso` con receta sin volumen o sin vaso | La operación se rechaza antes de completar el cobro |

## B. Compras e inventario

| ID | Caso | Esperado |
|---|---|---|
| INV-01 | Comprar 10 kg | Stock aumenta 10 kg |
| INV-02 | Comprar 2 paquetes de 50 | Stock aumenta 2 paquetes (equivalentes a 100 unidades) |
| INV-03 | Reintentar guardar compra | No crea segunda entrada |
| INV-04 | Compra con costo unitario | Costo unitario coherente con cantidad y total |

## C. Preparación

| ID | Caso | Esperado |
|---|---|---|
| PRE-01 | Intentar entrar/guardar preparación con caja cerrada | Se solicita abrir la caja y no se modifica inventario |
| PRE-02 | Preparar 10 pizzas con caja abierta | Insumos consumidos y 10 unidades preparadas |
| PRE-03 | Preparar 0 | No genera movimiento físico |
| PRE-04 | Presionar '-' desde 0 | Registra faltante -1, no stock físico -1 |
| PRE-05 | Preparar 10 y vender 3 | Quedan 7 preparadas |
| PRE-06 | Preparar 10 y vender 7 | Sobrante lógico = 3 |
| PRE-07 | Añadir sobrante anterior al campo de hoy y guardar | El formulario conserva el total; el stock no se vuelve a sumar ni se vuelve a descontar la receta |
| PRE-08 | Elegir merma de sobrante anterior y salir sin guardar | No se crea merma ni movimiento hasta confirmar Guardar |
| PRE-09 | Llevar sobrante a mañana | Las unidades pasan una sola vez al siguiente ciclo |

## D. Ventas

| ID | Caso | Esperado |
|---|---|---|
| VEN-01 | Venta de producto preparado | Disminuye disponibilidad preparada |
| VEN-02 | Venta después de preparación | No vuelve a descontar receta completa |
| VEN-03 | Venta sin preparación suficiente | Se rechaza o se procesa según regla explícita de demanda/faltante |
| VEN-04 | Precio manual distinto | Solo afecta venta actual |
| VEN-05 | Bebida de cortesía | Precio de línea = 0 y registro de consumo |

## E. Transformaciones

| ID | Caso | Esperado |
|---|---|---|
| TRN-01 | 10 Americanas, convertir 2 a Hawaiana | -2 Americana, +2 Hawaiana |
| TRN-02 | Insumo adicional insuficiente | Transformación rechazada o parcialmente procesada según regla explícita |
| TRN-03 | Agregar nueva transformación | No requiere nueva condición de código específica |

## F. Mermas

| ID | Caso | Esperado |
|---|---|---|
| MER-01 | Merma de insumo | Disminuye stock y registra movimiento |
| MER-02 | Merma de preparación | Disminuye disponibilidad preparada |
| MER-03 | Merma desde módulo y desde detalle | Ambos usan la misma lógica |

## G. Regresión

Después de cualquier cambio de inventario, ejecutar como mínimo:
- compra → stock;
- preparación → insumos;
- preparación → disponibilidad;
- venta → preparación;
- transformación;
- merma;
- sugerencias;
- cierre de caja.
