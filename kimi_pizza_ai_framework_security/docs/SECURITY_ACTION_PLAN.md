# KIMI PIZZA — Plan de acción de la evaluación de seguridad

**Versión:** 1.0 — 18/10/2026
**Edición:** `kimi_pizza_ai_framework_security/` (edición de seguridad)
**Prompts de ejecución:** `docs/SECURITY_PHASE_PROMPTS.md` (un prompt listo por fase)

> **Precedencia:** ante cualquier conflicto prevalece el framework principal (`AGENTS.md` de la raíz del repositorio y `kimi_pizza_ai_framework/`). Este plan organiza trabajo y evidencia; **no** certifica cumplimiento ISO/IEC 27001/27002 ni OWASP MASVS.

---

## 1. Propósito

Convertir la planificación de seguridad de esta edición (`docs/SECURITY_BASELINE.md`, `docs/SECURITY_CONTROL_MATRIX.md`, `docs/SECURITY_TEST_PLAN.md`) en **ejecución verificable por fases**, y formalizar la incorporación de esta carpeta al control de versiones del repositorio.

Los prompts para ejecutar cada fase con un agente están en `docs/SECURITY_PHASE_PROMPTS.md`.

## 2. Estado de partida (18/10/2026)

- Auditoría técnica cerrada y verificada (`C-01`…`C-31`; `H-01`…`H-13`; fases `F0`–`F15`): suite **75/75**; `flutter analyze` **0 issues**; esquema **v25**; `PRAGMA foreign_key_check` = 0 filas.
- Trabajo pendiente del árbol, verificado y commiteado (recomendación 1, ejecutada):
  - `a481045` — `fix: usa rawQuery para PRAGMA busy_timeout en Android/SQLCipher`;
  - `5cf6731` — `feat: rediseno de la pantalla de caja (apertura, movimiento manual, animaciones)`;
  - `32e2a79` — `feat: conserva el sobrante en preparacion cuando no es cierre de ciclo`;
  - `032ee70` — `docs: bitacora de cierre del fix busy_timeout y las mejoras de caja y sobrantes`.
- Esta carpeta quedó **incorporada al control de versiones** el 18/10/2026 (commit `06e40f1`; fase `FS-0`; 35 archivos, 6264 inserciones).
- El **triaje formal de los 40 casos** quedó publicado el 18/10/2026 (`docs/SECURITY_TEST_PLAN.md` §3.2; fase `FS-1`; commit `e68b122`): 30 ejecutables en escritorio, 1 cubierto por automatización (a re-ejecutar, `SEC-026`), 7 con requisito de dispositivo/keystore (agrupados en `FS-7`) y 2 no aplicables hoy (a ratificar en `FS-8`).
- **Mejoras de acceso aprobadas por el propietario** (18/10/2026, decisión registrada): iniciar sesión con **usuario recordado + huella**, **sin persistir la contraseña**; el logout revoca el acceso rápido (se borra el permiso de huella; reactivarlo exige login con contraseña + marcarlo). Registradas como `FS-10` (recordar usuario) y `FS-11` (huella), con ejecución previa a retomar la evaluación.
- Evidencia inicial de seguridad mapeada, **nada evaluado formalmente**: `docs/SECURITY_TEST_PLAN.md` §3.1 (17 filas) y `docs/SECURITY_CONTROL_MATRIX.md` → "Evidencia inicial del proyecto (18/10/2026)" (24 filas control → evidencia → pendiente).
- Pendientes de entorno (no de código): dispositivo/emulador para cifrado/instalación/restore (`F11(e)`, `F12(d)`) y ruta positiva de release firmado (requiere keystore propio). Agrupados en `FS-7`.

## 3. Recomendaciones → fases

| Recomendación del 18/10/2026 | Fase(s) | Estado |
|---|---|---|
| 1. Verificar y commitear el trabajo pendiente del árbol | — | ✅ Ejecutada (`a481045`, `5cf6731`, `32e2a79`, `032ee70`) |
| 2. Incorporar la edición de seguridad al control de versiones | `FS-0` | ✅ Ejecutada (commit `06e40f1`) |
| 3. Ejecutar la evaluación de seguridad por lotes (primero los casos sin dispositivo) | `FS-1`…`FS-8` | En ejecución — `FS-1` ✅ (triaje); mejoras de acceso `FS-10`/`FS-11` ✅; `FS-2` ✅ reanudada y cerrada sobre el código corregido (pruebas permanentes SEC-018…028; SEC-026 re-ejecutado 3/3; suite 110/110); `FS-3` ✅ (caja y ciclo operativo, SEC-029/030/031; suite 123/123); siguiente: `FS-4` |
| Mejoras de acceso aprobadas por el propietario (usuario recordado + huella, sin contraseña) | `FS-10`, `FS-11` | `FS-10` ✅ (commit `36a6fea`) y `FS-11` ✅ (commit `9d68f82`; validación en dispositivo en `FS-7`) |
| Backlog opcional no bloqueante (sin impacto en seguridad) | `FS-9` | Opcional |

