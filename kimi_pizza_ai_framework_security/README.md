# KIMI PIZZA — AI Engineering Framework (Edición de Seguridad)

**Edición de seguridad — 18/10/2026.** Framework de trabajo para desarrollar, mantener, depurar y evolucionar la aplicación Flutter KIMI PIZZA, con foco en **ingeniería segura** (ISO/IEC 27001:2022 / 27002:2022 y OWASP MASVS/MASTG) e **integridad del POS**.

## Contexto y precedencia (obligatorio)

- El **estado verificado y autoritativo** del proyecto vive en el `AGENTS.md` de la raíz del repositorio y en `kimi_pizza_ai_framework/` (auditoría `C-01`…`C-31`; plan `H-01`…`H-13` ejecutado en fases `F0`–`F15`; suite **75/75**; `flutter analyze` **0 issues**; esquema **v25**).
- Esta carpeta es la **edición de seguridad**: línea base, matriz de controles, plan de pruebas y Skills de trabajo. **Donde haya conflicto, prevalece el framework principal.**
- Los documentos de dominio aquí incluidos son referencia de diseño (08/10/2026); el detalle vigente (esquema físico v25, 37 tablas) está en `kimi_pizza_ai_framework/docs/DATA_MODEL.md` y `lib/core/database/db_schema.dart`.
- **Estado de la evaluación de seguridad: ciclo cerrado en `FS-8` (18/10/2026)** — evidencia inicial mapeada y evaluación ejecutada (ver estados finales en "Evidencia del proyecto y estados finales (FS-8, 18/10/2026)" de `docs/SECURITY_CONTROL_MATRIX.md`, el cierre de cobertura en §3.3 de `docs/SECURITY_TEST_PLAN.md` y el registro en `docs/SECURITY_CLOSURE_REGISTER.md`); **triaje de los 40 casos publicado** (§3.2; fase `FS-1`). La fase `FS-2` quedó **cerrada** el 18/10/2026 sobre el código corregido en `FS-2A` (pruebas permanentes de SEC-018 a SEC-028, SEC-026 re-ejecutado 3/3, suite **110/110**) y la corrección de H-4 (`FS-2B`) quedó **ejecutada** el 18/10/2026 (commit `09dea39`; suite **115/115**; analyze 0) y `FS-3` (caja y ciclo operativo: SEC-029/030/031) quedó **ejecutada** el 18/10/2026 (commit `e9bce34`; suite **123/123**; analyze 0) y `FS-4` (QR administrativo y cobro: SEC-022/023/024) quedó **ejecutada** el 18/10/2026 (commit `40dbc6c`; suite **129/129**; analyze 0). `FS-5` quedó **ejecutada** el 18/10/2026 (lote estático: SEC-011/013/032/034/036/037/039; evidencia en `docs/SECURITY_STATIC_EVIDENCE.md`; sin cambios de código; propuesta de CI pendiente de aprobación); `FS-6` quedó **ejecutada** el 18/10/2026 (acceso, cuentas y sesión: SEC-001…010; evidencia en `docs/SECURITY_ACCESS_EVIDENCE.md`; suite **139/139**; analyze 0; residuales SEC-002 y SEC-007/008 sujetos a decisión del propietario). La `FS-7` (casos de entorno) se inició el 18/10/2026 en dispositivo físico (Motorola Edge 60 Fusion, Android 16/API 36) y quedó **detenida por el defecto `DEF-FS7-01`** —cancelar el diálogo de contraseña de la copia portátil rompía la app en debug (`A TextEditingController was used after being disposed` + aserción `_dependents.isEmpty`)—, corregido en **`FS-7A`** (commit `5cb05f0`; regresión `test/respaldo_dialogo_seguridad_test.dart`, 5 pruebas; suite **144/144**; analyze 0). La `FS-7` quedó **ejecutada** el 18/10/2026 al reanudarse en dispositivo físico: SEC-012/014/015/016/033/035/038 con evidencia redactada en `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` (inspección del APK release, exportación/restauración `.kpzbackup` incluida la restauración cruzada en el release recién instalado sin red, artefacto firmado con keystore de prueba y exportaciones controladas). Ningún control se considera evaluado sin re-ejecución, evidencia y revisor. El ciclo quedó **cerrado en `FS-8`** (18/10/2026): 40/40 casos con disposición final (`docs/SECURITY_TEST_PLAN.md` §3.3), ratificaciones R-01…R-04, excepciones aceptadas E-01…E-06 (dueño, compensación y caducidad) y estados finales consolidados en `docs/SECURITY_CLOSURE_REGISTER.md`; pendientes operativos P-01…P-05 con responsable.
- **Pendientes de entorno:** verificación funcional de cifrado/instalación en dispositivo (`F11(e)`, `F12(d)`) y ruta positiva de release firmado (requiere keystore propio).

