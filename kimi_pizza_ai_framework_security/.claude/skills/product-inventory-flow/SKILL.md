# Skill: Product, Recipe, Inventory and Preparation Flow

## Objetivo

Diagnosticar, implementar o refactorizar funcionalidades que conecten productos, variantes, recetas, insumos, compras, preparación, transformaciones, ventas y mermas sin inconsistencias.

## Obligaciones

1. Leer `AGENTS.md`.
2. Leer `docs/PRODUCT_RECIPES_INVENTORY_PREPARATION.md`.
3. Leer `docs/INVENTORY.md` y `docs/DATA_MODEL.md` cuando la tarea afecte persistencia o movimientos.
4. Identificar la fuente de verdad antes de modificar stock.
5. Trazar el evento completo antes de cambiar código.
6. Buscar doble descuento.
7. Buscar duplicación de conversiones.
8. Buscar duplicación de entidades/modelos.
9. Comprobar idempotencia de operaciones críticas.
10. Ejecutar las pruebas afectadas y las de regresión.

## Preguntas obligatorias antes del cambio

- ¿La operación modifica stock de insumos, stock preparado o ambos?
- ¿En qué momento se consume la receta?
- ¿Puede la venta descontar dos veces?
- ¿La transformación mueve stock o crea stock ficticio?
- ¿La unidad visible coincide con la unidad base?
- ¿La operación puede ejecutarse dos veces?
- ¿El cambio afecta sugerencias, caja o reportes?

## Patrón esperado

```text
UI
 ↓
State/Controller
 ↓
Use Case
 ↓
Domain service / rules
 ↓
Repository
 ↓
Data source
```

Las reglas de negocio no se deben colocar en widgets.