**Orden elegido:** primero el núcleo financiero (integridad de ventas e inventario), luego caja, QR, lote estático y acceso/cuentas; los casos que dependen de dispositivo o keystore se agrupan en `FS-7` y no bloquean al resto; `FS-8` cierra el ciclo. `FS-1` fija el triaje de los 40 casos antes de ejecutar. **Ampliación (18/10/2026):** las mejoras de acceso del propietario (`FS-10` recordar usuario; `FS-11` huella) se ejecutan después de `FS-1` y antes de retomar `FS-2`; `FS-6` se ejecuta después de ambas para evaluar el flujo de acceso final.

## 4. Reglas generales (aplican a toda fase)

1. **Una fase por turno.** No adelantar trabajo de fases siguientes.
2. **Verificación:** si la fase toca `lib/` o `test/` → `flutter test --no-pub` y `flutter analyze --no-pub` con evidencia literal (exit code). Si es solo documentación → no es obligatoria; dejar constancia de la decisión y mostrar `git status`.
3. **Evidencia por caso** (según "Registro de evaluación por control" de `SECURITY_CONTROL_MATRIX.md`): fecha y commit; ruta de evidencia; herramienta y versión; resultado; limitaciones; riesgo residual; revisor. Nunca guardar secretos, tokens ni datos personales como evidencia.
4. **Estados:** `Pendiente → En ejecución → Evidencia registrada → (decisión del propietario) Implementado / Parcial / Excepción aceptada / No aplicable`. El agente **no** marca `Implementado`, no declara `No aplicable` ni acepta riesgo en nombre del propietario.
5. **Hallazgos:** si una prueba revela un defecto real, la fase **se detiene y lo reporta**; la corrección es una fase nueva, aprobada, con su propio gate (no se corrige "de paso").
6. **Commits:** uno por fase; mensaje en **ASCII sin acentos**; **solo local, sin push**; sin tocar archivos ajenos a la fase.
7. **Guards técnicos vigentes:** esquema v25; `PRAGMA foreign_key_check` = 0 filas; sin dependencias de red nuevas; stack intacto (`Provider` + `sqflite_sqlcipher`).
8. **Qué NO hacer:** no fusionar esta edición con `kimi_pizza_ai_framework/` (decisión diferida); no afirmar conformidad ISO/MASVS por pasar pruebas; no ejecutar pruebas destructivas; no ocultar hallazgos.

## 5. Fases

### FS-0 — Incorporación al control de versiones (recomendación 2)

**Tipo:** documentación/git · **Casos SEC:** — (habilitante) · **Prioridad:** primera

**Objetivo:** versionar la edición de seguridad tal como está (esta carpeta incluye el plan y los prompts; entran en el mismo commit inicial).

**Tareas:**
1. `git status` + revisión visual de la carpeta: sin temporales, sin datos sensibles, sin capturas con datos reales.
2. (Opcional, decisión del propietario) puntero de una línea en el `README.md` de la raíz hacia esta edición.
3. `git add kimi_pizza_ai_framework_security` y commit único.
4. Actualizar en `agent.md` (raíz) la entrada del 18/10/2026 sobre la carpeta: de "SIN trackear" a "incorporada" (con el hash).

**Evidencia:** `git status --short` (limpio), `git log --oneline -3`, lista de archivos del commit.

**Gate de cierre:** ningún archivo de `lib/` o `test/` en el commit; carpeta sin secretos (revisión visual; el escaneo formal llega en `FS-5`).

**Commit sugerido:** `docs: incorpora la edicion de seguridad alineada al estado post-correccion`

**Estado (18/10/2026):** ✅ Ejecutada — commit `06e40f1` (35 archivos, 6264 inserciones, todos dentro de esta carpeta; sin archivos de `lib/` ni `test/`; revisión visual sin temporales ni datos sensibles; `git status --short` limpio tras el commit); fase de documentación/git, sin re-ejecución de suite/analyze (regla 2 de §4).

### FS-1 — Triaje formal del catálogo de casos

**Tipo:** documentación · **Casos SEC:** los 40 (disposición, no ejecución)

**Objetivo:** publicar en `docs/SECURITY_TEST_PLAN.md` una nueva §3.2 con la disposición de cada caso: `Ejecutable en escritorio`, `Requiere dispositivo/keystore`, `No aplicable hoy (justificación)` o `Cubierto por automatización (re-ejecutar)`, con fase destino (Anexo A de este plan como borrador).

**Gate de cierre:** las 40 filas con disposición y justificación; ningún estado de la matriz cambia.

**Commit sugerido:** `docs: triaje formal del catalogo de casos de seguridad`

**Estado (18/10/2026):** ✅ Ejecutada — commit `e68b122`; §3.2 publicada con las 40 filas (30 `Ejecutable en escritorio`; 1 `Cubierto por automatización` — SEC-026; 7 `Requiere dispositivo/keystore`; 2 `No aplicable hoy` — SEC-017/SEC-040, a ratificar en `FS-8`); revisión caso por caso contra §3.1 sin copiar el Anexo A (se anotó la mitigación ya existente en `AuthService.login` para SEC-002 y el matiz de build release de SEC-005); sin cambios en los estados de la matriz; fase de documentación, sin re-ejecución de suite/analyze (regla 2 de §4).

