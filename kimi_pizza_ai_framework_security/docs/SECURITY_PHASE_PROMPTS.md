# KIMI PIZZA — Prompts de ejecución por fase (edición de seguridad)

**Versión:** 1.0 — 18/10/2026
**Compañero de:** `docs/SECURITY_ACTION_PLAN.md` (fases `FS-0`…`FS-9`)

Este archivo contiene un prompt listo para copiar, uno por fase. El plan de acción define **qué** hace cada fase; aquí está el **cómo pedirlo** a un agente.

## Cómo usarlos

1. Copia el **bloque de contexto común** (abajo) y añádele debajo el **bloque de la fase** deseada.
2. Pega todo en el agente (con acceso al repositorio local).
3. Exige el **informe final** de 5 puntos (definido en el contexto común).
4. Revisa el informe: **tú aprobás** los commits, los estados y cualquier excepción de riesgo.
5. Una fase por turno. Si un gate falla, la fase se detiene.

## Bloque de contexto común (incluir siempre)

```text
Contexto: trabajas en el repositorio local `C:\D\ProyectoPizza\pizzaapp`, rama `refactor/auditoria-2026-10`.
Estado verificado del proyecto: auditoría técnica cerrada (C-01…C-31, H-01…H-13, fases F0–F15); suite 75/75; `flutter analyze` 0 issues; esquema v25; PRAGMA foreign_key_check = 0 filas. Commits recientes: a481045 (fix busy_timeout), 5cf6731 (caja), 32e2a79 (sobrantes), 032ee70 (bitácora).
Edición de seguridad en `kimi_pizza_ai_framework_security/` (si figura como carpeta sin trackear, es lo esperado hasta que se ejecute FS-0).
Documento rector: `kimi_pizza_ai_framework_security/docs/SECURITY_ACTION_PLAN.md` — lee la sección de la fase a ejecutar y la sección 4 ("Reglas generales").
Reglas invariables: una fase por turno; no modificar `lib/` salvo que la fase lo autorice explícitamente; commits en ASCII sin acentos y SOLO locales (sin push); evidencia literal (comando + salida); no guardar secretos ni datos personales como evidencia; si una prueba revela un defecto real, DETENTE y repórtalo (no lo corrijas "de paso"); el agente no marca `Implementado`, no declara `No aplicable` ni acepta riesgo en nombre del propietario.
Entorno: Windows/PowerShell; en Flutter usar siempre `--no-pub`.
Informe final obligatorio: 1) qué se ejecutó (comandos literales); 2) resultado (fragmento literal, sanitizado); 3) casos cubiertos y estado propuesto por caso; 4) hallazgos y pendientes; 5) commit creado (hash + mensaje) o motivo de no crearlo.
```

## Prompt FS-0 — Incorporación al control de versiones

```text
TAREA (FS-0 — Incorporación al control de versiones):
1. Ejecuta `git status` y revisa visualmente `kimi_pizza_ai_framework_security/`: no debe haber temporales, capturas con datos reales, claves ni secretos. Lista cualquier archivo sospechoso y detente si existe.
2. Solo si el propietario lo autorizó: añade un puntero de una línea en `README.md` de la raíz hacia la edición de seguridad.
3. Ejecuta `git add kimi_pizza_ai_framework_security` y crea el commit `docs: incorpora la edicion de seguridad alineada al estado post-correccion`.
4. Actualiza en `agent.md` (raíz) la entrada del 18/10/2026 sobre la carpeta: de "SIN trackear" a "incorporada" (con el hash). Si prefieres un commit separado para la bitácora, pídelo antes.
Restricciones: no tocar `lib/` ni `test/`; no modificar el contenido de la carpeta (solo agregarla a git).
Evidencia: `git status --short`, `git log --oneline -3`, `git show --stat HEAD`.
Parada: si el `add` incluye archivos fuera de la carpeta o aparece cualquier dato sensible, detente y reporta.
```

## Prompt FS-1 — Triaje formal del catálogo de casos

