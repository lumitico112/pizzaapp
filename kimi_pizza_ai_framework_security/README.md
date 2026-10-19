# KIMI PIZZA — AI Engineering Framework (Edición de Seguridad)

**Edición de seguridad — 18/10/2026.** Framework de trabajo para desarrollar, mantener, depurar y evolucionar la aplicación Flutter KIMI PIZZA, con foco en **ingeniería segura** (ISO/IEC 27001:2022 / 27002:2022 y OWASP MASVS/MASTG) e **integridad del POS**.

## Contexto y precedencia (obligatorio)

- El **estado verificado y autoritativo** del proyecto vive en el `AGENTS.md` de la raíz del repositorio y en `kimi_pizza_ai_framework/` (auditoría `C-01`…`C-31`; plan `H-01`…`H-13` ejecutado en fases `F0`–`F15`; suite **75/75**; `flutter analyze` **0 issues**; esquema **v25**).
- Esta carpeta es la **edición de seguridad**: línea base, matriz de controles, plan de pruebas y Skills de trabajo. **Donde haya conflicto, prevalece el framework principal.**
- Los documentos de dominio aquí incluidos son referencia de diseño (08/10/2026); el detalle vigente (esquema físico v25, 37 tablas) está en `kimi_pizza_ai_framework/docs/DATA_MODEL.md` y `lib/core/database/db_schema.dart`.
- **Estado de la evaluación de seguridad:** preparación completa — **evidencia inicial mapeada** (ver "Evidencia inicial del proyecto" en `docs/SECURITY_CONTROL_MATRIX.md` y la cobertura en `docs/SECURITY_TEST_PLAN.md` §3.1) y **triaje de los 40 casos publicado** (§3.2; fase `FS-1`). La fase `FS-2` quedó **cerrada** el 18/10/2026 sobre el código corregido en `FS-2A` (pruebas permanentes de SEC-018 a SEC-028, SEC-026 re-ejecutado 3/3, suite **110/110**; H-4 reportado). Siguiente: `FS-3`. Ningún control se considera evaluado sin re-ejecución, evidencia y revisor.
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

**Estado de la evaluación (18/10/2026):** preparación completa — evidencia inicial mapeada, triaje de los 40 casos publicado, mejoras de acceso `FS-10`/`FS-11` ejecutadas y fase `FS-2` **cerrada** sobre el código corregido en `FS-2A` (pruebas permanentes de SEC-018 a SEC-028, SEC-026 re-ejecutado 3/3, filas "Integridad POS" de la matriz con evidencia registrada; suite **110/110**; H-4 queda reportado); siguiente: `FS-3` (caja y ciclo operativo):

- `docs/SECURITY_CONTROL_MATRIX.md` → sección "Evidencia inicial del proyecto (18/10/2026)" (control → evidencia → pendiente).
- `docs/SECURITY_TEST_PLAN.md` → sección 3.1 "Cobertura inicial del proyecto" (casos SEC cubiertos o parcialmente cubiertos) y §3.2 "Triaje de ejecución" (40 filas; `FS-1`).
- `docs/SECURITY_ACTION_PLAN.md` → fases `FS-0`–`FS-11` (reglas generales, evidencia y gates por fase); `docs/SECURITY_PHASE_PROMPTS.md` → prompts de ejecución, uno por fase.

Varios casos de integridad del POS (venta/inventario/caja) cruzan con correcciones ya cerradas de la auditoría (`H-05`, `H-07`, `RN-02`…`RN-04`); deben re-ejecutarse como pruebas de seguridad formales antes de marcar un control como implementado.

**Revisión 18/10/2026 (esta edición):** notas de contexto y precedencia (este README, `AGENTS.md` §1.1, `PROMPT_MASTER.md`); mapeo de evidencia en `docs/SECURITY_BASELINE.md` (Anexo §30), `docs/SECURITY_CONTROL_MATRIX.md` y `docs/SECURITY_TEST_PLAN.md` (§3.1); notas de vigencia en `docs/DATA_MODEL.md`, `docs/BUSINESS_RULES.md`, `docs/USERS_CONFIGURATION.md` y `docs/IMPLEMENTATION_ROADMAP.md`; lecturas obligatorias ampliadas en `.claude/skills/security-review/SKILL.md`.

**Ampliación (18/10/2026, plan de acción):** se agregan `docs/SECURITY_ACTION_PLAN.md` (fases `FS-0`–`FS-11`) y `docs/SECURITY_PHASE_PROMPTS.md` (prompts por fase). La incorporación de esta carpeta al control de versiones (`FS-0`) quedó **ejecutada** el 18/10/2026 (commit `06e40f1`, 35 archivos). El triaje formal de los 40 casos (`FS-1`) quedó **publicado** el 18/10/2026 en `docs/SECURITY_TEST_PLAN.md` §3.2 (commit `e68b122`). Las mejoras de acceso del propietario (`FS-10` recordar usuario; `FS-11` huella, sin persistir la contraseña) quedaron registradas el 18/10/2026: `FS-10` está **ejecutada** (commit `36a6fea`; suite **80/80**; analyze 0) y `FS-11` también (**ejecutada**, commit `9d68f82`; suite **90/90**; analyze 0; build debug OK). Al retomar `FS-2`, la evaluación confirmó por pruebas tres defectos de integridad (H-1 venta con importes negativos; H-2 doble submit de compra duplicaba stock/Gasto/CxP; H-3 doble cobro concurrente registraba dos ventas) y la fase se detuvo sin commit; la fase de corrección `FS-2A` los resolvió (**ejecutada**, commit `1b1dbf6`; suite **97/97**; analyze 0; H-4 —imágenes sin tope de tamaño— queda reportado, con su corrección agendada en `FS-2B` mediante prompt preparado el 18/10/2026). La fase `FS-2` quedó **cerrada** el 18/10/2026 (commit `da97b2f`: pruebas permanentes de SEC-018 a SEC-028 — entradas inválidas, inyección SQL acotada, concurrencia de inventario y PDF/imagen corrupta —, SEC-026 re-ejecutado 3/3 y filas "Integridad POS" de la matriz con evidencia registrada; suite **110/110**; analyze 0). Siguiente paso: `FS-3` (caja y ciclo operativo). `FS-6` corre después para evaluar el flujo de acceso final (usuario recordado + huella), y la validación real con huella en dispositivo queda agrupada en `FS-7`.
