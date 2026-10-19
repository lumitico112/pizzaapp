# KIMI PIZZA — Prompts de ejecución por fase (edición de seguridad)

**Versión:** 1.0 — 18/10/2026
**Compañero de:** `docs/SECURITY_ACTION_PLAN.md` (fases `FS-0`…`FS-11`)

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
Estado verificado del proyecto: auditoría técnica cerrada (C-01…C-31, H-01…H-13, fases F0–F15); suite 75/75; `flutter analyze` 0 issues; esquema v25; PRAGMA foreign_key_check = 0 filas. Commits recientes: a481045 (fix busy_timeout), 5cf6731 (caja), 32e2a79 (sobrantes), 032ee70 (bitácora), 06e40f1 (incorporación de la edición de seguridad, FS-0), e3ebc6d (bitácora de cierre de FS-0), e68b122 (triaje formal de los 40 casos, FS-1).
Edición de seguridad en `kimi_pizza_ai_framework_security/` (incorporada al control de versiones en `FS-0`, commit `06e40f1`; si apareciera sin trackear, detente y repórtalo antes de continuar).
Documento rector: `kimi_pizza_ai_framework_security/docs/SECURITY_ACTION_PLAN.md` — lee la sección de la fase a ejecutar y la sección 4 ("Reglas generales").
Reglas invariables: una fase por turno; no modificar `lib/` salvo que la fase lo autorice explícitamente; commits en ASCII sin acentos y SOLO locales (sin push); evidencia literal (comando + salida); no guardar secretos ni datos personales como evidencia; si una prueba revela un defecto real, DETENTE y repórtalo (no lo corrijas "de paso"); el agente no marca `Implementado`, no declara `No aplicable` ni acepta riesgo en nombre del propietario.
Entorno: Windows/PowerShell; en Flutter usar siempre `--no-pub`.
Informe final obligatorio: 1) qué se ejecutó (comandos literales); 2) resultado (fragmento literal, sanitizado); 3) casos cubiertos y estado propuesto por caso; 4) hallazgos y pendientes; 5) commit creado (hash + mensaje) o motivo de no crearlo.
```

## Prompt FS-0 — Incorporación al control de versiones

> **Ejecutada (18/10/2026):** commit `06e40f1` (35 archivos incorporados). Se conserva el prompt como referencia.

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

> **Ejecutada (18/10/2026):** commit `e68b122` (`SECURITY_TEST_PLAN.md` §3.2; 40 filas). Se conserva el prompt como referencia.

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

> **Cerrada (18/10/2026):** la ejecución inicial reveló defectos reales H-1 (SEC-019), H-2 (SEC-027) y H-3 (SEC-025) y la fase se detuvo sin commit; las correcciones se ejecutaron en `FS-2A`. Al retomar `FS-2` sobre el código corregido se añadieron las pruebas permanentes de los 8 casos (SEC-018…028), se re-ejecutó SEC-026 (3/3) y se registró la evidencia en la matriz; H-4 (SEC-021, imágenes sin tope) quedó reportado y se corrigió después en `FS-2B` (commit `09dea39`). Evidencia: suite **110/110**; analyze 0; commit `da97b2f`.

## Prompt FS-2A — Corrección de hallazgos de FS-2 (H-1 a H-3)

> **Ejecutada (18/10/2026):** commit `1b1dbf6` (código + pruebas; suite **97/97**; analyze 0) y commit de registro documental. Se conserva el prompt como referencia.

```text
TAREA (FS-2A — Corrección aprobada de los hallazgos H-1 a H-3 de FS-2):
1. H-1 (SEC-019): rechazar en la capa de dominio importes y cantidades negativos o no finitos (total de la venta, precio final de cada ítem, cantidad del detalle) y avisar en la UI del precio manual negativo. Referencias: `lib/services/pos_service.dart`, `lib/repositories/venta_repository.dart`, `lib/controllers/pos_controller.dart`, `lib/screens/pos/widgets/pos_item_detail_sheet.dart`.
2. H-2 (SEC-027): impedir el doble submit de compras y correcciones (guarda de reentrada en `lib/features/purchases/presentation/controllers/compras_controller.dart` + bandera local en `lib/screens/compras/compra_form_screen.dart`).
3. H-3 (SEC-025): impedir el doble cobro concurrente (guarda de reentrada en `PosController.procesarCobro`).
4. Pruebas de regresión permanentes en `test/` con datos sintéticos (una sola venta/movimiento/caja por cobro; una sola compra y una sola CxP por submit). H-4 (imágenes sin tope de tamaño/dimensiones) quedó fuera de alcance y reportado; corregido después en `FS-2B` (commit `09dea39`).
Restricciones: cambios mínimos en la capa correcta (presentación/controlador/servicio/repositorio); sin cambios de esquema ni migraciones; no tocar `android/`; no degradar los flujos con prueba existente.
Verificación obligatoria: `flutter test --no-pub` + `flutter analyze --no-pub` (evidencia literal con exit codes).
Evidencia: salida literal; rutas `test/…` de las pruebas nuevas.
Commit: `fix: valida importes de venta y evita doble submit de cobro y compra (H-1 a H-3)`.
```

## Prompt FS-2B — Corrección del hallazgo H-4 (SEC-021: límite de imágenes)

> **Ejecutada (18/10/2026):** commit `09dea39` (código + pruebas; suite **115/115**; analyze 0) y commit de registro documental. Se conserva el prompt como referencia.

```text
TAREA (FS-2B — Corrección aprobada del hallazgo H-4 de FS-2; SEC-021):
1. H-4: imponer límites a las imágenes capturadas/seleccionadas en `lib/services/image_service.dart`:
   a) Pasar `maxWidth: 1600` y `maxHeight: 1600` a ambos `pickImage` (mantener `imageQuality: 70`).
   b) Tope de bytes por archivo (sugerido: 5 MB): si el archivo excede el tope, borrarlo con `deleteLocalFile` y devolver `null` (mismo contrato que la cancelación; documentar que el rechazo es silencioso).
   c) Helper estático verificable para el tope (probar la frontera exacta).
