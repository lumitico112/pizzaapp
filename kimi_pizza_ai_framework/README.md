# KIMI PIZZA — AI ENGINEERING & SOFTWARE SPECIFICATION FRAMEWORK
**Versión del Framework:** 3.0.0 (Consolidated Audit & Approved Business Rules Edition)  
**Estado:** Especificación, Gobernanza y Hoja de Ruta Oficial para Kimi Pizza POS  
**Stack Tecnológico:** Flutter / Dart / Android / SQLite con Cifrado SQLCipher (AES-256) / Offline-First  

---

## 1. VISIÓN GENERAL DEL FRAMEWORK

El **KIMI PIZZA AI Engineering Framework** es la suite integral de ingeniería de software, arquitectura de sistemas, reglas de negocio y gobernanza técnica para la evolución controlada de **Kimi Pizza POS** (`com.kimipizza.pos`).

En su versión **3.0.0**, incorpora el **Informe Consolidado de Auditoría Técnica (`C-01` a `C-31`)** y las **12 Decisiones Oficiales de Negocio (`RN-01` a `RN-12`)**, garantizando que cualquier agente de IA o desarrollador trabaje sobre la realidad verificada del código y respete las invariantes financieras, de inventario y de SQLite.

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
- [`AGENTS.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/AGENTS.md) (sincronizado con [`/AGENTS.md`](file:///c:/D/ProyectoPizza/pizzaapp/AGENTS.md) en la raíz): **Constitución Técnica y Protocolo de Ejecución por Fases.** Define las reglas arquitectónicas no negociables, las 12 Reglas de Negocio Oficiales (`RN-01` a `RN-12`), las 4 Trampas Técnicas de SQLite/Seguridad y la secuencia de trabajo de las Fases 0 a 8.
- [`docs/AUDIT_CONSOLIDATED.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/AUDIT_CONSOLIDATED.md): **Informe Consolidado de Auditoría Técnica (`C-01` a `C-31`).** Matriz unificada de hallazgos verificados en código, resolución de discrepancias y hoja de ruta priorizada.
- [`PROMPT_MASTER.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/PROMPT_MASTER.md): **Directiva Maestra de Ingeniería.** Especificación integral de los 17 módulos del sistema alineada con las decisiones de negocio aprobadas.

### 2.2 Catálogos de Dominio y Reglas de Negocio
- [`docs/BUSINESS_RULES.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/BUSINESS_RULES.md): **Catálogo Canónico de Reglas de Negocio (`BR-2026-V3.0`).** Especificación matemática numerada (`BR-SEC`, `BR-INV`, `BR-PUR`, `BR-AST`, `BR-CAT`, `BR-PRP`, `BR-SUG`, `BR-POS`, `BR-CSH`, `BR-REP`, `BR-BCK`) con las 12 decisiones aprobadas.
- [`docs/IMPLEMENTED_CAPABILITIES.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/IMPLEMENTED_CAPABILITIES.md): Inventario de capacidades verificadas en el código actual, referencias de implementación y estado de brechas auditadas.
- [`docs/DATA_MODEL.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/DATA_MODEL.md): Modelo relacional, nota crítica de sincronización de las 36 tablas (`db_schema.dart` vs `database_helper.dart`) y estrategia de índices.
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