### FS-2 — Integridad transaccional: ventas, boleta e inventario

**Tipo:** pruebas (escritorio) · **Casos SEC:** SEC-018, SEC-019, SEC-020, SEC-021, SEC-025, SEC-026, SEC-027, SEC-028

**Objetivo:** cerrar con pruebas ejecutables la idempotencia y la validación del flujo comercial (núcleo financiero; prioridad 1 del proyecto).

**Tareas:**
1. **SEC-025 (primero):** prueba dedicada de doble toque/reintento de "Cobrar" → una sola venta, un solo movimiento de stock y un solo registro de caja. Referencias: `test/pos_boleta_resiliencia_test.dart`, `test/anular_editar_ventas_test.dart`.
2. SEC-026: re-ejecución formal (fallo de PDF tras venta confirmada no duplica la venta) y registro de la salida como evidencia.
3. SEC-027: doble submit/reintento de compra no duplica entrada de stock ni CxP.
4. SEC-028: venta/merma/transformación concurrente sin doble descuento (fuente única: `StockMovementWriter`).
5. SEC-018/019: entradas extremas/negativas rechazadas por dominio, sin crash ni estado parcial.
6. SEC-020: barrido de consultas parametrizadas en repositorios + prueba acotada con caracteres de inyección.
7. SEC-021: PDF/imagen corrupta o sobre-dimensionada rechazada con error seguro.

**Evidencia:** salida literal de `flutter test --no-pub` y `flutter analyze --no-pub`; rutas `test/…:líneas`; filas de la matriz "Integridad POS: venta / inventario / PDF" con "Evidencia registrada".

**Gate de cierre:** suite completa verde (75 + nuevas) y analyze 0; sin cambios de comportamiento no probados.

**Commit sugerido:** `test: cubre integridad de ventas e inventario (SEC-018 a SEC-028)`

**Estado (18/10/2026):** ✅ Ejecutada y cerrada — pruebas permanentes en `test/entradas_invalidas_seguridad_test.dart` (SEC-018/SEC-019: carrito vacío; fecha malformada/futura; infinito/NaN; monto insuficiente; compra con cantidad/costo inválidos e insumo inexistente con rollback; adelanto/cuotas fuera de rango), `test/inyeccion_sql_seguridad_test.dart` (SEC-020: carga SQL almacenada literal y sin efecto en autenticación), `test/integridad_inventario_seguridad_test.dart` (SEC-028: venta+merma+transformación concurrentes descuentan una sola vez; transformación fallida no descuenta y el reintento aplica una vez), `test/imagen_pdf_seguridad_test.dart` (SEC-021: logo corrupto e inexistente → boleta sin logo, error seguro) y T5 en `test/integridad_cobro_seguridad_test.dart` (SEC-025: reintento tras fallo de caja cobra una sola vez); los tests de `FS-2A` (T1a–T4 y T1–T2) quedan como evidencia permanente de H-1 a H-3. SEC-026 re-ejecutado formalmente: `flutter test --no-pub test/pos_boleta_resiliencia_test.dart` → 3/3 `All tests passed!` (con las trazas esperadas del fallo simulado). Barrido SEC-020: 83 llamadas `rawQuery/rawInsert/rawUpdate/rawDelete` en `lib/`; única interpolación en `where` = lista de marcadores `?` (`promocion_repository.dart:95`, valores en `whereArgs`) y `PRAGMA table_info($table)` usa nombres internos de migración. H-4 (SEC-021, imágenes sin tope de tamaño/dimensiones) quedó reportado y se corrigió en `FS-2B` (commit `09dea39`; ver sección). Evidencia: `flutter test --no-pub` → **110/110** (`All tests passed!`); `flutter analyze --no-pub` → `No issues found!` (98.7 s); commit de pruebas `da97b2f` (5 archivos, 652 inserciones); este registro documental cierra la fase.

### FS-2A — Corrección de hallazgos de integridad (H-1 a H-3)

**Tipo:** corrección (fase nueva, aprobada por el propietario tras la parada de `FS-2`) · **Hallazgos:** H-1 (SEC-019), H-2 (SEC-027), H-3 (SEC-025)

**Origen:** al ejecutar `FS-2` el 18/10/2026 se confirmó por pruebas que una venta admitía importes negativos (venta por `-S/ 50` con `MovimientosCaja` en negativo; cantidad `-2` directa al repositorio subía el stock 5 → 7), que el doble submit de una compra duplicaba stock/Gasto/MovimientoCaja (y CxP + adelanto en crédito) y que dos cobros concurrentes registraban dos ventas. H-4 (imágenes sin tope de tamaño/dimensiones, SEC-021) quedó reportado y fuera de esta fase; su corrección se ejecutó en `FS-2B` (commit `09dea39`).