2. Inyectar `ImagePicker` como parámetro opcional del constructor (`ImageService({ImagePicker? picker})`); los usos existentes `ImageService()` no cambian.
3. Barrido: sin `ImagePicker()` directo fuera del servicio (puntos de captura: `AppImagePicker` y pantallas de configuración, usuarios, productos, insumos, promociones, compras, activos y onboarding).
4. Pruebas permanentes en `test/imagenes_limite_seguridad_test.dart` (mocktail + archivos temporales): T1 imagen normal → ruta devuelta y parámetros de downscale verificados; T2 sobredimensionada → archivo borrado + `null`; T3 cancelación → `null`; T4 frontera del tope (exacto válido, +1 byte rechazado).
5. Actualizar al cerrar: sección `FS-2B` del plan, fila "PDF/documentos" de la matriz (sin H-4 abierto), README de la edición y `agent.md` (raíz).
Restricciones: cambios mínimos en el servicio compartido; sin cambios de esquema ni migraciones; no tocar `android/`; contrato `Future<String?>` intacto (`null` = cancelación o rechazo).
Valores sugeridos ajustables por el propietario: 1600 px de lado máximo y 5 MB por archivo.
Verificación obligatoria: `flutter test --no-pub` + `flutter analyze --no-pub` (evidencia literal con exit codes).
Evidencia: salida literal; rutas `test/…` de las pruebas nuevas; suite completa verde.
Commit: `fix: limita tamano y dimensiones de las imagenes capturadas (H-4)`.
```

## Prompt FS-3 — Caja y ciclo operativo

> **Ejecutada (18/10/2026):** commit `e9bce34` (pruebas; 1 archivo, 363 inserciones; suite **123/123**; analyze 0). Sin defectos y sin cambios en `lib/`. Se conserva el prompt como referencia.

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

> **Ejecutada (18/10/2026):** commit `40dbc6c` (pruebas; 1 archivo, 398 inserciones; suite **129/129**; analyze 0). Sin defectos y sin cambios en `lib/`; la parte con cámara/galería real queda como procedimiento manual para `FS-7`. Se conserva el prompt como referencia.

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

> **Ejecutada (18/10/2026) y reanudada el mismo día:** evidencia sanitizada en `docs/SECURITY_STATIC_EVIDENCE.md` (SEC-011/013/032/034/036/037/039). La reanudación implementó SEC-037 con aprobación del propietario (commit `ci:` `a176041`; Gitleaks v3 + OSV-Scanner reusable v2.7.0; YAML validado localmente; canario de aceptación pendiente del primer push). SEC-036: 121 paquetes hosted, 0 advisories OSV. Se conserva el prompt como referencia.

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

> **Ejecutada (18/10/2026):** commit de pruebas `a482224`; evidencia por caso en `docs/SECURITY_ACCESS_EVIDENCE.md`. Suite nueva `test/acceso_cuentas_sesion_seguridad_test.dart` (10 pruebas, SEC-001…SEC-010); sin cambios en `lib/`. Gate: `flutter test --no-pub` → **139/139** (`All tests passed!`) y `flutter analyze --no-pub` → `No issues found!`. Residuales sin aceptar: SEC-002 (bloqueo en memoria/sin auditoría), SEC-005 (sesión abierta no revalidada por operación), SEC-006 (guarda de ruta solo de sesión), SEC-007/008 (límite local-only) y observaciones de SEC-010 (autodemoción/auditoría de alta y edición). Se conserva el prompt como referencia.

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

> **En ejecución parcial (18/10/2026):** la fase se detuvo al hallar `DEF-FS7-01` (cancelar el diálogo de contraseña del respaldo rompía la app en debug); la corrección se ejecutó en `FS-7A` y la fase se reanudará con SEC-014/038 y el APK release firmado. Evidencia parcial: dispositivo Motorola Edge 60 Fusion (Android 16/API 36), huella `FS-11` aceptada/cancelada/revocada, QR por galería y cámara, permisos efectivos (`READ_MEDIA_*` declarados por `open_filex` y no concedidos) y copia automática `.kpzlocal` con cabecera `KPZB v1` + AES-GCM sin marcadores en claro. Se conserva el prompt como referencia.

## Prompt FS-7A — Corrección: ciclo de vida del diálogo de la copia portátil

> **Ejecutada (18/10/2026):** corrección + regresión en `5cb05f0`; cierre documental en el commit de documentación de `FS-7A`. Gate: `flutter test --no-pub` → **144/144** (`All tests passed!`) y `flutter analyze --no-pub` → `No issues found!`. Se conserva el prompt como referencia.

```text
TAREA (FS-7A — Corrección de DEF-FS7-01; desbloquea SEC-014/SEC-038):
1. Reproducir el defecto con una prueba de widget (TDD): abrir el diálogo de exportación de respaldo, cancelar y comprobar que `tester.takeException()` no es nulo por `A TextEditingController was used after being disposed` y la aserción `_dependents.isEmpty`.
2. Extraer el diálogo a un `StatefulWidget` que cree y libere sus `TextEditingController` en `dispose()` (la ruta los necesita durante la animación de salida); delegar desde `_requestPassword` y mantener la política de 12 caracteres en el llamador.
3. Validar los campos con `errorText` propio del diálogo (no SnackBar con el contexto de la pantalla).
4. Pruebas: cancelación limpia, cancelación tras contraseñas dispares, contraseña válida devuelta, cancelación devuelve null y campos vacíos rechazados.
Restricciones: sin cambios de esquema ni de dependencias; no tocar el flujo de cifrado del respaldo.
Verificación obligatoria: `flutter test --no-pub` + `flutter analyze --no-pub` (evidencia literal).
Evidencia: salida literal y rutas de las pruebas; actualizar plan, prompts, plan de pruebas, matriz, README y `agent.md`.
Commit: `fix: libera controladores del dialogo de respaldo tras la salida (FS-7A)`.
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