## Componentes

- `AGENTS.md`: reglas permanentes para el agente.
- `PROMPT_MASTER.md`: especificación funcional y arquitectónica maestra.
- `docs/`: arquitectura, reglas de negocio, modelo de datos, flujos, pruebas y trazabilidad.
- `.claude/skills/`: procedimientos especializados para arquitectura, debugging, refactoring, inventario, seguridad, testing y flujos transaccionales.

## Documentación crítica

- `docs/ARCHITECTURE.md`
- `docs/BUSINESS_RULES.md`
- `docs/DATA_MODEL.md`
- `docs/INVENTORY.md`
- `docs/PRODUCT_RECIPES_INVENTORY_PREPARATION.md`
- `docs/USERS_CONFIGURATION.md`
- `docs/SALES_PAYMENTS.md`
- `docs/CASH_FLOW.md`
- `docs/PURCHASES_SUPPLIERS_PAYABLE_ASSETS_WASTE_REPORTS.md`
- `docs/TRACEABILITY_MATRIX.md`
- `docs/IMPLEMENTATION_ROADMAP.md`

## Cómo usar el framework

1. El agente debe leer `AGENTS.md` antes de modificar código.
2. Debe consultar la documentación del módulo afectado.
3. Debe usar la Skill especializada que corresponda.
4. Debe analizar el código real antes de crear nuevas clases o widgets.
5. Debe buscar reutilización y duplicidad antes de implementar.
6. Debe probar el cambio y sus efectos cruzados.

## Orden de implementación recomendado

```text
Auditoría
  ↓
Fundaciones
  ↓
Usuarios / Configuración
  ↓
Productos / Recetas
  ↓
Insumos / Inventario
  ↓
Compras / Proveedores / CxP
  ↓
Activos
  ↓
Preparación
  ↓
Transformaciones
  ↓
Ventas / Pagos
  ↓
Caja
  ↓
Mermas / Sugerencias
  ↓
Reportes / Dashboard
  ↓
Regresión / endurecimiento
```

## Regla de oro

**Analizar primero. Reutilizar antes de crear. Corregir la causa raíz. Probar el flujo completo. No introducir duplicidad.**

## Seguridad de la aplicación

- `docs/SECURITY_BASELINE.md`: línea base técnica de seguridad para Flutter, almacenamiento, API, plataforma y operación POS.
- `docs/SECURITY_CONTROL_MATRIX.md`: matriz indicativa de controles y evidencia alineada a ISO/IEC 27001:2022 / 27002:2022 y OWASP MASVS.
- `docs/SECURITY_TEST_PLAN.md`: catálogo de pruebas de seguridad de aplicación y flujos críticos.
- `docs/SECURITY_ACTION_PLAN.md`: plan de acción por fases (`FS-0`–`FS-11`) para incorporar esta edición al control de versiones y ejecutar la evaluación de seguridad.
- `docs/SECURITY_PHASE_PROMPTS.md`: prompts de ejecución listos para copiar, uno por fase.
- `.claude/skills/security-review/SKILL.md`: procedimiento especializado para investigar, implementar y verificar correcciones de seguridad.