**Correcciones aplicadas (capa de dominio/controlador; sin cambios de esquema):**
1. **H-1 (SEC-019):** `PosService.registrarVenta` valida total finito y no negativo, cantidad > 0 y precio final finito y no negativo; `VentaRepository.registrarVentaCompleta` valida cabecera (subtotal/total) y detalles (cantidad/precio) antes de la transacción; `PosController.agregarAlCarrito`/`agregarPromocionAlCarrito` rechazan `precioPersonalizado` negativo o no finito; `pos_item_detail_sheet.dart` avisa al cajero si el precio manual es negativo.
2. **H-2 (SEC-027):** guarda de reentrada en `ComprasController.registrarCompra` y `corregirCompra` (`if (_isLoading) return false;`) y bandera local `_guardando` en `compra_form_screen.dart` para el golpe doble.
3. **H-3 (SEC-025):** guarda `_procesandoCobro` en `PosController.procesarCobro`; la reentrada devuelve `null` sin tocar caja ni stock.

**Pruebas nuevas (permanentes):** `test/integridad_cobro_seguridad_test.dart` (T1a, T1b, T2, T3, T4) y `test/compra_doble_submit_seguridad_test.dart` (T1, T2).

**Evidencia:** `flutter test --no-pub` → **97/97** (`All tests passed!`); `flutter analyze --no-pub` → `No issues found!`; commit de código/pruebas `1b1dbf6`.

**Gate de cierre:** cumplido; sin cambios de esquema ni migraciones.

**Commit sugerido:** `fix: valida importes de venta y evita doble submit de cobro y compra (H-1 a H-3)`

**Estado (18/10/2026):** ✅ Ejecutada — commit `1b1dbf6` (código + pruebas: 8 archivos, 411 inserciones; este registro documental cierra la fase); `FS-2` fue reanudada y cerrada el mismo día sobre el código corregido (commit `da97b2f`; ver sección `FS-2`). H-4 (SEC-021) quedó fuera de alcance y su corrección se ejecutó en `FS-2B` (commit `09dea39`).

### FS-2B — Corrección del hallazgo H-4 (SEC-021: límite de imágenes)

**Tipo:** corrección (fase nueva; prompt preparado a solicitud del propietario) · **Hallazgo:** H-4 (SEC-021)

**Origen:** al evaluar SEC-021 en `FS-2` se confirmó que `lib/services/image_service.dart` no impone tope de tamaño ni de dimensiones a las imágenes capturadas o seleccionadas (solo `imageQuality: 70`); una imagen sobredimensionada puede agotar memoria/almacenamiento al decodificarse o copiarse (S6: tratar archivos como entrada no confiable; exceso de recursos). El servicio es el punto único de captura del proyecto (usado por `AppImagePicker` y por las pantallas de configuración, usuarios, productos, insumos, promociones, compras, activos y onboarding; 9 puntos).

**Tareas (propuestas):**
1. `ImageService.pickImageFromCamera`/`pickImageFromGallery`: pasar `maxWidth`/`maxHeight` (sugerido: 1600 px de lado máximo) manteniendo `imageQuality: 70`, para que el plugin reduzca en origen.
2. Guarda posterior: tope de bytes por archivo (sugerido: 5 MB); si el archivo excede el tope, eliminarlo con `deleteLocalFile` y devolver `null` (mismo contrato que la cancelación, sin basura en disco). Extraer un helper estático verificable para el tope.
3. Inyectar `ImagePicker` como parámetro opcional del constructor (los usos existentes `ImageService()` no cambian) para probar con mock (mocktail ya es dev-dependency).
4. Barrido: confirmar que no existe ningún `ImagePicker()` directo fuera del servicio (verificado el 18/10/2026: único uso en `image_service.dart`).
5. Pruebas permanentes: imagen normal → ruta devuelta con downscale aplicado; sobredimensionada → borrada + `null`; cancelación → `null`; frontera exacta del tope.

**Evidencia:** salida literal de `flutter test --no-pub` y `flutter analyze --no-pub`; rutas `test/…:líneas`; fila "PDF/documentos" de la matriz sin H-4 abierto.

**Gate de cierre:** suite verde + analyze 0; sin cambios de esquema; los 9 puntos de captura siguen funcionando sin cambios (parámetro opcional); validación real del picker en dispositivo, si se desea, queda para `FS-7`.

**Commit sugerido:** `fix: limita tamano y dimensiones de las imagenes capturadas (H-4)`

**Estado (18/10/2026):** ✅ Ejecutada — commit `09dea39` (código + pruebas: 2 archivos, 153 inserciones) y este registro documental cierra la fase; evidencia: `flutter test --no-pub` → **115/115** (`All tests passed!`, exit 0) y `flutter analyze --no-pub` → `No issues found!` (87.7 s, exit 0). No quedan hallazgos H-1…H-4 abiertos.

### FS-3 — Caja y ciclo operativo

**Tipo:** pruebas (escritorio) · **Casos SEC:** SEC-029, SEC-030, SEC-031

**Objetivo:** probar formalmente cierre y reapertura de caja. Desbloqueado por el commit `5cf6731` (trabajo de caja ya commiteado).

