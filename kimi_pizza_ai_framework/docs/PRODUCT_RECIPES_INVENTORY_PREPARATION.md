# KIMI PIZZA — Reglas críticas de Productos, Recetas, Insumos, Preparación y Transformaciones

## 1. Propósito

Este documento define la fuente de verdad y las reglas de negocio para el ciclo:

```text
Producto / Variante
        ↓
      Receta
        ↓
      Insumos
        ↓
   Preparación
        ↓
Disponibilidad preparada
        ↓
      Venta
        ↓
 Stock preparado + stock de insumos + caja
```

El objetivo es impedir dobles descuentos, datos contradictorios, recetas duplicadas y lógica específica de una sola pizza.

## 2. Entidades y responsabilidades

### Product
Representa el producto comercial.

Responsabilidades:
- nombre;
- descripción;
- categoría;
- imagen;
- estado activo/inactivo;
- variantes;
- receta o recetas según el modelo real del negocio.

No debe almacenar directamente el stock calculado si ese dato puede derivarse de movimientos.

### ProductVariant
Representa una variante concreta de un producto.

Ejemplo:
- Pizza Americana — pequeña;
- Pizza Americana — mediana;
- Pizza Americana — grande.

La lista comercial puede mostrar un solo producto padre y sus variantes internamente.

### Recipe
Define qué insumos y cantidades requiere una unidad de producto/variante.

### RecipeItem
Relaciona una receta con un insumo y una cantidad normalizada.

### Ingredient
Representa el insumo físico almacenado.

Debe conservar:
- unidad base de stock;
- contenido de paquete cuando aplique;
- stock mínimo o regla de umbral;
- datos necesarios para compras, consumo y merma.

### Preparation
Representa la cantidad preparada/disponible para venta en una fecha o ciclo operativo.

### PreparationItem
Representa cada producto, variante, promoción o preparación registrada.

### TransformationRule
Define una transformación reutilizable entre un producto preparado base y un producto objetivo mediante insumos adicionales.

Ejemplo:
```text
Americana preparada
        + piña
        ↓
Hawaiana disponible
```

### StockMovement
Representa cualquier movimiento físico o lógico que modifique una existencia.

Tipos mínimos:
- PURCHASE;
- PREPARATION_CONSUMPTION;
- SALE;
- COURTESY;
- TRANSFORMATION_INPUT;
- TRANSFORMATION_OUTPUT;
- WASTE;
- ADJUSTMENT;
- OTHER explícitamente justificado.

## 3. Principio de única fuente de verdad

El stock físico de insumos debe poder reconstruirse a partir de movimientos y reglas de consumo.

El stock preparado debe representar unidades listas para venta y también debe poder reconstruirse mediante movimientos de preparación, ventas, transformaciones, mermas y transferencias al siguiente día.

No debe existir un número de stock editable arbitrariamente en varias pantallas sin registrar un movimiento.

## 4. Ciclo de preparación

La app requiere una sesión de caja abierta antes de entrar al flujo de preparación y vuelve a validar la caja al guardar los movimientos.

Si existen sobrantes pendientes de días anteriores, el formulario presenta cada producto con dos decisiones: añadir una cantidad al campo de preparación de hoy o marcarla como merma. La selección queda en borrador; no se registra hasta pulsar Guardar. La caja y los movimientos de sobrante, merma y preparación se confirman dentro de una operación transaccional.

Una preparación típica sigue:

```text
Seleccionar producto/variante
        ↓
Registrar cantidad preparada
        ↓
Resolver receta
        ↓
Calcular consumo de insumos
        ↓
Registrar consumos de insumos
        ↓
Aumentar disponibilidad preparada
```

La cantidad preparada NO debe descontarse nuevamente de los insumos cuando posteriormente se venda.

## 5. Regla crítica contra doble descuento

Para productos que se venden desde existencias preparadas:

```text
Preparación:
  consume insumos
  genera stock preparado

Venta:
  consume stock preparado
  registra ingreso/caja
```

La venta NO vuelve a consumir la receta completa si esa receta ya fue consumida durante la preparación.

Si en el futuro existe un producto preparado bajo pedido, deberá existir un flujo de dominio explícito diferente; no se debe mezclar silenciosamente con el flujo de productos preparados.

## 6. Recetas