```text
TAREA (FS-1 — Triaje formal):
1. Lee `docs/SECURITY_TEST_PLAN.md` §3 (casos SEC-001…SEC-040) y §3.1, y el Anexo A de `docs/SECURITY_ACTION_PLAN.md` (borrador de mapeo).
2. Añade en `docs/SECURITY_TEST_PLAN.md` una sección §3.2 "Triaje de ejecución" con una fila por caso: ID, disposición (`Ejecutable en escritorio` / `Requiere dispositivo/keystore` / `No aplicable hoy (justificación)` / `Cubierto por automatización (re-ejecutar)`), fase destino (FS-2…FS-7) y nota breve.
3. Revisa caso por caso contra el estado real del proyecto (no copies a ciegas el Anexo A: confirma con los documentos citados en §3.1).
Restricciones: no cambies los estados de `SECURITY_CONTROL_MATRIX.md`; no ejecutes casos todavía; no marques nada como evaluado.
Evidencia: diff de §3.2 con el conteo final (deben ser 40 filas).
Commit: `docs: triaje formal del catalogo de casos de seguridad`.
Parada: si detectas contradicciones entre §3.1 y el Anexo A, resuélvelas a favor de la evidencia real y repórtalas.
```

## Prompt FS-2 — Integridad: ventas, boleta e inventario

```text
TAREA (FS-2 — Integridad transaccional; casos SEC-018, SEC-019, SEC-020, SEC-021, SEC-025, SEC-026, SEC-027, SEC-028):
1. Empieza por SEC-025: busca si ya existe una prueba de doble toque/reintento de "Cobrar". Si no existe, escribe una prueba dedicada en `test/` (nombre descriptivo, p. ej. `test/cobro_idempotencia_seguridad_test.dart`) usando el arnés existente (mira `test/pos_boleta_resiliencia_test.dart` y `test/anular_editar_ventas_test.dart` como referencia). Verifica: una sola venta, un solo movimiento de stock, un solo registro en caja.
2. SEC-026: re-ejecuta formalmente la prueba de resiliencia de boleta y registra la salida como evidencia (fallo de PDF no duplica la venta).
3. SEC-027: prueba de doble submit/reintento de compra → sin duplicar entrada de stock ni cuenta por pagar.
4. SEC-028: prueba de venta/merma/transformación concurrente → sin doble descuento (fuente única: `StockMovementWriter`).
5. SEC-018/019: pruebas de entradas extremas/negativas rechazadas por dominio (sin crash, sin estado parcial).
6. SEC-020: barrido de consultas parametrizadas en repositorios + prueba acotada con caracteres de inyección.
7. SEC-021: prueba de PDF/imagen corrupta o sobre-dimensionada rechazada con error seguro.
Restricciones: NO modifiques `lib/`; si una prueba revela un defecto real, detente y repórtalo con la traza (la corrección será otra fase). Datos sintéticos únicamente.
Verificación obligatoria: `flutter test --no-pub` (suite completa, evidencia literal del resultado final) y `flutter analyze --no-pub` (0 issues).
Evidencia: salida literal (exit codes), rutas de pruebas nuevas, y propuesta de actualización de las filas "Integridad POS: venta / inventario / PDF" de la matriz a "Evidencia registrada".
Commit: `test: cubre integridad de ventas e inventario (SEC-018 a SEC-028)`.
```

## Prompt FS-3 — Caja y ciclo operativo

```text
TAREA (FS-3 — Caja; casos SEC-029, SEC-030, SEC-031):
1. SEC-029: prueba de reapertura excepcional sin autorización → denegada, sin cambios.
2. SEC-030: prueba de cierre enviado dos veces → un solo cierre/ciclo.
3. SEC-031: prueba de reapertura autorizada → registra fecha/hora, actor, motivo y referencia al ciclo anterior (auditoría).
Referencias: `test/caja_arqueo_repo_test.dart`, `test/gastos_movimiento_caja_test.dart`, RN-04 y RN-06. El trabajo de caja ya está commiteado (commit 5cf6731).
Restricciones: NO modifiques `lib/`; si una prueba revela un defecto, detente y reporta.
Verificación obligatoria: `flutter test --no-pub` + `flutter analyze --no-pub` (evidencia literal).
Evidencia: salida literal, rutas de pruebas, y propuesta de actualización de la fila "Integridad POS: caja" de la matriz.
Commit: `test: cubre caja y ciclo operativo (SEC-029, SEC-030, SEC-031)`.
```

