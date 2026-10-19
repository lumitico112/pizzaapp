# Inventario y stock

## Fuente de verdad

El stock actual debe poder explicarse mediante movimientos.

Modelo conceptual:

Stock actual = stock inicial + entradas - salidas +/- ajustes

Entradas/salidas relevantes:
- compra;
- consumo de receta/preparación;
- venta;
- cortesía;
- transformación;
- merma;
- ajuste.

## Reglas

1. No cambiar stock desde widgets.
2. No duplicar la lógica de cálculo de stock en ventas, preparación y compras.
3. Cada operación debe identificar el movimiento que genera.
4. Las operaciones críticas deben ser transaccionales en el backend o persistencia aplicable.

## Conversiones

### Masa
- 1 kg = 1000 g.

### Volumen
- 1 litro = 1000 ml.

### Paquete
- Un paquete define su contenido en unidades.
- El consumo puede expresarse en unidades aunque el stock se compre por paquetes.

## Recetas

La receta puede recibir cantidades en la unidad de formulación más cómoda para el usuario. El dominio convierte a la unidad de stock antes de registrar consumo.

Ejemplo:
100 g de harina => 0.1 kg si el stock base está en kg.

## Preparación

La preparación no debe generar un inventario paralelo desconectado. Debe existir una relación explícita entre:
- preparado disponible;
- venta consumida;
- sobrante;
- merma;
- transformación.

## Transformaciones

La transformación consume una unidad base y recursos adicionales según configuración.

## Bebidas por capacidad

Si se prepara una bebida de 3 litros y se sirve por vaso, la cantidad restante debe reducirse mediante una conversión configurable de rendimiento por vaso. No asumir automáticamente que un vaso equivale a una botella completa.

## Merma

Toda merma descuenta el recurso correspondiente y crea un movimiento trazable.

## Indicador visual

El color de stock debe depender de una regla centralizada:
- rojo = sin stock;
- amarillo = stock bajo;
- verde = stock disponible.

El umbral de stock bajo no debe estar hardcodeado dentro de cada pantalla.