## Prompt FS-10 — Mejoras de acceso: recordar usuario (Fase A)

> **Ejecutada (18/10/2026):** commit `36a6fea` (suite **80/80**; analyze 0). Se conserva el prompt como referencia.

```text
TAREA (FS-10 — Recordar usuario; decisión del propietario: "usuario + huella, sin contraseña"):
1. Crea `lib/core/storage/secure_auth_store.dart` sobre `flutter_secure_storage` (Keystore/Keychain): guarda SOLO `username` + `user_id`; NUNCA la contraseña (regla dura S3). Métodos: guardar/leer/limpiar.
2. `lib/screens/auth/login_screen.dart`: checkbox "Recordar usuario" (objetivo táctil >= 48 px), autocompletado del nombre al abrir la pantalla y registro de la decisión tras un login exitoso; un fallo del almacén seguro NO bloquea el acceso (se continúa al Dashboard).
3. `lib/controllers/auth_controller.dart`: extensión con parámetros opcionales en el constructor (compatibilidad con las construcciones existentes en `test/`).
4. `test/auth_remember_test.dart`: guardado/lectura/limpieza, prefill, decisión marcado/desmarcado y verificación de que solo se persisten `username`/`user_id` (usar `FlutterSecureStorage.setMockInitialValues`).
Restricciones: no tocar la validación de acceso (la revalidación `activo = 1 AND bloqueado = 0` del usuario recordado se aplica en FS-11 al restaurar la sesión); sin dependencias nuevas en esta fase.
Verificación obligatoria: `flutter test --no-pub` + `flutter analyze --no-pub` (evidencia literal).
Commit: `feat: recordar usuario con almacenamiento seguro y autocompletado en login`.
```