## Prompt FS-4 — QR administrativo y cobro

```text
TAREA (FS-4 — QR; casos SEC-022, SEC-023, SEC-024):
1. Inspecciona el flujo real del QR de cobro: pantalla de configuración, validación de rol, servicio de guardado, persistencia y consumo en el cobro (Yape/Plin). Documenta el recorrido con `archivo:línea`.
2. Escribe pruebas donde la infraestructura lo permita (sin cámara/galería real): SEC-022 (role no autorizado no cambia el QR), SEC-023 (fallo al persistir conserva el QR previo y avisa al usuario), SEC-024 (el cobro usa la fuente de verdad verificada, no un archivo temporal obsoleto).
3. Lo que dependa de interfaz/dispositivo real, redáctalo como procedimiento manual (pasos + resultado esperado) para ejecutarlo en FS-7; sin datos reales de pago.
Restricciones: NO modifiques `lib/`; si detectas un defecto, detente y reporta.
Verificación obligatoria: `flutter test --no-pub` + `flutter analyze --no-pub` (evidencia literal).
Evidencia: salida literal, rutas de pruebas o procedimiento, inspección `archivo:línea` y propuesta de actualización de la fila "Integridad QR" de la matriz.
Commit: `test: cubre flujo QR administrativo y de cobro (SEC-022, SEC-023, SEC-024)`.
```

## Prompt FS-5 — Lote estático de repositorio y plataforma

```text
TAREA (FS-5 — Estático; casos SEC-011, SEC-013, SEC-032, SEC-034, SEC-036, SEC-037, SEC-039):
1. SEC-011: secret scanning del árbol y de la historia. Si `gitleaks` (u otra herramienta) está instalada, úsala; si no, barrido por patrones sobre archivos versionados y documenta la limitación. Nunca uses valores reales de prueba.
2. SEC-036: `flutter pub deps --style=compact` como inventario; revisión de advisories solo con lo disponible offline (documenta la limitación si no hay red).
3. SEC-037: redacta una PROPUESTA de job de secret scanning con canario para `.github/workflows/ci.yml`. NO modifiques el workflow sin aprobación explícita; si se aprueba, va en commit `ci:` separado.
4. SEC-034: revisión completa de `AndroidManifest.xml` (components, `exported`, permisos, intents) y reglas de backup (`data_extraction_rules`/`backup_rules`).
5. SEC-039: deep links/intents: ausencia o validación previa. 6. SEC-032: barrido de logs por patrones sensibles en `lib/`. 7. SEC-013 (estático): persistencia local (preferencias, temporales, PDFs, fotos) sin credenciales en claro.
Restricciones: solo lectura sobre `lib/` y `android/`; toda salida se registra sanitizada (sin secretos ni datos personales).
Evidencia: comando + salida por caso y propuesta de actualización de las filas correspondientes de la matriz.
Commit: `docs: evidencia estatica de repositorio y plataforma (SEC-011 a SEC-039)`.
```

## Prompt FS-6 — Acceso, cuentas y sesión

```text
TAREA (FS-6 — Acceso; casos SEC-001…SEC-010):
1. SEC-001/002: prueba de login inválido y de repetición rápida de intentos. Busca si existe mitigación (retardo/contador) en el flujo de login; si no existe, repórtalo como hallazgo con propuesta (contador + retardo) — NO implementes sin aprobación.
2. SEC-003/004 (adaptados): sesión local sin tokens remotos; verifica limpieza de estado en `logout()` (C-18).
3. SEC-005: cuenta desactivada/bloqueada no accede (RN-10/RN-11).
4. SEC-006: rol empleado en ruta admin → UI y guardas rechazan (usa `test/router_guards_test.dart` como referencia).
5. SEC-007/008: manipulación de rol/IDs locales; documenta el límite de defensa local-only (S2 de `AGENTS.md` de la edición).
6. SEC-009/010: ciclo de usuarios (alta/baja, última cuenta admin) con auditoría y sin auto-baja.
Restricciones: NO modifiques `lib/`; hallazgos reportados, no corregidos "de paso".
Verificación obligatoria: `flutter test --no-pub` + `flutter analyze --no-pub` (evidencia literal).
Evidencia: salida literal, rutas de pruebas y propuesta de actualización de las filas de acceso/identidades de la matriz.
Commit: `test: cubre acceso, cuentas y sesion (SEC-001 a SEC-010)`.
```