La documentación mejora la disciplina de ingeniería, pero no equivale a certificación ISO ni sustituye auditoría del SGSI.

**Estado de la evaluación (18/10/2026):** preparación completa — evidencia inicial mapeada, triaje de los 40 casos publicado, mejoras de acceso `FS-10`/`FS-11` ejecutadas y fase `FS-2` **cerrada** sobre el código corregido en `FS-2A` (pruebas permanentes de SEC-018 a SEC-028, SEC-026 re-ejecutado 3/3, filas "Integridad POS" de la matriz con evidencia registrada; suite **110/110**; H-4 corregido en `FS-2B`, commit `09dea39`; `FS-3` ejecutada, commit `e9bce34`; `FS-4` ejecutada, commit `40dbc6c`, suite **129/129**); `FS-7` (casos de entorno) **ejecutada** el 18/10/2026 (SEC-012/014/015/016/033/035/038; evidencia en `docs/SECURITY_ENVIRONMENT_EVIDENCE.md`), tras la `FS-6` **ejecutada** el 18/10/2026 (SEC-001…010; evidencia en `docs/SECURITY_ACCESS_EVIDENCE.md`; suite **139/139**; analyze 0) y la `FS-5` **ejecutada** el 18/10/2026 (lote estático: SEC-011/013/032/034/036/037/039; evidencia en `docs/SECURITY_STATIC_EVIDENCE.md`; SEC-037 aprobado e implementado en CI el 18/10/2026 (commit `a176041`; canario verificado el 19/10/2026 (PR #2, job `118319199755`))) y el ciclo quedó **cerrado en `FS-8`** el 18/10/2026 (40/40 casos con disposición final en `docs/SECURITY_TEST_PLAN.md` §3.3; ratificaciones, excepciones y estados finales en `docs/SECURITY_CLOSURE_REGISTER.md`):

- `docs/SECURITY_CONTROL_MATRIX.md` → sección "Evidencia del proyecto y estados finales (FS-8, 18/10/2026)" (control → evidencia → estado final) y registro en `docs/SECURITY_CLOSURE_REGISTER.md`.
- `docs/SECURITY_TEST_PLAN.md` → secciones 3.1/3.2 (historial) y §3.3 "Cierre de cobertura (FS-8)" (40 casos con disposición final).
- `docs/SECURITY_ACTION_PLAN.md` → fases `FS-0`–`FS-11` (reglas generales, evidencia y gates por fase); `docs/SECURITY_PHASE_PROMPTS.md` → prompts de ejecución, uno por fase.
- Corrección **`FS-7A`** (18/10/2026): `DEF-FS7-01` resuelto extrayendo el diálogo a `BackupPasswordDialog` (controladores liberados en `dispose()`); regresión `test/respaldo_dialogo_seguridad_test.dart` (5 pruebas); commit `5cb05f0`; suite **144/144**; analyze 0.

Varios casos de integridad del POS (venta/inventario/caja) cruzaban con correcciones ya cerradas de la auditoría (`H-05`, `H-07`, `RN-02`…`RN-04`); fueron re-ejecutados como pruebas de seguridad formales en `FS-2`/`FS-3` y sus controles quedaron `Implementado` en la consolidación de `FS-8`.

**Revisión 18/10/2026 (esta edición):** notas de contexto y precedencia (este README, `AGENTS.md` §1.1, `PROMPT_MASTER.md`); mapeo de evidencia en `docs/SECURITY_BASELINE.md` (Anexo §30), `docs/SECURITY_CONTROL_MATRIX.md` y `docs/SECURITY_TEST_PLAN.md` (§3.1); notas de vigencia en `docs/DATA_MODEL.md`, `docs/BUSINESS_RULES.md`, `docs/USERS_CONFIGURATION.md` y `docs/IMPLEMENTATION_ROADMAP.md`; lecturas obligatorias ampliadas en `.claude/skills/security-review/SKILL.md`.

**Ampliación (18/10/2026, plan de acción):** se agregan `docs/SECURITY_ACTION_PLAN.md` (fases `FS-0`–`FS-11`) y `docs/SECURITY_PHASE_PROMPTS.md` (prompts por fase). La fase `FS-5` (lote estático de repositorio y plataforma: SEC-011/013/032/034/036/037/039) quedó **ejecutada** el 18/10/2026 con evidencia en `docs/SECURITY_STATIC_EVIDENCE.md` (SEC-037 aprobado e implementado en CI el 18/10/2026 (commit `a176041`; canario verificado el 19/10/2026 (PR #2, job `118319199755`))) y la `FS-7` (casos de entorno) quedó **ejecutada** el 18/10/2026 (SEC-012/014/015/016/033/035/038; evidencia en `docs/SECURITY_ENVIRONMENT_EVIDENCE.md`), tras la `FS-6` **ejecutada** (SEC-001…010; evidencia en `docs/SECURITY_ACCESS_EVIDENCE.md`; suite **139/139**; analyze 0). La incorporación de esta carpeta al control de versiones (`FS-0`) quedó **ejecutada** el 18/10/2026 (commit `06e40f1`, 35 archivos). El triaje formal de los 40 casos (`FS-1`) quedó **publicado** el 18/10/2026 en `docs/SECURITY_TEST_PLAN.md` §3.2 (commit `e68b122`). Las mejoras de acceso del propietario (`FS-10` recordar usuario; `FS-11` huella, sin persistir la contraseña) quedaron registradas el 18/10/2026: `FS-10` está **ejecutada** (commit `36a6fea`; suite **80/80**; analyze 0) y `FS-11` también (**ejecutada**, commit `9d68f82`; suite **90/90**; analyze 0; build debug OK). Al retomar `FS-2`, la evaluación confirmó por pruebas tres defectos de integridad (H-1 venta con importes negativos; H-2 doble submit de compra duplicaba stock/Gasto/CxP; H-3 doble cobro concurrente registraba dos ventas) y la fase se detuvo sin commit; la fase de corrección `FS-2A` los resolvió (**ejecutada**, commit `1b1dbf6`; suite **97/97**; analyze 0) y la corrección de H-4 —imágenes sin tope de tamaño— quedó **ejecutada** en `FS-2B` (commit `09dea39`; suite **115/115**; analyze 0). La fase `FS-2` quedó **cerrada** el 18/10/2026 (commit `da97b2f`: pruebas permanentes de SEC-018 a SEC-028 — entradas inválidas, inyección SQL acotada, concurrencia de inventario y PDF/imagen corrupta —, SEC-026 re-ejecutado 3/3 y filas "Integridad POS" de la matriz con evidencia registrada; suite **110/110**; analyze 0). La fase `FS-3` (caja y ciclo operativo, SEC-029/030/031) quedó **ejecutada** el 18/10/2026 (commit `e9bce34`: reapertura no autorizada denegada sin cambios, cierre único ante doble envío secuencial/concurrente y reapertura autorizada auditada con actor, motivo, fecha/hora y ciclo previo; suite **123/123**; analyze 0). La fase `FS-4` (QR administrativo y cobro, SEC-022/023/024) quedó **ejecutada** el 18/10/2026 (commit `40dbc6c`: solo el rol administrador administra el QR, fallo de persistencia con rollback que conserva el previo + aviso, y fuente de verdad única consumida por el cobro; suite **129/129**; analyze 0), con procedimiento manual de cámara/galería para `FS-7`. Siguiente paso: `FS-5` (lote estático de repositorio y plataforma). `FS-6` corre después para evaluar el flujo de acceso final (usuario recordado + huella), y la validación real con huella en dispositivo queda agrupada en `FS-7`. El ciclo de evaluación quedó **cerrado en `FS-8`** el 18/10/2026: ratificaciones R-01…R-04, excepciones E-01…E-06, pendientes P-01…P-05 y estados finales en `docs/SECURITY_CLOSURE_REGISTER.md` (40/40 casos con disposición).
