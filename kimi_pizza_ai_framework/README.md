# KIMI PIZZA — AI ENGINEERING & SOFTWARE SPECIFICATION FRAMEWORK
**Versión del Framework:** 3.1.0 (Post-Correction Verified Edition — 18/10/2026)  
**Estado:** Gobernanza técnica verificada post-corrección: plan `H-01`…`H-13` ejecutado (`F0`–`F15`), suite **75/75** y `flutter analyze` **0 issues**.  
**Stack Tecnológico:** Flutter / Dart / Android / SQLite con Cifrado SQLCipher (AES-256) / Offline-First  

---

## 1. VISIÓN GENERAL DEL FRAMEWORK

El **KIMI PIZZA AI Engineering Framework** es la suite integral de ingeniería de software, arquitectura de sistemas, reglas de negocio y gobernanza técnica para la evolución controlada de **Kimi Pizza POS** (`com.kimipizza.pos`).

En su versión **3.1.0**, el framework conserva el **Informe Consolidado de Auditoría Técnica (`C-01` a `C-31`)** y las **12 Decisiones Oficiales de Negocio (`RN-01` a `RN-12`)**, e incorpora el **estado post-corrección verificado** (sección 4 del informe y bitácora `agent.md`): los hallazgos residuales del informe del 18/10/2026 (`H-01`…`H-13`) fueron corregidos en las fases `F0`–`F15` con regresión completa en verde. Garantiza que cualquier agente de IA o desarrollador trabaje sobre la realidad verificada del código y respete las invariantes financieras, de inventario y de SQLite.

```
                                  ┌─────────────────────────────┐
                                  │          AGENTS.md          │
                                  │ (Constitución y Guardrails) │
                                  └──────────────┬──────────────┘
                                                 │
                                  ┌──────────────▼──────────────┐
                                  │      PROMPT_MASTER.md       │
                                  │ (Especificación de Módulos) │
                                  └──────────────┬──────────────┘
                                                 │
        ┌────────────────────────────────────────┼────────────────────────────────────────┐
        │                                        │                                        │
┌───────▼────────────────┐              ┌────────▼───────────────┐              ┌────────▼────────────────┐
│ AUDITORÍA Y REGLAS     │              │   CONTRATOS Y DISEÑO   │              │   OPERACIÓN Y PRUEBAS   │
│ - AUDIT_CONSOLIDATED   │              │  - SDD.md / SRS.md     │              │  - TESTING_STRATEGY.md  │
│ - BUSINESS_RULES.md    │              │  - DATA_MODEL.md       │              │  - USER_MANUAL.md       │
│ - IMPLEMENTED_CAPAB.   │              │  - API_TECHNICAL.md    │              │  - CASH_FLOW / POS      │
└────────────────────────┘              └────────────────────────┘              └─────────────────────────┘
```

---

## 2. MAPA MAESTRO DE DOCUMENTACIÓN

