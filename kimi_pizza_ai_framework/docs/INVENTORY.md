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

Las existencias preparadas de variantes se ajustan exclusivamente mediante el
escritor central de movimientos. `MovimientosStockPreparado` conserva entradas,
preparaciones, ventas, transformaciones, mermas y ajustes. Una entrada adicional
de producto ya preparado suma unidades al saldo existente; nunca reemplaza la
cantidad disponible.

Una regla de transformación puede tener rendimiento y varios insumos
adicionales. Su aplicación descuenta primero la variante de origen, registra la
variante de destino y consume los insumos configurados en una transacción. Por
ejemplo, convertir Americana en Hawaiana no crea una segunda unidad base.

## Bebidas servidas por vaso

En la implementación actual, una bebida servida por vaso es una variante vendible de la categoría Bebidas cuyo nombre incluye `Vaso`. Su receta por unidad define el volumen real servido en ml o litros y el insumo del vaso. Cada venta o cortesía consume ambos componentes desde la receta; no se descuenta una botella completa ni se requiere stock preparado de la bebida.

Para un insumo almacenado en litros, la receta puede dosificarse en ml (`1 L = 1000 ml`). Para vasos almacenados en paquetes, registra `contenido_paquete` como el número de unidades del paquete y usa `1 Unidades` en la receta. El conversor convierte ese vaso a la fracción correspondiente del paquete.

La venta por vaso debe rechazarse si falta el componente de volumen o el insumo cuyo nombre identifica el vaso. No se debe fijar un tamaño universal: cada variante lleva su propio volumen.

Ejemplo con 3 L y paquete de 50 vasos:

```text
Insumo Gaseosa: unidad de stock Litros; compra: 3
Insumo Vaso descartable: unidad Paquetes; contenido_paquete: 50; compra: 1
Variante: Vaso pequeño
Receta por unidad: 250 ml de gaseosa + 1 unidad de vaso
Consumo de una venta o cortesía: 0.25 L + 1/50 de paquete
```

El volumen `250 ml` es solo ilustrativo; debe configurarse con la porción real del negocio.

## Merma

Toda merma descuenta el recurso correspondiente y crea un movimiento trazable.

## Indicador visual

El color de stock debe depender de una regla centralizada:
- rojo = sin stock;
- amarillo = stock bajo;
- verde = stock disponible.

El umbral de stock bajo no debe estar hardcodeado dentro de cada pantalla.