Una receta:
- debe tener insumos claramente identificados;
- debe guardar cantidades con unidad de formulación;
- debe convertirse a la unidad base de stock antes de impactar inventario;
- debe impedir el mismo insumo repetido en la misma receta.

Si se intenta añadir un insumo ya presente:

```text
El insumo ya está agregado a la receta.
```

Debe rechazarse también a nivel de dominio/repositorio, no solamente en la UI.

## 7. Conversión de unidades

Toda conversión debe centralizarse en un servicio o componente de dominio reutilizable.

### Masa
```text
1 kg = 1000 g
1 g = 0.001 kg
```

### Volumen
```text
1 L = 1000 ml
1 ml = 0.001 L
```

### Paquetes
Si un insumo tiene:
```text
unidad = paquete
contenido = N unidades
```
se debe poder convertir entre paquetes y unidades.

Ejemplo:
```text
1 paquete = 50 unidades
5 unidades = 0.1 paquete
```

Nunca repartir conversiones entre múltiples pantallas.

## 8. Cantidad de receta

La interfaz de receta puede mostrar una unidad de formulación amigable para el usuario.

Ejemplo:
```text
Stock del insumo: kg
Cantidad en receta: 100 g
```

El sistema debe normalizar internamente a kg para el movimiento de stock.

No obligar al usuario a escribir `0.1 kg` para representar 100 g.

La misma regla aplica a litros/ml y paquetes/unidades.

## 9. Productos con variantes

La lista principal debe mostrar un solo producto cuando existan variantes, evitando repetir:

```text
Americana
Americana
Americana
```

Debe existir una forma clara de visualizar o seleccionar sus variantes.

La variante debe ser parte explícita de:
- receta cuando las recetas sean distintas;
- preparación;
- venta;
- consumo;
- transformaciones.

No asumir que todas las variantes comparten receta si el modelo actual indica lo contrario.

## 10. Categorías de productos

Debe existir una semilla inicial de cinco categorías.

La semilla debe ser idempotente:
- si existe, reutilizar;
- si no existe, crear;
- nunca duplicar al reiniciar.

Los nombres exactos de las cinco categorías deben provenir de la configuración/requisitos oficiales del proyecto o de los datos existentes; el agente no debe inventarlos silenciosamente.

Debe existir `+` para crear nuevas categorías.

Debe impedirse la duplicidad de categorías.

## 11. Insumos y categorías

El módulo de insumos debe seguir las mismas reglas:
- categoría reutilizable;
- botón `+` reutilizable;
- cinco categorías predefinidas idempotentes;
- insumo único según la identidad definida por el dominio.

La regla de unicidad debe estar clara. No depender solamente de mayúsculas/minúsculas o espacios.

## 12. Unidad de medida del insumo

Valores soportados:
```text
Kg
gr
Litros
ml
Paquetes
Unidades
```

Cuando la unidad sea `Paquetes`, debe registrarse cuántas unidades contiene el paquete.

Ese dato es obligatorio para poder convertir correctamente.

## 13. Stock dinámico del insumo

El stock se almacena en la unidad configurada para ese insumo. Si la unidad es `Paquetes`, comprar 2 significa 2 paquetes; no reescribir el saldo visible como unidades sueltas. Las recetas pueden expresarse en `Unidades` y el movimiento se convierte a paquetes utilizando el contenido configurado.

El stock actual debe reflejar, como mínimo:

```text
stock inicial
+ compras
- consumo por preparación
- mermas
± ajustes
```

Las ventas de productos preparados normalmente NO vuelven a descontar insumos, porque el consumo ya ocurrió durante la preparación.

Si se usa otro flujo, debe quedar explícito y probado para evitar doble descuento.

## 14. Rendimiento

El rendimiento debe derivarse de las recetas y cantidades preparadas.

No crear un rendimiento manual desconectado de la receta cuando pueda calcularse.

Ejemplo conceptual:
```text
1 kg de harina
→ X unidades según receta
```

El cálculo debe vivir en dominio y ser reutilizable por:
- preparación;
- sugerencias;
- simulaciones;
- validaciones de stock.

## 15. Preparación diaria

La pantalla de preparación debe mostrar todos los productos preparados que pueden venderse en el día/ciclo.

Cada fila permite:
- disminuir con `-`;
- editar numéricamente;
- aumentar con `+`;
- registrar observación específica.

