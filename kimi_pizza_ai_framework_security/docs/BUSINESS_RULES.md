# Reglas de negocio transversales — KIMI PIZZA

> **Vigencia (18/10/2026):** reglas transversales de diseño. Las **12 decisiones oficiales de negocio (`RN-01`…`RN-12`)** y las reglas implementadas y verificadas están en el framework principal (`AGENTS.md` de la raíz y `kimi_pizza_ai_framework/`). En caso de conflicto, prevalece el framework principal.

## Identidad y duplicidad

- Categorías, insumos y proveedores deben ser únicos según la clave de negocio definida.
- Un insumo no puede aparecer dos veces dentro de una misma receta.
- Las restricciones críticas de unicidad deben validarse en dominio/backend cuando exista persistencia remota.

## Precio

- El precio base de producto es independiente del precio aplicado en una venta concreta.
- Un precio personalizado en una venta no debe modificar el catálogo.
- Una bebida de cortesía no genera cobro, pero sí genera registro y consumo del recurso.

## Compras

- Una compra puede corresponder a insumos o activos, dentro del flujo unificado.
- El costo unitario debe ser derivado de cantidad y costo total cuando corresponda.
- Una cuenta por pagar debe mantener el monto pendiente y el adelanto.
- El proveedor debe quedar vinculado a la compra cuando corresponda.

## Inventario

- Toda variación de stock debe tener causa.
- No modificar stock de forma directa en múltiples capas sin registrar un movimiento.
- Un mismo evento no puede descontarse dos veces.

## Preparación

- La preparación representa disponibilidad operativa para venta.
- Un valor negativo representa una demanda/faltante de preparación que no pudo satisfacerse con stock preparado.
- Los sobrantes pueden pasar al siguiente día si son válidos según la regla de negocio.
- Los sobrantes que dejan de ser utilizables se convierten en merma.

## Transformaciones

Una transformación es una relación genérica entre una preparación/producto base y una variante/producto derivado mediante ingredientes o reglas adicionales.

Ejemplo:
Americana -> Hawaiana + consumo adicional de piña.

La transformación consume la base disponible y el adicional requerido. No crea unidades duplicadas de la base.

## Mermas

La merma debe registrar como mínimo:
- entidad afectada;
- cantidad;
- fecha;
- motivo;
- usuario responsable.

## Caja

La caja se trata como un ciclo operativo.

Una caja abierta el día D y cerrada después de medianoche conserva como ciclo la fecha de apertura, aunque la hora de cierre pertenezca al día calendario siguiente.

Las reaperturas excepcionales deben:
- estar autorizadas;
- registrar usuario;
- registrar fecha/hora;
- quedar auditadas.

## Sesión

El usuario permanece autenticado hasta logout o el evento de negocio que determine el cierre de sesión asociado al cierre de caja.
