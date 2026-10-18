---
name: inventory-validation
description: Validación de stock en tiempo real, alertas de stock mínimo, trazabilidad de movimientos y prevención de discrepancias físicas.
---

# Skill: Validación de Inventario y Trazabilidad

## 1. Reglas Inmutables de Inventario
1. **Principio de Doble Inventario:** No confundir existencias de materia prima cruda (Kg de queso en almacén) con unidades de pizzas preparadas (Pizzas listas para meter al horno).
2. **Semáforo de Insumos:**
   - Verde: $\text{Stock} > 1.5 \times \text{Stock Mínimo}$.
   - Amarillo: $\text{Stock Mínimo} \le \text{Stock} \le 1.5 \times \text{Stock Mínimo}$.
   - Rojo: $\text{Stock} < \text{Stock Mínimo}$.
3. **Cero Mutaciones Directas:** Prohibido hacer `UPDATE insumos SET stock = ...` sin un movimiento justificado (compra, preparación, merma o ajuste formal).
4. **Validación Preventiva en POS:** El POS debe consultar el stock disponible en tiempo real antes de permitir el cobro de una variante para evitar vender productos inexistentes.
