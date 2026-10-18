---
name: product-inventory-flow
description: Dominio completo de Productos, Variantes, Recetas, Conversiones de Unidades, Preparación Diaria, Transformaciones en Vivo y Sugerencias Heurísticas.
---

# Skill: Flujo de Productos, Recetas, Preparación y Transformaciones

## 1. Documentación Obligatoria
1. `PROMPT_MASTER.md` — Módulos 04, 06, 07, 08 y 09.
2. `docs/SRS.md` — Requisitos FR-015 a FR-017, FR-022 a FR-034.
3. `docs/BUSINESS_RULES.md` — Reglas BR-INV, BR-CAT, BR-PRP, BR-SUG.

## 2. Invariantes del Inventario y Recetas
1. **Doble Inventario Operativo:**
   - **Materia Prima:** Insumos crudos (Harina en Kg, Queso en g, Aceite en L, etc.).
   - **Producto Preparado:** Variantes pre-elaboradas listas para venta en vitrina/cocina.
2. **Conversiones Universales:** Todas las equivalencias ($Kg \leftrightarrow g$, $L \leftrightarrow ml$, $Pqte \leftrightarrow Und$) deben ejecutarse a través de `ConversionesHelper`. Jamás codificar multiplicadores manuales en pantallas.
3. **Regla Upsert en Recetas:** Si se agrega un insumo ya presente en la receta de una variante, debe actualizarse la cantidad en vez de duplicar la fila en base de datos.
4. **Cálculo de COGS (Food Cost):** El costo de una receta se calcula dinámicamente sumando la cantidad de cada ingrediente por el costo unitario promedio ponderado de la materia prima.
5. **Dosificación por variante:** Cada variante independiente tiene receta propia por `variante_id`; compartir insumos no significa compartir cantidades. Una variante derivada puede sumar su receta específica a la receta de la variante base.
6. **Paquetes y unidades:** El stock se conserva en la unidad configurada. Si vasos se compran por paquetes, se registra el contenido del paquete y la receta puede descontar `1 Unidades`, convertido a una fracción de paquete.

### Bebidas por vaso
- La regla actual aplica a una variante llamada `Vaso` dentro de la categoría Bebidas.
- La receta debe incluir un insumo de volumen en ml/litros y el insumo cuyo nombre identifica el vaso.
- Cada venta o cortesía consume la receta completa por unidad. No tratar la porción como botella entera ni como stock preparado.
- Si falta el volumen o el vaso, el repositorio debe rechazar el cobro.

## 3. Invariantes de Preparación y Cocina
1. **Caja abierta:** La preparación y los movimientos de sobrantes requieren una sesión de caja abierta, validada en UI y nuevamente en el repositorio.
2. **Planilla de Preparación Diaria:** Al registrar unidades preparadas de una pizza, se incrementa el stock de la variante y se descuenta el proporcional exacto de materia prima según su receta.
3. **Soporte de Faltantes (Cantidades Negativas):** Si una pizza se preparó de urgencia bajo demanda sin registro previo, el sistema admite registrar cantidades negativas para alimentar la heurística de faltantes.
4. **Sobrantes de días anteriores:** Al entrar, mostrar los productos pendientes con opción de traslado a preparación de hoy o merma. Mantener la selección como borrador hasta guardar; el traslado no puede volver a sumar stock ni consumir receta.
5. **Transformaciones en Vivo (Americana -> Hawaiana):**
   - Consume 1 unidad física de la variante base preparada.
   - Consume la dosis del insumo adicional del almacén crudo.
   - Suma 1 unidad física a la variante destino.
   - **Prohibición:** La transformación jamás debe duplicar la masa base física.

## 4. Motor Heurístico de Sugerencias
- Aplicar la fórmula:
  $$\text{Sugerencia} = \max\left(0, \text{Round}\left( (\bar{V}_{\text{mismo\_día}} \times F_{\text{estacional}}) + Faltantes_{\text{anterior}} - Sobrantes_{\text{válidos}} \right)\right)$$
- Proveer desglose transparente en la UI y botón de un solo toque: "Aplicar Sugerencias a Preparación de Hoy".