**Tareas:**
1. SEC-029: reapertura excepcional sin autorización → denegada y sin cambios.
2. SEC-030: cierre enviado dos veces → un solo cierre/ciclo.
3. SEC-031: reapertura autorizada → fecha/hora, actor, motivo y referencia al ciclo anterior (auditoría).

**Referencias:** `test/caja_arqueo_repo_test.dart`, `test/gastos_movimiento_caja_test.dart`; RN-04, RN-06.

**Gate de cierre:** suite verde + analyze 0; fila "Integridad POS: caja" de la matriz con evidencia.

**Commit sugerido:** `test: cubre caja y ciclo operativo (SEC-029, SEC-030, SEC-031)`

**Estado (18/10/2026):** ✅ Ejecutada — commit `e9bce34` (pruebas: 1 archivo, 363 inserciones; sin cambios en `lib/`); evidencia: `flutter test --no-pub` → **123/123** (`All tests passed!`, exit 0) y `flutter analyze --no-pub` → `No issues found!` (41.2 s, exit 0); fila "Integridad POS: caja" de la matriz con evidencia registrada. Sin defectos detectados.

### FS-4 — QR administrativo y cobro

**Tipo:** pruebas/inspección (escritorio; la parte con cámara/galería real va a `FS-7`) · **Casos SEC:** SEC-022, SEC-023, SEC-024

**Objetivo:** verificar que el QR de cobro tiene una única fuente de verdad, solo lo cambia el rol autorizado, un fallo de guardado conserva el QR previo y el cobro usa la fuente verificada (sin archivos temporales obsoletos).

**Tareas:**
1. Inspeccionar el flujo real de configuración del QR (pantalla, servicio, persistencia) y documentar el recorrido con `archivo:línea`.
2. Escribir pruebas donde la infraestructura lo permita (sin cámara/galería real).
3. Redactar el procedimiento manual (sin datos reales) para lo que dependa de interfaz/dispositivo.

**Gate de cierre:** evidencia por caso (prueba o procedimiento + inspección `archivo:línea`).

**Commit sugerido:** `test: cubre flujo QR administrativo y de cobro (SEC-022, SEC-023, SEC-024)`

### FS-5 — Lote estático de repositorio y plataforma

**Tipo:** inspección/scripts (escritorio) · **Casos SEC:** SEC-011, SEC-013, SEC-032, SEC-034, SEC-036, SEC-037, SEC-039

**Tareas:**
1. SEC-011: secret scanning del árbol y de la historia (herramienta instalada si existe; si no, barrido por patrones + limitación documentada; nunca usar valores reales).
2. SEC-036: inventario de dependencias (`flutter pub deps`) y revisión de advisories con lo disponible (sin red → documentar limitación).
3. SEC-037: **propuesta** de job de secret scanning con canario en `.github/workflows/ci.yml` (implementación sujeta a aprobación del propietario; commit `ci:` separado).
4. SEC-034: revisión completa de `AndroidManifest.xml` (components, `exported`, permisos, intents) y reglas de backup.
5. SEC-039: deep links/intents: ausencia o validación previa.
6. SEC-032: barrido de logs por patrones sensibles (`password`, `token`, `authorization`) en `lib/`.
7. SEC-013 (estático): persistencia local (preferencias, temporales, PDFs, fotos) sin credenciales en claro.

**Gate de cierre:** cada caso con comando y salida sanitizada; el gap de CI documentado como decisión pendiente.

**Commit sugerido:** `docs: evidencia estatica de repositorio y plataforma (SEC-011 a SEC-039)`

### FS-6 — Acceso, cuentas y sesión

**Tipo:** pruebas (escritorio) · **Casos SEC:** SEC-001…SEC-010

**Tareas:**
1. SEC-001/002: login inválido y repetición rápida de intentos. **Nota (FS-1):** `AuthService.login` ya aplica contador/bloqueo en memoria (5 intentos / 30 s, sin persistencia) y tiene prueba (`test/phase4_security_resources_test.dart`, caso C-18); evaluar su alcance real y registrarlo.
2. SEC-003/004 (adaptados): sesión local sin tokens remotos; verificar limpieza de estado en `logout()` (C-18).
3. SEC-005: cuenta desactivada/bloqueada no accede (RN-10/RN-11).
4. SEC-006: rol empleado en ruta admin → UI y guardas rechazan (`test/router_guards_test.dart`).
5. SEC-007/008: manipulación de rol/IDs locales; documentar el límite de defensa local-only (S2).
6. SEC-009/010: ciclo de usuarios (alta/baja, última cuenta admin) con auditoría y sin auto-baja.

**Orden:** se ejecuta después de `FS-10`/`FS-11` (mejoras de acceso), para evaluar el flujo de acceso final (usuario recordado + huella).

**Gate de cierre:** suite verde + analyze 0; hallazgos (p. ej., SEC-002) reportados, no corregidos sin aprobación.

**Commit sugerido:** `test: cubre acceso, cuentas y sesion (SEC-001 a SEC-010)`

### FS-7 — Casos dependientes de entorno (dispositivo/keystore)