Debe existir una observación general.

Los controles no deben modificar directamente bases de datos sin pasar por la lógica de dominio.

## 16. Cantidades negativas en preparación

Se permiten cantidades negativas como indicador de demanda no atendida.

Ejemplo:
```text
Cantidad preparada: 0
Cliente solicita 1
Presionar -
Resultado: -1
```

Un negativo NO significa necesariamente stock físico negativo.

Debe representar una necesidad/faltante/demanda y registrarse con motivo.

No permitir que un negativo de preparación se convierta automáticamente en stock físico negativo del almacén.

## 17. Sobrantes

Si al terminar el ciclo quedan unidades preparadas:

```text
preparado = 10
vendido = 7
sobrante = 3
```

el sistema debe permitir:
- mantener para el siguiente día cuando sea permitido;
- registrar merma;
- dejar el sobrante en cero con el movimiento correspondiente cuando se descarte.

No copiar el mismo stock dos veces al pasar sobrantes al día siguiente.

## 18. Transformaciones

Una transformación convierte disponibilidad preparada existente en otra presentación/producto sin crear unidades base ficticias.

Ejemplo:
```text
10 Americanas preparadas
+ transformación Americana → Hawaiana
```

Si se convierten 2:
```text
-2 Americanas disponibles
+2 Hawaianas disponibles
- consumo de piña correspondiente
```

El sistema no debe sumar 2 Hawaianas sin disminuir la disponibilidad base correspondiente.

## 19. Transformaciones reutilizables

No implementar una condición exclusiva:
```dart
if (americana) convertirAHawaiana();
```

Debe existir un modelo general de transformación.

Ejemplo conceptual:
```text
TransformationRule
  sourceProduct / sourceVariant
  targetProduct / targetVariant
  additionalIngredients[]
  yield
  active
```

Eso permite agregar en el futuro:
- Americana → Hawaiana;
- otra base → otra variedad;
- múltiples transformaciones.

## 20. Consumo de ingredientes en transformaciones

Los ingredientes adicionales deben descontarse con la receta/regla de transformación.

Ejemplo:
```text
1 Hawaiana derivada de Americana
= 1 Americana preparada
+ X g de piña
```

No volver a consumir toda la receta de Americana si la unidad ya fue preparada.

## 21. Promociones en el ciclo de inventario

Una promoción puede agrupar productos y/o insumos según la definición del negocio.

La promoción no debe duplicar físicamente el stock de sus componentes.

En una venta, el consumo debe resolver los componentes reales de la promoción según las reglas configuradas.

## 22. Bebidas de cortesía

Una bebida marcada como cortesía:
- tiene precio de venta cero para la línea de cortesía;
- queda registrada en la venta;
- consume el recurso correspondiente;
- no debe modificar el precio base del producto.

La cortesía se sirve en vaso.

En la implementación actual, una bebida por vaso se modela como una variante vendible independiente, por ejemplo `Vaso pequeño`, dentro de la categoría Bebidas. Su receta por unidad contiene el volumen servido en ml o litros y el insumo del vaso. La venta normal y la cortesía consumen esa receta completa; no se utiliza el stock preparado de una botella para esta modalidad.

El nombre de la variante debe incluir `Vaso`. Al confirmar una venta o cortesía, el repositorio valida que la receta incluya un insumo de volumen y otro cuyo nombre identifique el vaso. Si falta cualquiera, la operación se rechaza con un mensaje para corregir la receta. Las variantes independientes mantienen cantidades propias; las variantes derivadas pueden consumir además la receta de su base.

## 23. Bebida de 3 litros servida por vaso

Ejemplo:
```text
Insumo Gaseosa: stock en litros
Compra: 3 L
Variante vendible: Vaso pequeño
Receta por unidad: volumen servido en ml + 1 unidad de vaso
```

El volumen de receta es el tamaño real de la porción que sirve el local; no se fija un volumen universal. La conversión litros/ml se aplica al descontar el insumo. Por ejemplo, una receta de 250 ml consume 0.25 L del stock por cada unidad.

Si los vasos se compran por paquetes, crea el insumo con unidad `Paquetes` e indica cuántos vasos trae el paquete. En la receta, selecciona ese insumo y dosifica `1` en `Unidades`; el conversor descuenta la fracción equivalente del paquete. Por ejemplo, con 50 vasos por paquete, un vaso consume 1/50 de paquete.

