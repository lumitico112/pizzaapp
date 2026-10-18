# Estrategia de pruebas

## Capas

### Unit tests
Usar para reglas puras y deterministas:
- conversiones;
- costo unitario;
- cálculo de subtotal/total;
- stock;
- sugerencias;
- transformaciones;
- caja;
- validación de duplicados.

### Widget tests
Usar para:
- formularios;
- visibilidad condicional;
- estados loading/error/empty;
- interacción de controles;
- validación visual de modales importantes.

### Integration tests
Usar para flujos completos:
- compra -> stock;
- preparación -> venta;
- venta -> caja;
- venta -> PDF;
- cierre -> reapertura;
- merma -> stock.

## Casos mínimos

### Unidades
- 1 kg -> 1000 g.
- 1 L -> 1000 ml.
- paquete -> unidades configuradas.
- conversiones inversas cuando aplique.

### Inventario
- compra incrementa.
- venta disminuye una sola vez.
- merma disminuye.
- cortesía consume recurso sin cobrarlo.
- transformación consume base y adicional sin duplicar base.

### Duplicidad
- categoría existente no se duplica.
- proveedor existente no se duplica.
- insumo existente no se duplica.
- insumo repetido en receta se rechaza.

### Ventas
- precio especial no altera precio base.
- efectivo sin monto recibido no muestra vuelto.
- efectivo con monto recibido calcula vuelto.
- Yape/Plin usa QR configurado.
- venta finalizada genera y guarda PDF.

### Preparación
- contador parte en 0.
- puede llegar a negativo para faltante registrado.
- sobrantes pueden pasar al día siguiente.
- merma reduce disponibilidad.

### Sugerencias
- considerar ventas.
- considerar faltantes.
- considerar sobrantes.
- respetar día de la semana.

### Caja
- efectivo esperado automático.
- transferencias automáticas.
- balance coherente.
- diferencia 0 verde.
- faltante rojo.
- sobrante naranja.
- cierre después de medianoche conserva ciclo de apertura.
- reapertura requiere autorización válida.

## Criterio de regresión

Después de modificar una regla transversal, ejecutar pruebas de todos los módulos afectados, aunque el cambio original haya comenzado en una sola pantalla.