**Tipo:** dispositivo/release · **Casos SEC:** SEC-012, SEC-014, SEC-015, SEC-016, SEC-033, SEC-035, SEC-038

**Precondiciones para desbloquear:** emulador con imagen `android-37.2\google_apis_playstore_ps16k\x86_64` (AVD `Pixel_8`) o dispositivo físico; keystore propio + `android/key.properties` (creación a cargo del propietario); ventana de prueba autorizada.

**Tareas:**
1. Con entorno: ejecutar SEC-014 (backup/restore), SEC-015/016 (release sin red/HTTP), SEC-033 (permisos), SEC-035 (artefacto firmado), SEC-012 (inspección de APK) y SEC-038 (exportaciones); registrar evidencia redactada. Incluye la validación real del acceso con huella de `FS-11` (huella aceptada, cancelada y permiso revocado).
2. Sin entorno: registrar cada caso como **Bloqueado por entorno** con el intento (comando + error literal) y las precondiciones faltantes.

**Gate de cierre:** todos los casos con resultado o bloqueo documentado; nunca marcar resultados no ejecutados.

**Commit sugerido:** `docs: casos de seguridad dependientes de entorno (SEC-012, 014, 015, 016, 033, 035, 038)`

### FS-8 — No aplicables y cierre del ciclo de evaluación

**Tipo:** documentación/cierre · **Casos SEC:** SEC-017, SEC-040 (+ ratificaciones)

**Tareas:**
1. Formalizar `No aplicable` (SEC-017/040: sin backend/sync hoy) y las ratificaciones que pidan `FS-5`/`FS-6`, **con aprobación explícita del propietario**.
2. Consolidar en la matriz los estados finales con su registro de evidencia; registrar excepciones aceptadas (si las hubiera) con dueño, compensación y expiración.
3. Actualizar `docs/SECURITY_TEST_PLAN.md` (§3.1/§3.2), el "Estado de la evaluación" del `README.md` y la bitácora `agent.md` (raíz).
4. Revisión final: ningún caso sin disposición.

**Gate de cierre:** cierre firmado por el propietario; nada en ambigüedad.

**Commit sugerido:** `docs: cierre del ciclo de evaluacion de seguridad`

### FS-9 — Backlog opcional (no bloqueante)

**Tipo:** documentación/pruebas · **Casos SEC:** —

1. Sincronizar `kimi_pizza_ai_framework/PROMPT_MASTER.md` §5 (anexo) y `docs/DATA_MODEL.md` (diccionario) contra `lib/core/database/db_schema.dart` (v25).
2. Añadir prueba para la semántica de "conservar el sobrante en preparación cuando no es cierre de ciclo" (commit `32e2a79`).
3. Cualquier puntero pendiente en el `README.md` de la raíz.

**Commit sugerido:** según unidad (`docs:` / `test:`), aprobado por el propietario.

### FS-10 — Mejoras de acceso: recordar usuario (Fase A)

**Tipo:** funcionalidad (escritorio; validación en uso real) · **Casos SEC relacionados:** SEC-001…SEC-004 (el flujo de acceso final se evalúa en `FS-6`)

**Origen:** decisión del propietario (18/10/2026): acceso "usuario recordado + huella, sin contraseña".

**Objetivo:** recordar al último usuario que inició sesión (solo `username` y `user_id`; **nunca la contraseña**) en almacenamiento seguro, con checkbox "Recordar usuario" y autocompletado del nombre en el login.

**Tareas:**
1. `lib/core/storage/secure_auth_store.dart`: guardar/leer/limpiar el usuario recordado con `flutter_secure_storage` (Keystore/Keychain).
2. `lib/screens/auth/login_screen.dart`: checkbox "Recordar usuario", autocompletado al abrir y registro de la decisión tras un login exitoso; un fallo del almacén no bloquea el acceso.
3. `lib/controllers/auth_controller.dart`: extensión con parámetros opcionales (compatibilidad con los tests existentes).
4. `test/auth_remember_test.dart`: guardado, lectura, limpieza, prefill y no-persistencia de la contraseña.

**Gate de cierre:** suite completa verde (75 + nuevas) y analyze 0; en almacén solo `username`/`user_id`; el logout no concede acceso (solo conserva el nombre; el acceso rápido con huella se revoca en `FS-11`).

**Commit sugerido:** `feat: recordar usuario con almacenamiento seguro y autocompletado en login`

**Estado (18/10/2026):** ✅ Ejecutada — commit `36a6fea`; suite **80/80** ("All tests passed!", exit 0) y `flutter analyze --no-pub` = *No issues found!* (141.2 s, exit 0); el almacén solo persiste `username`/`user_id` (cubierto por `test/auth_remember_test.dart`); registro del plan en `b70af02`.

### FS-11 — Mejoras de acceso: huella para el usuario recordado (Fase B)

**Tipo:** funcionalidad (requiere dispositivo para la validación real) · **Casos SEC relacionados:** SEC-001…SEC-004 (evaluados en `FS-6`, después de esta fase)

**Origen:** decisión del propietario (18/10/2026).

