---
name: purchases-assets-waste-reporting
description: Dominio completo de Compras Unificadas, Proveedores, Cuentas por Pagar (CxP), Activos Fijos, Control de Mermas y Reportes Analíticos P&L.
---

# Skill: Compras, Activos Fijos, Cuentas por Pagar, Mermas y Reportes P&L

## 1. Documentación Obligatoria
1. `PROMPT_MASTER.md` — Módulos 03, 05, 12, 14 y 15.
2. `docs/SRS.md` — Requisitos FR-010 a FR-014, FR-018 a FR-021, FR-043, FR-049 a FR-051.
3. `docs/BUSINESS_RULES.md` — Reglas BR-PUR, BR-AST, BR-REP.

## 2. Invariantes de Compras y Cuentas por Pagar
1. **Flujo Unificado:** Toda compra de materia prima o equipamiento pasa por el módulo unificado de compras. Se elimina cualquier formulario paralelo de "Gastos Varios".
2. **Cálculo Derivado de Costo Unitario:** El costo unitario es estrictamente:
   $$CU = \frac{\text{Costo Total}}{\text{Cantidad}}$$
3. **Condición Contado:** Descuenta inmediatamente de la sesión de caja abierta.
4. **Condición Crédito:**
   - Admite un `Adelanto` inicial ($0 \le \text{Adelanto} \le \text{Total}$).
   - Si $\text{Adelanto} > 0$, genera egreso en la caja activa.
   - Crea una única fila consolidada en `cuentas_por_pagar` con:
     $$\text{Saldo Pendiente} = \text{Total Compra} - \text{Adelanto}$$
5. **Amortización de CxP:** El pago de una cuota reduce el saldo pendiente y registra la salida correspondiente en la sesión de caja abierta en ese momento.

## 3. Invariantes de Activos Fijos
1. **Modalidades de Adquisición:**
   - `Comprado`: Aplica flujo de compra (Contado con salida de caja o Crédito con CxP).
   - `Alquilado`: Requiere periodicidad y costo de canon.
   - `Prestado` / `Regalado`: Valoración simbólica patrimonial sin egreso de caja.
2. **Semáforo Operativo:** Verde (`En Uso`), Amarillo (`En Reparación`), Rojo (`Fuera de Servicio`).

## 4. Invariantes de Mermas y Desperdicios
- Asentar siempre: Entidad (Insumo o Variante), Cantidad física y unidad, Motivo categorizado (`Vencimiento`, `Rotura/Caída`, `Error de Cocina`), Usuario responsable y Costo económico de la pérdida.
- Descuenta inmediatamente el inventario y suma al indicador de mermas en los estados financieros.

## 5. Invariantes de Reportes Financieros (P&L)
1. **Fórmula Canónica de Ganancias y Pérdidas:**
   $$\text{Beneficio Neto} = \text{Ingresos Brutos} - \text{COGS (Food Cost)} - \text{Gastos Operativos}$$
2. **Prevención de Doble Contabilización:** Las compras de materia prima que ya forman parte del inventario y del COGS de productos vendidos no deben sumarse de nuevo a los gastos operativos del periodo.
3. **Exportación Ejecutiva a PDF:** Documento formal con cabecera corporativa, KPIs en cajas de color, estado P&L y tabla de productos más vendidos.