## Prompt FS-7 — Casos dependientes de entorno

```text
TAREA (FS-7 — Entorno; casos SEC-012, SEC-014, SEC-015, SEC-016, SEC-033, SEC-035, SEC-038):
1. Diagnóstico de entorno: `flutter devices`, `flutter emulators`, `Test-Path android/key.properties`. No descargues imágenes de sistema ni crees keystores sin autorización explícita.
2. Si hay dispositivo/emulador disponible: ejecuta los procedimientos (SEC-014 backup/restore; SEC-015/016 release sin red; SEC-033 permisos; SEC-035 artefacto firmado; SEC-012 inspección de APK; SEC-038 exportaciones) y registra evidencia redactada.
3. Si no hay entorno: registra cada caso como "Bloqueado por entorno" con el intento (comando + error literal) y las precondiciones faltantes.
Restricciones: pruebas no destructivas; nunca usar datos reales de producción; no aceptar riesgo pendiente.
Evidencia: diagnóstico literal + resultado o bloqueo por caso; propuesta de actualización de las filas correspondientes de la matriz.
Commit: `docs: casos de seguridad dependientes de entorno (SEC-012, 014, 015, 016, 033, 035, 038)`.
```

## Prompt FS-8 — No aplicables y cierre del ciclo

```text
TAREA (FS-8 — Cierre; casos SEC-017, SEC-040 + ratificaciones):
1. Prepara el paquete de cierre: para cada caso con "Evidencia registrada" en las fases previas, redacta su entrada del "Registro de evaluación por control" (fecha/commit, ruta de evidencia, herramienta y versión, resultado, limitaciones, riesgo residual).
2. Formaliza las propuestas de `No aplicable` (SEC-017/040: sin backend/sync hoy) y las ratificaciones pendientes — cada una requiere aprobación explícita del propietario; sin firma, quedan `Pendiente`.
3. Consolida en `SECURITY_CONTROL_MATRIX.md` los estados finales y en `SECURITY_TEST_PLAN.md` (§3.1/§3.2) la cobertura cerrada; actualiza el "Estado de la evaluación" del `README.md` y la bitácora `agent.md` (raíz).
4. Revisión final: ningún caso sin disposición; lista expresa de excepciones aceptadas (dueño, compensación, expiración) si existen.
Restricciones: no cambiar estados sin evidencia y sin decisión del propietario; no cerrar con ambigüedades.
Evidencia: tabla final caso → estado → evidencia; diff de los documentos actualizados.
Commit: `docs: cierre del ciclo de evaluacion de seguridad`.
```

## Prompt FS-9 — Backlog opcional

```text
TAREA (FS-9 — Backlog opcional, solo cuando el propietario lo pida):
1. Sincronizar `kimi_pizza_ai_framework/PROMPT_MASTER.md` §5 (anexo) y `docs/DATA_MODEL.md` (diccionario) contra `lib/core/database/db_schema.dart` (v25): reporta diferencias antes de editar.
2. Añadir prueba para la semántica "conservar el sobrante en preparación cuando no es cierre de ciclo" (commit 32e2a79), con la misma disciplina de FS-2/FS-3.
3. Cualquier puntero pendiente en el `README.md` de la raíz.
Verificación obligatoria si se toca `lib/` o `test/`: `flutter test --no-pub` + `flutter analyze --no-pub`.
Commits: según unidad (`docs:` / `test:`), aprobado por el propietario.
```

---

**Regla final:** cada informe se archiva actualizando el Anexo B de `docs/SECURITY_ACTION_PLAN.md` (estado, commit, fecha de la fase). Si un gate falla, la fase queda abierta; no se avanza a la siguiente.

*Fin de los prompts.*