**Objetivo:** tras un login con contraseña y "Recordar usuario" marcado, permitir entrar con huella (sin teclear contraseña) al usuario recordado.

**Condiciones y límites (decididos):**
1. **Nunca** se persiste la contraseña; la sesión se restaura revalidando `activo = 1 AND bloqueado = 0` del `user_id` recordado.
2. El **logout revoca** el acceso rápido (se borra el permiso de huella); para reactivarlo hay que iniciar sesión con contraseña y volver a marcarlo.
3. La huella es un **candado de conveniencia** contra el acceso físico casual; no protege contra root/APK modificado ni sustituye la contraseña (límite declarado, S2).

**Tareas ejecutadas:**
1. Dependencia `local_auth` `^3.0.2` (revisión S8: paquete oficial de Flutter, sin red ni permiso `INTERNET`; aporta `USE_BIOMETRIC` y `androidx.biometric` transitivo) y ajustes nativos: `MainActivity` → `FlutterFragmentActivity`, permiso `USE_BIOMETRIC` en el manifiesto y temas `Theme.AppCompat.Light.NoActionBar` (`LaunchTheme`/`NormalTheme`; evita los cierres de Android 8- documentados por el plugin).
2. `lib/services/biometric_auth_service.dart` (wrapper testeable; `biometricOnly: true`; un fallo del plugin equivale a "no disponible"), `UsuarioRepository.getUsuarioActivo` (filtro `activo = 1 AND bloqueado = 0`, RN-10) y `AuthService.loginRapido(userId)` (nunca verifica ni persiste contraseñas).
3. UI: checkbox "Entrar con huella" (visible solo con biometría disponible y enrolada; requiere "Recordar usuario") + botón "Entrar con huella" cuando el permiso está habilitado; `AuthController.entrarConHuella()` ordena permiso → biometría → sesión revalidada, y ante cancelación vuelve al login con contraseña.
4. Revocación del permiso (solo se conserva el nombre recordado): logout (los 3 puntos de cierre de sesión esperan la revocación antes de navegar), usuario inválido detectado al restaurar (bloqueado/inactivo → mensaje + revocación) y restablecimiento de contraseña por recuperación del usuario recordado.
5. `test/biometric_login_test.dart` (10 pruebas con fake de biometría: permiso en almacén seguro, matriz de disponibilidad, camino feliz, cancelación sin mensaje, usuario bloqueado, marcado/desmarcado, logout y reset). La validación real con huella en dispositivo queda agrupada en `FS-7`.

**Gate de cierre:** suite verde + analyze 0; sin contraseña persistida; logout revoca; límite declarado documentado.

**Commit sugerido:** `feat: acceso rapido con huella para el usuario recordado`

**Estado (18/10/2026):** ✅ Ejecutada — commit `9d68f82`; `flutter test --no-pub` = **90/90** ("All tests passed!", exit 0) y `flutter analyze --no-pub` = *No issues found!* (exit 0); `flutter build apk --debug --no-pub` compila (`app-debug.apk`) y el manifiesto fusionado declara `USE_BIOMETRIC` (+ `USE_FINGERPRINT` del plugin) sin `INTERNET` en los manifiestos de producción (el `INTERNET` fusionado de debug proviene del manifiesto estándar de desarrollo de Flutter). Pendiente: validación real con huella en dispositivo (`FS-7`).

## 6. Decisiones abiertas (solo el propietario)

| Decisión | Fase | Propuesta por defecto |
|---|---|---|
| ¿Mitigar intentos de login (SEC-002) o aceptar el riesgo documentado? | FS-6 | Proponer contador + retardo; decidir con evidencia en mano |
| ¿Añadir secret scanning al CI (SEC-037)? | FS-5 | Propuesta de job con canario; commit `ci:` separado |
| Ratificar `No aplicable` (SEC-017, SEC-040) y excepciones | FS-8 | Requiere firma explícita; sin firma, queda `Pendiente` |
| Puntero en el `README.md` raíz hacia la edición de seguridad | FS-0 | Opcional, una línea |
| Aceptación de riesgo residual (p. ej., defensa local-only, SEC-007/008) | FS-6/FS-8 | Documentar; el agente no acepta riesgo en nombre del propietario |
| ¿Ejecutar la corrección de H-4 (FS-2B) o aceptar el riesgo documentado? | FS-2B/FS-8 | RESUELTA (18/10/2026): ejecutada en `FS-2B` (commit `09dea39`; suite **115/115**; analyze 0); sin riesgo aceptado |

## 7. Anexos

### Anexo A — Mapeo de los 40 casos a fases

