---
name: sales-cash-flow
description: Analizar, implementar y validar cambios relacionados con ventas, carrito, pagos, boletas, historial, sesiones de caja y cierres.
---

# Skill: Sales & Cash Flow

## Leer antes de trabajar

1. `AGENTS.md`
2. `docs/SALES_PAYMENTS.md`
3. `docs/CASH_FLOW.md`
4. `docs/INVENTORY.md`
5. `docs/PRODUCT_RECIPES_INVENTORY_PREPARATION.md`
6. `docs/USERS_CONFIGURATION.md` cuando haya autorización/sesión.
7. `docs/DATA_MODEL.md`
8. `docs/SALES_CASH_TEST_CASES.md`

## Procedimiento

### 1. Inspección

Identificar:
- modelo de venta;
- carrito;
- método de pago;
- estado de venta;
- caja activa;
- disponibilidad preparada;
- stock;
- PDF;
- historial.

### 2. Causa raíz

No corregir solamente la pantalla. Determinar si el defecto pertenece a presentation, state, domain, repository, persistencia o backend.

### 3. Reglas obligatorias

- El precio especial no modifica catálogo.
- Yape/Plin usa el QR configurado.
- Cortesía vale 0 y queda registrada.
- Cobrar es una operación idempotente.
- La venta consume disponibilidad/stock una sola vez.
- El PDF se persiste sin duplicar ventas.
- Caja recibe automáticamente las ventas confirmadas.
- Una sesión cerrada no admite ventas normales.
- La reapertura requiere autorización.

### 4. Validación

Ejecutar los casos relevantes de `SALES_CASH_TEST_CASES.md`, más regresiones de inventario y autenticación cuando correspondan.

### 5. Resultado

Explicar brevemente:
- causa raíz;
- archivos/capas modificados;
- pruebas realizadas;
- impacto cruzado revisado;
- cualquier deuda técnica pendiente.