## Prompt FS-11 — Mejoras de acceso: huella (Fase B)

> **Ejecutada (18/10/2026):** commit `9d68f82` (suite **90/90**; analyze 0; `main` sin `INTERNET` y build debug OK). La validación real con huella en dispositivo queda agrupada en `FS-7`. Se conserva el prompt como referencia.

```text
TAREA (FS-11 — Acceso rápido con huella para el usuario recordado; se ejecuta después de FS-10):
1. Dependencia `local_auth` ^3.0.2 (revisión S8: mantenimiento, permisos, código nativo); ajustes Android: `MainActivity` → `FlutterFragmentActivity`, permiso `USE_BIOMETRIC`, verificación del tema AppCompat de la actividad (minSdk 24 ya cumplido).
2. `lib/services/biometric_auth_service.dart` (wrapper testeable con fakes) y `AuthService.loginRapido()`: restaurar la sesión del `user_id` recordado SOLO si la consulta valida `activo = 1 AND bloqueado = 0` (denegar en caso contrario).
3. UI: acceso con huella visible únicamente si existe usuario recordado y la biometría está disponible/enrolada; si la huella falla o se cancela, se vuelve al login con contraseña. NUNCA se persiste la contraseña.
4. El logout REVOCA el acceso rápido (se borra el permiso de huella); para reactivarlo: login con contraseña + marcarlo de nuevo.
5. Pruebas de escritorio con fakes; la validación real en dispositivo se agrupa con FS-7 cuando haya entorno (hoy bloqueado).
Límite declarado (S2): la huella es un candado de conveniencia contra el acceso físico casual; no protege contra root/APK modificado ni sustituye la contraseña como credencial.
Verificación obligatoria: `flutter test --no-pub` + `flutter analyze --no-pub`.
Commit: `feat: acceso rapido con huella para el usuario recordado`.
```

---

**Regla final:** cada informe se archiva actualizando el Anexo B de `docs/SECURITY_ACTION_PLAN.md` (estado, commit, fecha de la fase). Si un gate falla, la fase queda abierta; no se avanza a la siguiente.

*Fin de los prompts.*