| Caso | Fase | Tipo/entorno | Nota |
|---|---|---|---|
| SEC-001 | FS-6 | prueba/escritorio | login inválido |
| SEC-002 | FS-6 | prueba/escritorio | posible brecha: sin mitigación de intentos |
| SEC-003 | FS-6 | prueba/escritorio | adaptado: sesión local, sin tokens remotos |
| SEC-004 | FS-6 | prueba/escritorio | adaptado: limpieza de estado en logout (C-18) |
| SEC-005 | FS-6 | prueba | cuenta desactivada/bloqueada (RN-10/RN-11) |
| SEC-006 | FS-6 | prueba | ruta admin con rol empleado (`router_guards_test.dart`) |
| SEC-007 | FS-6 | prueba | manipulación de rol local |
| SEC-008 | FS-6 | prueba | IDs de otro usuario/recurso |
| SEC-009 | FS-6 | prueba | ciclo de usuarios admin |
| SEC-010 | FS-6 | prueba | protección de la última cuenta admin |
| SEC-011 | FS-5 | inspección/escritorio | secret scanning de árbol e historia |
| SEC-012 | FS-7 | dispositivo/release | inspección de APK |
| SEC-013 | FS-5 (+FS-7) | inspección | estático ahora; runtime en dispositivo |
| SEC-014 | FS-7 | dispositivo | backup/restore (`F11(e)`) |
| SEC-015 | FS-7 | release | HTTP en release (hoy sin red; ratificar) |
| SEC-016 | FS-7 | release | TLS (sin tránsito hoy; ratificar) |
| SEC-017 | FS-8 | documental | no aplicable hoy: sin backend |
| SEC-018 | FS-2 | prueba/escritorio | entrada malformada/tipos |
| SEC-019 | FS-2 | prueba/escritorio | importes negativos/extremos |
| SEC-020 | FS-2 | prueba/escritorio | inyección SQL (consultas parametrizadas) |
| SEC-021 | FS-2 | prueba/escritorio | PDF/imagen corrupta o grande |
| SEC-022 | FS-4 | prueba/manual | reemplazo de QR restringido por rol |
| SEC-023 | FS-4 | prueba | fallo al persistir QR conserva el previo |
| SEC-024 | FS-4 | prueba | QR en cobro: fuente de verdad |
| SEC-025 | FS-2 | prueba/escritorio | doble cobro (primera prueba de la fase) |
| SEC-026 | FS-2 | prueba/escritorio | re-ejecución: fallo PDF no duplica venta |
| SEC-027 | FS-2 | prueba/escritorio | compra reenviada/timeout (local) |
| SEC-028 | FS-2 | prueba/escritorio | concurrencia venta/merma/transformación |
| SEC-029 | FS-3 | prueba/escritorio | reapertura no autorizada |
| SEC-030 | FS-3 | prueba/escritorio | cierre duplicado |
| SEC-031 | FS-3 | prueba/escritorio | reapertura autorizada auditada |
| SEC-032 | FS-5 | inspección/escritorio | búsqueda de secretos en logs |
| SEC-033 | FS-7 | dispositivo | permisos cámara/galería |
| SEC-034 | FS-5 | inspección/escritorio | manifest: components/`exported`/permisos |
| SEC-035 | FS-7 | release/keystore | artefacto firmado |
| SEC-036 | FS-5 | inspección/escritorio | dependencias/advisories |
| SEC-037 | FS-5 | CI | canario de secreto (propuesta) |
| SEC-038 | FS-7 | dispositivo | exportaciones/compartir |
| SEC-039 | FS-5 | inspección/escritorio | deep links/intents |
| SEC-040 | FS-8 | documental | no aplicable hoy: sin sync/replay remoto |

### Anexo B — Tablero de fases

| Fase | Contenido | Estado | Commit | Fecha |
|---|---|---|---|---|
| FS-0 | Incorporación al control de versiones (recomendación 2) | ✅ Completada | `06e40f1` | 18/10/2026 |
| FS-1 | Triaje formal de los 40 casos | ✅ Completada | `e68b122` | 18/10/2026 |
| FS-2 | Integridad: ventas, boleta e inventario | ✅ Completada | `da97b2f` | 18/10/2026 |
| FS-2A | Corrección de hallazgos de integridad (H-1 a H-3) | ✅ Completada | `1b1dbf6` | 18/10/2026 |
| FS-2B | Corrección del hallazgo H-4 (SEC-021: límite de imágenes) | ✅ Completada | `09dea39` | 18/10/2026 |
| FS-3 | Caja y ciclo operativo | ✅ Completada | `e9bce34` | 18/10/2026 |
| FS-4 | QR administrativo y cobro | Pendiente | — | — |
| FS-5 | Lote estático de repositorio y plataforma | Pendiente | — | — |
| FS-6 | Acceso, cuentas y sesión | Pendiente | — | — |
| FS-7 | Casos dependientes de entorno (dispositivo/keystore) | Pendiente | — | — |
| FS-8 | Cierre del ciclo de evaluación | Pendiente | — | — |
| FS-9 | Backlog opcional | Opcional | — | — |
| FS-10 | Mejoras de acceso: recordar usuario (Fase A) | ✅ Completada | `36a6fea` | 18/10/2026 |
| FS-11 | Mejoras de acceso: huella (Fase B) | ✅ Completada (validación en dispositivo en `FS-7`) | `9d68f82` | 18/10/2026 |

Cada fase actualiza su fila del tablero al cerrar (estado, commit, fecha).

*Fin del plan. Los prompts de ejecución por fase están en `docs/SECURITY_PHASE_PROMPTS.md`.*