### 2.1 Núcleo de Gobernanza, Auditoría y Agentes
- [`AGENTS.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/AGENTS.md) (sincronizado con [`/AGENTS.md`](file:///c:/D/ProyectoPizza/pizzaapp/AGENTS.md) en la raíz): **Constitución Técnica y Protocolo de Ejecución por Fases.** Define las reglas arquitectónicas no negociables, las 12 Reglas de Negocio Oficiales (`RN-01` a `RN-12`), los 4 Guardrails críticos de SQLite/Seguridad (trampas de auditoría resueltas y vigiladas) y el protocolo de trabajo (plan de corrección cerrado el 18/10/2026).
- [`docs/AUDIT_CONSOLIDATED.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/AUDIT_CONSOLIDATED.md): **Informe Consolidado de Auditoría Técnica (`C-01` a `C-31`).** Matriz unificada de hallazgos verificados en código, resolución de discrepancias, hoja de ruta priorizada y **sección 4 con el estado post-corrección** (`H-01`…`H-13` → estado + fase + commit).
- [`PROMPT_MASTER.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/PROMPT_MASTER.md): **Directiva Maestra de Ingeniería.** Especificación integral de los 17 módulos del sistema (esquema canónico v28) alineada con las decisiones de negocio aprobadas.
- [`agent.md`](file:///c:/D/ProyectoPizza/pizzaapp/agent.md) (raíz): **Bitácora de ejecución del plan de corrección (`F0`–`F15`).** Tabla de progreso por fase, decisiones, prompts y pendientes explícitos; complementa a `AGENTS.md` (no lo reemplaza).

### 2.2 Catálogos de Dominio y Reglas de Negocio
- [`docs/BUSINESS_RULES.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/BUSINESS_RULES.md): **Catálogo Canónico de Reglas de Negocio (`BR-2026-V3.0`).** Especificación matemática numerada (`BR-SEC`, `BR-INV`, `BR-PUR`, `BR-AST`, `BR-CAT`, `BR-PRP`, `BR-SUG`, `BR-POS`, `BR-CSH`, `BR-REP`, `BR-BCK`) con las 12 decisiones aprobadas.
- [`docs/IMPLEMENTED_CAPABILITIES.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/IMPLEMENTED_CAPABILITIES.md): Inventario de capacidades verificadas en el código actual, referencias de implementación y estado post-corrección de los hallazgos auditados.
- [`docs/DATA_MODEL.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/DATA_MODEL.md): Modelo relacional v28 (38 tablas), sincronización esquema↔migraciones certificada por test (`schema_equivalence_test.dart`) y estrategia de índices (28 `IDX_*` + 4 triggers).
- [`docs/ASSETS_AND_PAYABLES_FLOWS.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/ASSETS_AND_PAYABLES_FLOWS.md): Reglas de activos fijos, compras a crédito, recálculo de abonos en `PagosCuentaPorPagar` (`RN-01`) y bloqueo de borrado directo de gastos (`RN-02`).
- [`docs/CASH_FLOW.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/CASH_FLOW.md): Ciclo operativo por `sesion_caja_id` (`RN-06`) y fuente única `CashCloseSummary` (`RN-04`).
- [`docs/SALES_PAYMENTS.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/SALES_PAYMENTS.md) y [`docs/SALES_FLOW.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/SALES_FLOW.md): Flujos de POS, boletas PDF con IGV desglosado, bebidas por vaso y bloqueo de productos `'momento'` sin receta/stock (`RN-07`).
- [`docs/PRODUCT_RECIPES_INVENTORY_PREPARATION.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/PRODUCT_RECIPES_INVENTORY_PREPARATION.md) y [`docs/INVENTORY.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/INVENTORY.md): Doble inventario, invariante física de sobrantes/mermas (`RN-03`), traslado idempotente y alimentación de `ItemsPreparacion.sobrante`.
- [`docs/USERS_CONFIGURATION.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/USERS_CONFIGURATION.md) y [`docs/PASSWORD_RECOVERY.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/PASSWORD_RECOVERY.md): Login por `username` con filtro `activo = 1 AND bloqueado = 0` (`RN-10`), reactivación auditada (`RN-11`), recuperación con clave de rescate y QR del negocio.
- [`docs/BACKUPS_AND_RECOVERY.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/BACKUPS_AND_RECOVERY.md): Copias portátiles `.kpzbackup`, copias diarias locales y exclusión de Android Auto Backup (`RN-08`).

### 2.3 Especificaciones IEEE, Pruebas y Manuales
- [`docs/SRS.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/SRS.md), [`docs/SDD.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/SDD.md), [`docs/ARCHITECTURE.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/ARCHITECTURE.md), [`docs/API_TECHNICAL_DOCS.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/API_TECHNICAL_DOCS.md).
- [`docs/TESTING_STRATEGY.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/TESTING_STRATEGY.md), [`docs/SALES_CASH_TEST_CASES.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/SALES_CASH_TEST_CASES.md), [`docs/PRODUCT_PREPARATION_TEST_CASES.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/PRODUCT_PREPARATION_TEST_CASES.md), [`docs/PURCHASES_ASSETS_WASTE_TEST_CASES.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/PURCHASES_ASSETS_WASTE_TEST_CASES.md).
- [`docs/TRACEABILITY_MATRIX.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/TRACEABILITY_MATRIX.md), [`docs/CHANGE_CHECKLIST.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/CHANGE_CHECKLIST.md), [`docs/USER_STORIES_BACKLOG.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/USER_STORIES_BACKLOG.md), [`docs/USER_MANUAL.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/USER_MANUAL.md).