El stock teórico de una botella de 3 L alcanza para `3000 ml ÷ volumen servido` unidades, antes de considerar pérdidas. El POS muestra la variante como `1 vaso de Gaseosa` y la opción de cortesía cobra S/ 0.00 mientras registra el consumo de ambos insumos.

El sistema debe impedir:
- consumos negativos inesperados;
- descontar litros dos veces;
- contabilizar el mismo vaso como una botella completa;
- registrar una venta/cortesía por vaso sin receta de volumen y vaso.

## 24. Mermas

Una merma puede originarse desde:
- módulo de mermas;
- insumo;
- preparación.

Todas deben terminar usando una misma lógica de dominio y generando un `StockMovement` o equivalente.

Debe registrar:
- fecha;
- usuario;
- elemento;
- cantidad;
- unidad;
- motivo;
- observación.

## 25. Estados de stock

El indicador visual de stock debe derivarse de una regla centralizada.

Estados mínimos:
- verde: disponible;
- amarillo: stock bajo;
- rojo: sin stock.

Los umbrales no deben estar escritos directamente dentro de la pantalla.

## 26. Compra → Insumo → Stock

Una compra de insumo debe:
1. registrar compra;
2. registrar cantidad/unidad;
3. convertir si es necesario;
4. registrar movimiento de entrada;
5. actualizar stock derivado/consultable.

No actualizar únicamente el texto visible de stock.

## 27. Venta → Preparación → Stock

Para productos preparados:

```text
Venta
 ↓
verificar disponibilidad preparada
 ↓
disminuir disponibilidad preparada
 ↓
registrar venta
 ↓
actualizar caja
```

No consumir de nuevo la receta completa salvo que el producto pertenezca explícitamente a un flujo de preparación bajo pedido.

## 28. Preparación → Sugerencias

Las sugerencias deben poder utilizar:
- ventas históricas;
- cantidades preparadas;
- faltantes negativos;
- sobrantes;
- día de la semana.

La preparación no debe guardar una fórmula de sugerencia propia.

Debe consumirse el algoritmo centralizado de sugerencias.

## 29. Idempotencia y concurrencia

Las operaciones críticas deben protegerse contra doble envío:
- guardar compra;
- guardar preparación;
- registrar venta;
- registrar merma;
- transformar producto.

Si el backend lo soporta, utilizar identificadores de operación/idempotency keys o transacciones equivalentes.

## 30. Casos límite obligatorios

Probar:
- stock cero;
- stock exacto;
- stock insuficiente;
- decimal de kg;
- decimal de litros;
- paquete con contenido;
- receta duplicada;
- categoría duplicada;
- insumo duplicado;
- producto con múltiples variantes;
- preparación cero;
- preparación negativa;
- sobrante;
- merma parcial;
- merma total;
- transformación parcial;
- transformación sin ingrediente adicional suficiente;
- venta de cortesía;
- bebida de 3 litros llegando a cero;
- doble toque en guardar/cobrar;
- operación repetida tras reconexión.

## 31. Criterios de aceptación

La funcionalidad se considera correcta únicamente si:

```text
[ ] La receta no duplica insumos.
[ ] Las unidades se convierten correctamente.
[ ] Comprar aumenta stock.
[ ] Preparar consume insumos una sola vez.
[ ] Preparar crea disponibilidad preparada.
[ ] Vender consume disponibilidad preparada.
[ ] Vender no vuelve a descontar la receta preparada.
[ ] Transformar mueve disponibilidad base a producto objetivo.
[ ] Transformar consume únicamente los insumos adicionales necesarios.
[ ] Merma afecta la existencia correspondiente.
[ ] Sobrantes pueden pasar al siguiente ciclo sin duplicarse.
[ ] Los negativos representan faltante/demanda, no inventario físico negativo.
[ ] Cortesías quedan registradas sin cobrar.
[ ] Las bebidas por vaso consumen correctamente la preparación.
[ ] Los cálculos de rendimiento provienen de reglas centralizadas.
[ ] Las sugerencias reciben datos correctos.
[ ] No existe una segunda implementación de las conversiones.
[ ] No existe una segunda implementación de stock.
```
