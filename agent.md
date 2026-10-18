# agent.md — Plan de corrección por fases (post-auditoría 18/10/2026)

> ⚠️ **Este archivo COMPLEMENTA a `AGENTS.md` (constitución técnica del proyecto). NO lo reemplaza.**
> Si hay conflicto entre ambos, **prevalece `AGENTS.md`**.
> Origen: informe de auditoría técnica del 18/10/2026 (hallazgos **H-01 … H-13**).
> Rama de trabajo: `refactor/auditoria-2026-10`.

**Antecedentes mínimos:** la auditoría midió `flutter analyze --no-pub` = 3 warnings (exit 1) y `flutter test --no-pub` = 43/44 (exit 1). El árbol contenía una refactorización avanzada sin commitear (fases 0–8 del AGENTS.md) que resolvió casi todos los C-01..C-31 previos. Los hallazgos residuales se corrigen fase por fase con este plan.

> **Estado real al congelar la rama (F0, 18/10/2026):** `flutter analyze` = *No issues found!* (exit 0) y `flutter test` = **44/44** (exit 0), porque el usuario aplicó correcciones manuales antes de F0 (ver tabla de progreso y bitácora).

---

## 0. PROTOCOLO DE USO (obligatorio para cualquier IA que retome este proyecto)

1. **Localiza la siguiente fase:** abre la sección 3 (Tabla de progreso) y toma la PRIMERA fila en estado `⬜ PENDIENTE`.
2. **Verifica la fase anterior (no confíes solo en la tabla):**
   - `git log --oneline` → debe existir un commit cuyo mensaje empiece por `fase N:` por cada fase marcada ✅.
   - Ejecuta la **Puerta de Calidad** (sección 2) y compárala con el estado esperado de la fase anterior.
   - Si la verificación contradice la tabla, corrige la tabla en tu commit y reporta la discrepancia.
3. **Ejecuta SOLO esa fase:** usa su prompt completo de la sección 5 + las Reglas de Oro (sección 1).
   - Si los números de línea citados en un prompt ya no coinciden (el código evolucionó), **prevalece el objetivo del hallazgo y su Test de Éxito**; adapta los pasos con criterio y documéntalo.
4. **Antes de commitear la fase:** marca su fila como ✅ en la sección 3 (con fecha y evidencia). El commit de la fase DEBE incluir esa actualización de `agent.md`.
5. **Reporta la evidencia** (salidas literales de los comandos) y **DETENTE**.
   **NUNCA ejecutes dos fases en el mismo turno**, aunque todo haya pasado. Cada fase requiere autorización del usuario.
6. **Hallazgo nuevo fuera de alcance:** anótalo en la sección 6 (Bitácora) y repórtalo. No lo corrijas sin autorización.

---

## 1. REGLAS DE ORO (aplican a TODA fase)

| # | Regla |
|---|---|
| 1 | **Una fase por turno.** No se empieza la fase N+1 en el mismo turno en que se ejecutó la fase N. |
| 2 | **Puerta de Calidad obligatoria** (sección 2). Si falla → corregir dentro de la fase o `git checkout -- .` / `git revert`. **Nunca** se avanza con la puerta en rojo ni se deja el árbol a medias. |
| 3 | **TDD para comportamiento nuevo:** primero el test que falla (rojo), luego el código (verde). |
| 4 | **Migraciones SQLite lineales, idempotentes y no destructivas.** `DbSchema.initialTables` y `upgradeDatabase` equivalentes; `PRAGMA foreign_key_check` = 0 filas al cierre. |
| 5 | **Prohibido cambiar el stack** (Provider + sqflite_sqlcipher) y **prohibido agregar dependencias**. Única excepción: retirar `sqlcipher_flutter_libs` en la Fase 11. |
| 6 | **Escritores centralizados intactos:** stock vía `StockMovementWriter`; operaciones críticas auditadas vía `AuditLogWriter` en la MISMA `txn`. |
| 7 | **Cero datos reales:** los tests usan BD en memoria (`sqflite_common_ffi` + `DatabaseHelper.setTestDatabase`). |
| 8 | **Un commit por fase** (código + tests juntos), mensaje `fase N: <descripción> (H-xx)`, **en ASCII sin acentos** (evita mojibake al commitear desde PowerShell). |
| 9 | **Hallazgos nuevos fuera de alcance:** solo se registran en la Bitácora (sección 6). |
| 10 | **Evidencia obligatoria:** pegar salidas literales de los comandos; nunca resumir "todo pasó" sin salida real. |
| 11 | **Actualizar la Tabla de progreso** (sección 3) antes de commitear la fase (fila ✅ con fecha + banner "COMPLETADA" en el título de su prompt), dentro del mismo commit. |

---

## 2. PUERTA DE CALIDAD (obligatoria al final de TODA fase)

```powershell
# 1) Test específico de la fase (indicado en cada prompt)
flutter test --no-pub test/<archivo_de_la_fase>.dart

# 2) Regresión completa (obligatoria)
flutter test --no-pub

# 3) Analizador estático (obligatorio: exit code 0)
flutter analyze --no-pub
```

**Criterio de aprobación:** (1) test específico verde; (2) TODA la suite verde (el conteo crece fase a fase; línea base = 44, 43/44 verdes); (3) `flutter analyze` = `No issues found!` exit 0; (4) commit de la fase (incluye `agent.md` actualizado); (5) evidencia pegada. Solo entonces el usuario autoriza la fase siguiente.

---

## 3. TABLA DE PROGRESO

| Fase | Hallazgos | Estado | Fecha | Verificación | Evidencia git |
|---|---|---|---|---|---|
| F0 | — (baseline) | ✅ COMPLETADA | 18/10/2026 | `flutter analyze --no-pub` = **No issues found!** (exit 0, 193.2s); `flutter test --no-pub` = **44/44** (exit 0); `git status` = 121 entradas (incluye `agent.md`) | commit `chore(baseline): congela refactorizacion + plan por fases (analyze 0, tests 44/44)` |
| F1 | H-01, H-02 | ✅ COMPLETADA (pre-F0) | 18/10/2026 | suite 44/44 + analyze 0 issues verificados en F0 | corrección manual del usuario incluida en el commit baseline |
| F2 | H-05 | ✅ COMPLETADA | 18/10/2026 | `test/gastos_movimiento_caja_test.dart` T1–T5 verdes; suite 49/49; analyze 0 issues; `foreign_key_check` limpio | commit `fase 2: vincula MovimientosCaja por id explicito en gastos (H-05, migracion v24)` |
| F3 | H-06 | ✅ COMPLETADA | 18/10/2026 | grep 0 referencias residuales; suite 49/49; analyze 0 issues | commit `fase 3: elimina ruta muerta de borrado de gastos GastoController/GastoService (H-06)` |
| F4 | H-07 | ✅ COMPLETADA | 18/10/2026 | test T1–T3 verde; suite 52/52; analyze 0 issues | commit `fase 4: la venta se confirma aunque falle la generacion de boleta (H-07)` |
| F5 | H-03 | ✅ COMPLETADA | 18/10/2026 | test T1–T4 verde; suite 57/57; analyze 0 issues | commit `fase 5: mide demanda no satisfecha para las sugerencias de preparacion (H-03, v25)` |
| F6 | H-04a | ✅ COMPLETADA | 18/10/2026 | test fase 4 +5; suite 57/57; analyze 0; grep servicios 0 | commit `fase 6: extrae SQL de usuario/onboarding a repositorios (H-04a)` |
| F7 | H-04b | ✅ COMPLETADA | 18/10/2026 | phase3 verde; suite 58/58; analyze 0; grep caja_service 0 | commit `fase 7: extrae consultas de arqueo a CajaRepository (H-04b)` |
| F8 | H-04c | ✅ COMPLETADA | 18/10/2026 | test nuevo + phase5 verdes; suite 61/61; analyze 0; grep reportes_service 0 | commit `fase 8: extrae SQL de reportes y aisla la capa PDF (H-04c)` |
| F9 | H-08 | ✅ COMPLETADA | 18/10/2026 | test T1–T3 verdes; suite 64/64; analyze 0 | commit `fase 9: guardas de sesion en rutas protegidas (H-08)` |
| F10 | H-09 | ✅ COMPLETADA | 18/10/2026 | release sin keystore FALLA con mensaje exacto (exit 1); debug compila (exit 0, APK generado); suite 64/64; analyze 0 | commit `fase 10: exige keystore para builds release (H-09)` |
| F11 | H-11 | ✅ COMPLETADA (e pendiente explícito) | 18/10/2026 | pub get 0; suite 64/64; analyze 0; debug APK con `libsqlcipher.so`; (e) pendiente: sin device funcional (AVD sin system-image) | commit `fase 11: retira sqlcipher_flutter_libs +eol sin uso (H-11)` |
| F12 | H-10 | ✅ COMPLETADA (d pendiente explícito) | 18/10/2026 | namespace/paquete = `com.kimipizza.pos`; grep android/ = 0; manifest fusionado resuelve `com.kimipizza.pos.MainActivity`; debug APK exit 0; suite 64/64; analyze 0; (d) sin device | commit `fase 12: alinea namespace Android con com.kimipizza.pos (H-10)` |
| F13 | H-12 | ✅ COMPLETADA | 18/10/2026 | test nuevo 9/9 (T1 guías + T2 2.0x); suite 73/73; analyze 0; Semantics+48px en POS/Caja/anulación/gastos; 2 overflows 2.0x corregidos | commit `fase 13: accesibilidad en pantallas criticas de operacion (H-12)` |
| F14 | H-13 | ⬜ PENDIENTE | — | `flutter test --no-pub test/schema_equivalence_test.dart` | commit `fase 14: ...` |
| F15 | — (cierre) | ⬜ PENDIENTE | — | regresión global + `git status` limpio | commit `fase 15: ...` |

---

## 4. DECISIONES PENDIENTES Y MAPA DE FASES

### 4.1 Decisiones que el usuario debe confirmar

| Decisión | Fase | Opción recomendada | Alternativa |
|---|---|---|---|
| Semántica de "faltantes" | F5 (H-03) | **A:** medir demanda no satisfecha real (registrar intentos de venta rechazados por stock preparado) | **B:** columna aproximada `ItemsPreparacion.faltante` |
| Guardas de router: ¿solo sesión o también rol? | F9 (H-08) | **Solo sesión** | Sesión + rol admin para rutas sensibles |
| ¿WAL / `busy_timeout`? | F14 (H-13) | `busy_timeout = 5000` sí; WAL **no** (interactúa con el backup `.kpzbackup`) | WAL completo con revisión de backup |

### 4.2 Mapa de fases

| Fase | Hallazgo(s) | Objetivo | Esfuerzo |
|---|---|---|---|
| F0 | — | Baseline congelado y métricas registradas | 0.25 día |
| F1 | H-01, H-02 | Suite verde + analyze 0 issues (CI verde) | 0.25–0.5 día |
| F2 | H-05 | Vínculo explícito `movimiento_caja_id` (migración v24) | 1 día |
| F3 | H-06 | Eliminar ruta muerta de gastos | 0.5 día |
| F4 | H-07 | Venta confirmada aunque falle la boleta | 0.5–1 día |
| F5 | H-03 | Señal de faltantes real (migración v25) | 1–1.5 días |
| F6 | H-04a | SQL fuera de `usuario_service` y `onboarding_service` | 0.5–1 día |
| F7 | H-04b | SQL fuera de `caja_service` | 0.5–1 día |
| F8 | H-04c | SQL fuera de `reportes_service` + PDF aislado | 1 día |
| F9 | H-08 | Guardas de sesión en el router | 0.5 día |
| F10 | H-09 | Build release falla sin keystore | 0.25 día |
| F11 | H-11 | Retirar `sqlcipher_flutter_libs +eol` | 0.25 día |
| F12 | H-10 | Namespace Android alineado | 0.5 día |
| F13 | H-12 | Semántica + escalado de texto en pantallas críticas | 1 día |
| F14 | H-13 | Test de equivalencia de esquema + `busy_timeout` | 0.5 día |
| F15 | — | Cierre documental y regresión final | 0.25 día |

> **Nota de versiones de esquema:** F2 sube a **v24**; F5 sube a **v25**. Si alguna fase se omite, la siguiente debe ajustar su numeración (las migraciones son acumulativas).

---

## 5. PROMPTS POR FASE (uno por turno; copiar/pegar)

### PROMPT F0 — Baseline y congelamiento

```
Actúa como ingeniero Flutter senior en el repositorio C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
Esta es la FASE 0 (baseline). NO modifiques código.

TAREAS
1. Ejecuta y copia la salida de: flutter analyze --no-pub ; flutter test --no-pub ;
   git status --porcelain ; git log -1 --oneline.
2. Registra métricas de partida exactas (warnings del analyzer, tests pasados/fallados, entradas git status).
3. Crea la rama: git switch -c refactor/auditoria-2026-10
4. Verifica que no existan archivos temporales de auditoría en la raíz.
5. Commit de preservación (solo con autorización del usuario):
   git add -A && git commit -m "chore(baseline): congela refactorizacion + plan por fases (analyze 0, tests 44/44)"

TEST DE ÉXITO
- analyze y test ejecutados y registrados tal cual (estado real al ejecutar F0: analyze = No issues found!, test = 44/44; las correcciones manuales del usuario ya estaban aplicadas).
- Rama creada y git status --porcelain vacío tras el commit.

EVIDENCIA: salidas literales de los 4 comandos + métricas + hash del commit.
REGLA DE PARADA: termina aquí. NO inicies la Fase 1.
```

### PROMPT F1 — Verde inmediato (H-01 + H-02) — ✅ COMPLETADA el 18/10/2026 (solo referencia histórica; NO re-ejecutar)

```
Actúa como ingeniero Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
Esta es la FASE 1: dejar la suite y el analizador en verde (H-01 y H-02).

CONTEXTO
- flutter test falla 1/44: test "Protección financiera: rechaza anular o editar una venta si la sesión
  de caja ya fue cerrada" (test/anular_editar_ventas_test.dart:341). Exige que la excepción contenga
  'ya fue cerrada'. anularVenta sí lo usa (lib/repositories/venta_repository.dart:~507-509), pero
  actualizarMetodoPagoVenta usa '...sesión de caja ya cerrada.' (~686-688). Solo difiere el texto.
- flutter analyze reporta 3 warnings en test/anular_editar_ventas_test.dart:
  línea 2: unused import audit_log_writer; línea 3: unused import stock_movement_writer;
  línea 112: unused local variable 'sesionId'.

TAREAS (alcance cerrado)
1. En actualizarMetodoPagoVenta cambia el literal a:
   'No se puede editar el método de pago de una venta de una sesión de caja que ya fue cerrada.'
2. Elimina los 2 imports sin uso del test.
3. Resuelve 'sesionId' (línea 112): úsala en una aserción de documentación (estado 'abierta' en
   SesionesCaja) o elimina la asignación dejando solo await abrirCajaPrueba(...). Justifica.
4. Opcional recomendado: test corto que documente que AMBOS métodos lanzan mensaje con 'ya fue cerrada'.
5. Prohibido: reformatear archivos, tocar lógica de negocio o modificar otros tests.

TEST DE ÉXITO (obligatorio)
a) flutter test --no-pub test/anular_editar_ventas_test.dart → verde, exit 0
b) flutter test --no-pub → suite completa verde, exit 0
c) flutter analyze --no-pub → "No issues found!", exit 0
Si falla: corrige dentro de la fase o revierte con git checkout -- <archivos>. NO avances.

COMMIT: git add -A && git commit -m "fase 1: unifica mensaje de sesión cerrada y limpia warnings del analyzer (H-01, H-02)"
(El commit debe incluir agent.md con la fila F1 marcada ✅.)
EVIDENCIA: salidas (a)(b)(c) + diff resumido + hash.
PARADA: no inicies la Fase 2.
```

### PROMPT F2 — Vínculo explícito de caja en gastos (H-05, migración v24) — ✅ COMPLETADA el 18/10/2026 (solo referencia histórica; NO re-ejecutar)

```
Actúa como ingeniero Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 2: vínculo explícito Gasto ↔ MovimientosCaja (H-05, RN-02).

PROBLEMA
- CajaRepository.registrarMovimientoManual (lib/repositories/caja_repository.dart:~397-407) inserta
  MovimientosCaja + Gastos SIN guardar el id del movimiento en el gasto.
- PurchaseRepository.eliminarGasto (lib/features/purchases/data/repositories/purchase_repository.dart:
  ~908-937) borra por heurística difusa (monto+fecha, LIMIT 1) → puede borrar el equivocado o dejar huérfanos.

DISEÑO
1. Migración v23→v24 (lib/core/database/database_helper.dart): databaseVersion = 24;
   if (oldVersion < 24) { await _ensureColumn(db, 'Gastos', 'movimiento_caja_id',
   'INTEGER REFERENCES MovimientosCaja(id)'); } — usa _ensureColumn (idempotente).
   Añade la columna también al CREATE TABLE de Gastos en lib/core/database/db_schema.dart.
   Revisa cleanOrphanForeignKeys (~línea 828): añade 'gastos.movimiento_caja_id' si maneja lista manual.
   NO agregues índices nuevos (mantén 23 IDX_* y 4 triggers).
2. registrarMovimientoManual: captura el id del insert del movimiento y guárdalo en el insert de Gastos.
3. eliminarGasto:
   - movimiento_caja_id != null → borrar MovimientosCaja por id exacto (conservar salvaguarda
     NOT EXISTS de PagosCuentaPorPagar.movimiento_caja_id).
   - null (históricos) → fallback difuso SOLO si hay EXACTAMENTE 1 candidato; con 0 o >1, no borrar
     y dejar rastro en el audit log.
   - Conserva AuditLogWriter al final, misma transacción.

TESTS (TDD; crea test/gastos_movimiento_caja_test.dart con el harness en memoria; patrón en
test/phase3_sqlite_consolidation_test.dart):
  T1: salida manual → gasto con movimiento_caja_id; eliminar borra exactamente ese movimiento.
  T2: dos salidas idénticas → eliminar la segunda borra SOLO su movimiento (verifica ids).
  T3: gasto legado sin link con 1 candidato → fallback borra ese movimiento.
  T4: 0 o 2+ candidatos → gasto eliminado, movimientos intactos.
  T5: migración v23→v24 → columna existe; PRAGMA foreign_key_check = 0 filas.
Actualiza aserciones existentes sobre version 23/columnas si corresponde (anótalo).

TEST DE ÉXITO: a) test nuevo verde; b) suite completa verde; c) analyze exit 0.
Si falla: corrige o revierte todo con git checkout -- <archivos>.

COMMIT: "fase 2: vincula MovimientosCaja por id explícito en gastos (H-05, migración v24)" (incluye agent.md).
EVIDENCIA: (a)(b)(c) + diff de migración + foreign_key_check + hash.
PARADA: no inicies la Fase 3.
```

### PROMPT F3 — Eliminar ruta muerta de gastos (H-06) — ✅ COMPLETADA el 18/10/2026 (solo referencia histórica; NO re-ejecutar)

```
Actúa como ingeniero Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 3: eliminar la ruta muerta y sin auditoría de borrado de gastos (H-06).

HECHOS
- UI borra vía: compras_screen.dart:~794 → ComprasController.eliminarGasto → CompraService.eliminarGasto
  → PurchaseRepository.eliminarGasto (correcta).
- GastoController (lib/controllers/gasto_controller.dart) + GastoService (lib/services/gasto_service.dart)
  + GastoRepository.deleteGasto (lib/repositories/gasto_repository.dart:~63-94) = ruta paralela sin
  consumidores (solo registrada en lib/main.dart ~128 y ~199), sin AuditLogWriter ni limpieza de caja.
- CompraService SÍ usa GastoRepository.getGastosRaw() (no tocar).

TAREAS
1. Evidencia previa: rg -n "GastoController|GastoService|GastoRepository" lib test
2. Elimina: gasto_controller.dart; gasto_service.dart (solo si 0 consumidores); provider y construcción
   en main.dart (+imports); métodos de GastoRepository sin uso (probablemente deleteGasto, insertGasto,
   updateGasto, getGastos — borra solo con 0 consumidores; mantén getGastosRaw).
3. Si algún símbolo SÍ tiene consumidor: no lo borres, documéntalo y detente para consultar.

TESTS: sin tests nuevos (código muerto). Suite existente debe quedar idéntica de verde.

TEST DE ÉXITO: a) suite verde; b) analyze "No issues found!" exit 0; c) grep sin referencias residuales.
Si falla: revierte (git checkout / git restore).

COMMIT: "fase 3: elimina ruta muerta de borrado de gastos GastoController/GastoService (H-06)".
EVIDENCIA: grep previo/posterior, archivos borrados, (a)(b), hash.
PARADA: no inicies la Fase 4.
```

### PROMPT F4 — Venta confirmada aunque falle la boleta (H-07) — ✅ COMPLETADA el 18/10/2026 (solo referencia histórica; NO re-ejecutar)

```
Actúa como ingeniero Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 4: la venta debe quedar confirmada aunque falle la impresión de la boleta (H-07).

PROBLEMA
- PosService.registrarVenta (lib/services/pos_service.dart:~186-204) hace commit de la venta y
  acto seguido generarBoletaPDF (~207-642) en la misma llamada. Si el PDF falla, la excepción sube a
  la UI DESPUÉS del commit → el cajero puede reintentar → doble venta.
- Ya existe regeneración: obtenerORecrearBoletaPDF (~673-715).
- NOTA (18/10): la reimpresión ya tiene UI propia (PosHistorialBoletasSheet + PosController.obtenerBoleta)
  añadida tras la auditoría; el foco de esta fase es el try/catch y no propagar el error post-commit
  (H-07 sigue ABIERTO: pos_service.dart:~204 aún espera el PDF sin protección).

DISEÑO
1. Inspecciona consumidores: rg -n "registrarVenta" lib test. Mantén firma Future<String?> salvo que
   el manejo de null sea insuficiente; entonces haz el cambio mínimo documentado.
2. registrarVenta: envuelve la generación en try/catch. Éxito → ruta PDF como hoy.
   Fallo → NO propagar; devolver null + log de diagnóstico (debugPrint) con ventaId y error.
3. UI: si el retorno es null, mensaje claro "Venta registrada. La boleta no pudo generarse; puedes
   reimprimirla desde el historial." con acceso a obtenerORecrearBoletaPDF (ajuste mínimo).
4. Prohibido: mover el commit, cambiar la transacción, reordenar validaciones.

TESTS (TDD; crea test/pos_boleta_resiliencia_test.dart):
  T1: subclase de prueba con generarBoletaPDF que lanza → registrarVenta NO lanza, devuelve null y la
      venta+detalles EXISTEN en BD.
  T2: flujo normal devuelve ruta no nula (no regresión).
  T3 (si adaptaste UI): test del contrato/mensaje de "boleta pendiente".

TEST DE ÉXITO: a) test nuevo verde; b) suite completa verde; c) analyze exit 0.
COMMIT: "fase 4: la venta se confirma aunque falle la generación de boleta (H-07)" (incluye agent.md).
EVIDENCIA: (a)(b)(c) + diff + hash.
PARADA: no inicies la Fase 5.
```

### PROMPT F5 — Señal de faltantes del algoritmo (H-03, migración v25) — ✅ COMPLETADA el 18/10/2026 (solo referencia histórica; NO re-ejecutar) — enfoque elegido: A

```
Actúa como ingeniero Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 5: restaurar la señal de faltantes de SugerenciasAlgoritmo (H-03).
Si el usuario no eligió A o B explícitamente, pide confirmación; recomendado: A.

PROBLEMA
- lib/core/utils/sugerencias_algoritmo.dart:~30-44 consulta ip.sobrante < 0 para promedioFaltantes.
- Tras RN-03, ItemsPreparacion.sobrante siempre es >= 0 (preparacion_repository.dart:164, 511, 719,
  1003, 1037, 1107) → promedioFaltantes siempre 0; la fórmula (~63-65) pierde el efecto de quiebres.

ENFOQUE A
1. Nueva tabla FaltantesPreparacion en db_schema.dart: id PK AUTOINCREMENT, variante_id INTEGER NOT NULL
   REFERENCES VariantesProducto(id), fecha TEXT NOT NULL, cantidad INTEGER NOT NULL, motivo TEXT,
   created_at TEXT + índice IDX_FaltantesPreparacion_variante_fecha (variante_id, fecha).
   Actualiza la aserción del test test/phase3_sqlite_consolidation_test.dart:~28 (23 → 24 índices).
2. Migración v24→v25 en database_helper.dart: databaseVersion = 25; if (oldVersion < 25) crea tabla+índice.
3. Registro del faltante en lib/repositories/venta_repository.dart:
   - Localiza TODO punto donde la venta falla por stock preparado insuficiente (mensaje "El stock
     preparado no alcanza...", ~240-250; solo faltante de stock preparado, no receta insuficiente).
   - Excepción tipada (StockPreparadoInsuficiente) con varianteId, cantidadFaltante, fecha.
   - CRÍTICO: NO insertes el faltante dentro de la transacción que lanza (el rollback lo borra).
     En registrarVentaCompleta: try { return await db.transaction(...); }
     on StockPreparadoInsuficiente catch (e) { await db.insert('FaltantesPreparacion', {...}); rethrow; }
4. SugerenciasAlgoritmo: faltantes = SELECT SUM(cantidad) FROM FaltantesPreparacion WHERE variante_id=?
   AND fecha<=? AND fecha>date(?,'-28 days') AND strftime('%w', fecha)=?  (weekday-aware, /4).
   Mantén la clave 'promedioFaltantes'.

TESTS (TDD; crea test/faltantes_preparacion_test.dart):
  T1: venta sin stock preparado suficiente → lanza Y queda fila en FaltantesPreparacion (sin rollback).
  T2: sugerencia con faltantes del mismo weekday → promedioFaltantes > 0 y sugerenciaFinal mayor.
  T3: sin faltantes → 0 (no regresión).
  T4: migración v24→v25 + foreign_key_check = 0.
ENFOQUE B (solo si el usuario lo elige): columna ItemsPreparacion.faltante al cierre + algoritmo; documenta fórmula.

TEST DE ÉXITO: a) test nuevo verde; b) suite completa verde; c) analyze exit 0.
COMMIT: "fase 5: mide demanda no satisfecha para las sugerencias de preparación (H-03, v25)" (incluye agent.md).
EVIDENCIA: (a)(b)(c) + migración + prueba anti-rollback de T1 + hash.
PARADA: no inicies la Fase 6.
```

### PROMPT F6 — SQL fuera de usuario/onboarding (H-04a) — ✅ COMPLETADA el 18/10/2026 (solo referencia histórica; NO re-ejecutar)

```
Actúa como ingeniero Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 6: extraer SQL directo de servicios a repositorios (H-04a).

PROBLEMA
- lib/services/usuario_service.dart usa DatabaseHelper directo (~líneas 14, 23, 55, 99, 115, 140).
- lib/services/onboarding_service.dart:~26 igual para su setup transaccional.
- AGENTS.md §2: solo la capa data/ toca SQLite. Tests fase4 (RN-11/C-28, C-18, C-30) deben pasar sin cambios.

TAREAS (refactor mecánico: mover SQL, no cambiar lógica)
1. UsuarioService: mueve cada consulta a lib/repositories/usuario_repository.dart; transacciones completas
   al repo (o patrón txn del estilo de purchase_repository/preparacion_repository). AuditLogWriter debe
   seguir en la MISMA transacción que el cambio de estado.
2. OnboardingService: mueve el setup transaccional a repositorio (p. ej. ConfiguracionRepository).
3. Prohibido cambiar mensajes, orden de operaciones o comportamiento observable. No tocar ventas/caja/reportes.

TEST DE ÉXITO
a) flutter test --no-pub test/phase4_security_resources_test.dart → verde
b) suite completa verde
c) analyze exit 0
d) rg -n "DatabaseHelper|\.database" lib/services/usuario_service.dart lib/services/onboarding_service.dart → 0
Si falla: revierte con git checkout -- .

COMMIT: "fase 6: extrae SQL de usuario/onboarding a repositorios (H-04a)".
EVIDENCIA: (a)(b)(c)(d) + diff + hash.
PARADA: no inicies la Fase 7.
```

### PROMPT F7 — SQL fuera de caja_service (H-04b) — ✅ COMPLETADA el 18/10/2026 (solo referencia histórica; NO re-ejecutar)

```
Actúa como ingeniero Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 7: extraer SQL directo de caja_service a CajaRepository (H-04b).

PROBLEMA
- lib/services/caja_service.dart usa DatabaseHelper.instance.database (~172, ~192-193) y rawQuery del
  arqueo. Flujo de dinero: refactor MECÁNICO, cero cambios de comportamiento.

REGLAS
1. Mueve cada consulta a lib/repositories/caja_repository.dart con nombre claro (getResumenArqueo,
   getTotalesPorMetodo, ...). Mismo SQL, args y orden.
2. Transacciones: el repo posee la txn completa O acepta executor — no mezcles estilos.
3. CashCloseSummary sigue siendo la ÚNICA clase que calcula el cuadre (RN-04). Prohibido moverlo.
4. No tocar ventas/gastos/reportes/UI.

TESTS
- Tests de caja/arqueo existentes (fase1, fase3 C-11) pasan sin editarse.
- Añade caracterización del nuevo método de repo para un escenario fijo (ventas efectivo+digital, gastos,
  apertura) con números esperados escritos a mano si no existe ya.

TEST DE ÉXITO: a) phase3 verde; b) suite completa verde; c) analyze exit 0;
d) rg -n "DatabaseHelper|\.database" lib/services/caja_service.dart → 0.
COMMIT: "fase 7: extrae consultas de arqueo a CajaRepository (H-04b)".
EVIDENCIA: (a)(b)(c)(d) + diff + hash.
PARADA: no inicies la Fase 8.
```

### PROMPT F8 — SQL fuera de reportes + PDF aislado (H-04c) — ✅ COMPLETADA el 18/10/2026 (solo referencia histórica; NO re-ejecutar)

```
Actúa como ingeniero Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 8: extraer SQL de reportes_service y aislar el PDF (H-04c).

PROBLEMA
- lib/services/reportes_service.dart mezcla rawQuery (~24, 35, 51, 85, 117, 148) con la construcción de
  reportes PDF. La lógica RN-05 (COGS por receta activa con fallback manual) NO debe cambiar de resultado
  (cubierta por el test de fase5/C-15).

TAREAS
1. Mueve cada rawQuery a un repositorio del feature de reportes (ubicación coherente con la estructura
   por features, p. ej. lib/features/reporting/data/repositories/reportes_repository.dart), mismo SQL,
   mismos parámetros y resultados.
2. ReportesService queda como orquestador (pide datos + genera PDF).
3. Separa la construcción del PDF en archivo/clase propia de exportación (p. ej. reportes_pdf.dart) SIN
   cambiar layout ni números.
4. Prohibido cambiar fórmulas RN-05, formatos de fecha o significado de agregados.

TESTS
- test/phase5_architecture_reports_performance_test.dart (C-15) pasa sin editarse.
- Añade caracterización del repo con dataset fijo y valores esperados escritos a mano (ventas, gastos,
  COGS, utilidad). Documenta si el PDF no es testeable de forma estable.

TEST DE ÉXITO: a) phase5 verde; b) suite completa verde; c) analyze exit 0;
d) rg -n "DatabaseHelper|\.database" lib/services/reportes_service.dart → 0.
COMMIT: "fase 8: extrae SQL de reportes y aísla la capa PDF (H-04c)".
EVIDENCIA: (a)(b)(c)(d) + diff + hash.
PARADA: no inicies la Fase 9.
```

### PROMPT F9 — Guardas de sesión en el router (H-08) — ✅ COMPLETADA el 18/10/2026 (solo referencia histórica; NO re-ejecutar)

```
Actúa como ingeniero Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 9: guardas de sesión en rutas protegidas (H-08). Si el usuario no pidió rol, implementa SOLO sesión.

PROBLEMA
- lib/app/app_router.dart (~65-125) construye cualquier pantalla sin verificar sesión.

DISEÑO
1. Inspecciona lib/controllers/auth_controller.dart y usa su API de sesión (añade bool get haySesion si
   falta, cambio mínimo).
2. Crea lib/app/auth_guard.dart: widget que lee AuthController; con sesión → child; sin sesión →
   const LoginScreen() (sin Navigator extra; login ya navega con replace).
3. Envuelve TODAS las rutas protegidas en AppRouter (todas menos onboarding y login).
4. Prohibido cambiar rutas públicas ni tocar autenticación/servicios.

TESTS (crea test/router_guards_test.dart; patrón de widget tests de fase6)
  T1: '/dashboard' sin sesión → se muestra LoginScreen (identificador estable, no texto frágil).
  T2: '/dashboard' con sesión (harness de fase4) → DashboardScreen.
  T3: '/login' y '/onboarding' accesibles sin sesión.
  T4 (solo si se pidió rol): cajero no accede a rutas admin.

TEST DE ÉXITO: a) test nuevo verde; b) suite completa verde; c) analyze exit 0.
COMMIT: "fase 9: guardas de sesión en rutas protegidas (H-08)".
EVIDENCIA: (a)(b)(c) + diff + hash.
PARADA: no inicies la Fase 10.
```

### PROMPT F10 — Firma release segura (H-09) — ✅ COMPLETADA el 18/10/2026 (solo referencia histórica; NO re-ejecutar)

```
Actúa como ingeniero Android/Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 10: el build release DEBE fallar si no hay keystore (H-09).

PROBLEMA
- android/app/build.gradle.kts (~52-55): sin android/key.properties, el build "release" se firma
  silenciosamente con la clave debug.

DISEÑO
1. buildTypes.release: si NO existe keystorePropertiesFile → throw GradleException("key.properties no
   existe: no se puede firmar un build release. Crea android/key.properties a partir de key.properties.example.")
   Si existe → signingConfigs.getByName("release"). debug sin cambios.
2. key.properties.example: documenta todas las claves (storeFile, storePassword, keyAlias, keyPassword)
   y de dónde obtener el keystore.
3. Prohibido tocar applicationId, label, SDKs o código Flutter.

TEST DE ÉXITO
a) SIN key.properties: flutter build apk --release → FALLA con el mensaje claro (pegar salida).
b) flutter build apk --debug → compila, exit 0.
c) flutter test --no-pub && flutter analyze --no-pub → verde/limpio.
Si no hay SDK: reporta "verificación de build pendiente en entorno con SDK" (no inventes resultados).

COMMIT: "fase 10: exige keystore para builds release (H-09)".
EVIDENCIA: (a)(b)(c) o pendiente explícito + diff + hash.
PARADA: no inicies la Fase 11.
```

### PROMPT F11 — Retirar dependencia EOL (H-11) — ✅ COMPLETADA el 18/10/2026 (solo referencia histórica; NO re-ejecutar)

```
Actúa como ingeniero Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 11: retirar sqlcipher_flutter_libs 0.7.0+eol sin uso (H-11).

EVIDENCIA PREVIA: rg -n "sqlcipher_flutter_libs" lib test → 0 consumidores; pubspec.yaml:~18 lo declara;
pubspec.lock:~789 registra +eol.

TAREAS
1. Elimina la línea de pubspec.yaml y ejecuta flutter pub get.
2. Verifica que sqflite_sqlcipher (el usado) sigue aportando los binarios nativos.

TEST DE ÉXITO
a) flutter pub get ok; b) suite completa verde; c) analyze exit 0;
d) flutter build apk --debug compila (si no hay SDK → pendiente explícito);
e) verificación funcional de SQLCipher en emulador/dispositivo si está disponible (abrir la app);
   si no hay dispositivo, DOCUMÉNTALO como pendiente (no inventes).
Si (d) o (e) fallan por el paquete: restaura dependencia y revierte.

COMMIT: "fase 11: retira sqlcipher_flutter_libs +eol sin uso (H-11)".
EVIDENCIA: (a)-(e) o pendientes + diff + hash.
PARADA: no inicies la Fase 12.
```

### PROMPT F12 — Namespace Android alineado (H-10) — ✅ COMPLETADA el 18/10/2026 (solo referencia histórica; NO re-ejecutar)

```
Actúa como ingeniero Android/Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 12: alinear namespace/paquete Kotlin con com.kimipizza.pos (H-10).

ESTADO: build.gradle.kts namespace = "com.pizzaapp.pizzaapp" (~18) con applicationId = "com.kimipizza.pos"
(~29); MainActivity.kt en kotlin/com/pizzaapp/pizzaapp/.

TAREAS
1. rg -n "pizzaapp\.pizzaapp" android/ → identifica TODAS las referencias.
2. namespace = "com.kimipizza.pos".
3. Mueve MainActivity.kt a kotlin/com/kimipizza/pos/ y actualiza su package. El manifest usa
   ".MainActivity" (resuelve contra namespace); verifica que no haya componentes con nombre completo.
4. Elimina directorios antiguos vacíos. Prohibido tocar lógica de MainActivity, applicationId, label o backups.

TEST DE ÉXITO
a) flutter build apk --debug compila (o pendiente explícito sin SDK);
b) rg -n "pizzaapp\.pizzaapp" android/ → 0;
c) flutter test --no-pub && flutter analyze --no-pub verde/limpio;
d) si hay dispositivo: instalar APK debug y confirmar arranque.
Si (a) falla: revierte todo (git checkout -- android/ + restaurar movidos).

COMMIT: "fase 12: alinea namespace Android con com.kimipizza.pos (H-10)".
EVIDENCIA: (a)-(d) o pendientes + archivos movidos + hash.
PARADA: no inicies la Fase 13.
```

### PROMPT F13 — Accesibilidad en pantallas críticas (H-12) — ✅ COMPLETADA el 18/10/2026 (solo referencia histórica; NO re-ejecutar)

```
Actúa como ingeniero Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 13: semántica y escalado de texto en pantallas de operación diaria (H-12).

ALCANCE (no ampliar): POS (cobrar, eliminar ítem, cortesía), Caja (abrir/cerrar/salida manual),
diálogo de anulación de venta, listado/borrado de gastos.

TAREAS
1. Audita acciones críticas: etiqueta+rol para lector de pantalla; añade Semantics(button, label) donde
   falte; usa ExcludeSemantics para evitar dobles anuncios.
2. Crea test/accessibility_test.dart:
   T1: pump de widgets críticos (empieza por PosCartSummary y diálogo de confirmación; patrón de fase6)
       con Tester.ensureSemantics() + meetsGuideline(androidTapTargetGuideline) y
       meetsGuideline(labeledTapTargetGuideline).
   T2: repetir con textScaler 2.0 (o platformDispatcher.textScaleFactorTestValue) → sin excepciones
       de overflow/layout.
3. Corrige con cambios MÍNIMOS (padding, wrap, labels). Prohibido rediseñar o cambiar temas globales.
4. Guideline imposible en un widget: documéntalo con excepción de auditoría y motivo (no lo silencies).

TEST DE ÉXITO: a) test nuevo verde; b) suite completa verde; c) analyze exit 0.
COMMIT: "fase 13: accesibilidad en pantallas críticas de operación (H-12)".
EVIDENCIA: (a)(b)(c) + lista de Semantics añadidos + hash.
PARADA: no inicies la Fase 14.
```

### PROMPT F14 — Robustez SQLite preventiva (H-13)

```
Actúa como ingeniero Flutter/SQLite senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 14: equivalencia de esquema y estabilidad de conexión (H-13).
Decisión del usuario: busy_timeout SÍ; WAL NO (salvo autorización expresa).

TAREAS
1. Crea test/schema_equivalence_test.dart (patrón de test/phase3_sqlite_consolidation_test.dart:~62):
   - Camino A: BD nueva → initializeTestSchema (v25).
   - Camino B: BD con esquema v22 → upgradeDatabase hasta v25 (mismo truco del test de fase3).
   - Compara: (i) nombres de tabla/índice (excluye sqlite_autoindex)/trigger en sqlite_master;
     (ii) columnas por tabla vía PRAGMA table_info (nombre+notnull).
   - Esperado: IDÉNTICOS. Diferencias = deriva real: corrígelas alineando DbSchema o la migración.
     No silencies con exclusiones; allowlist mínima y justificada si algo es legítimo.
2. Añade en database_helper.dart (onOpen y initializeTestSchema):
   await db.execute('PRAGMA busy_timeout = 5000');
   Prohibido habilitar WAL.
3. Documenta PRAGMAs vigentes (foreign_keys=ON, busy_timeout=5000, journal_mode por defecto).

TEST DE ÉXITO: a) test de equivalencia verde; b) suite completa verde; c) analyze exit 0.
Si (a) revela diferencias y no logras converger sin riesgo: reporta las diferencias exactas y detente.

COMMIT: "fase 14: test de equivalencia de esquema y busy_timeout (H-13)".
EVIDENCIA: (a)(b)(c) + diferencias encontradas y su resolución + hash.
PARADA: no inicies la Fase 15.
```

### PROMPT F15 — Cierre documental y regresión final

```
Actúa como ingeniero Flutter senior en C:\D\ProyectoPizza\pizzaapp (Kimi Pizza POS).
FASE 15: cierre documental y regresión final del plan H-01..H-13.

TAREAS
1. Añade al final de kimi_pizza_ai_framework/docs/AUDIT_CONSOLIDATED.md la sección
   "Estado post-corrección (fecha)" con tabla H-01..H-13 → estado (Corregido / Omitido-con-motivo) →
   commit de su fase. No reescribas la auditoría histórica.
2. Sincronía documental: `git diff --no-index AGENTS.md kimi_pizza_ai_framework/AGENTS.md` debe dar vacío;
   si alguna fase cambió reglas (no se espera), actualiza ambos.
3. README.md: actualiza el conteo FINAL real de tests si menciona el estado de pruebas/fases.
4. Regresión final: flutter analyze --no-pub (0 issues, exit 0); flutter test --no-pub (todo verde, exit 0);
   git log --oneline -n 20 (un commit por fase); git status --porcelain (vacío).
5. Lista los pendientes explícitos acumulados (builds/instalaciones no verificables por falta de SDK/dispositivo).

TEST DE ÉXITO: las 4 verificaciones del punto 4 en verde/limpio + docs actualizados en el mismo commit.
COMMIT: "fase 15: cierre documental post-auditoría y regresión final".
EVIDENCIA: salidas de regresión + count final de tests + pendientes + hash.
PARADA: fin del plan. Reporta el resumen global y espera validación del usuario.
```

---

## 6. BITÁCORA Y PENDIENTES EXPLÍCITOS

> Registrar aquí, sin corregir, cualquier hallazgo nuevo, discrepancia documental o verificación no ejecutable
> (falta de SDK/dispositivo). Formato: `[fecha] [fase] descripción — estado (pendiente/reportado/decidido)`.

- [18/10/2026] [F0] Baseline REAL al congelar: `flutter analyze --no-pub` = **No issues found!** (exit 0, 193.2s); `flutter test --no-pub` = **44/44** (exit 0); `git status` = 121 entradas (incluye `agent.md`); HEAD `20c1beb`.
- [18/10/2026] [Pre-F0] Correcciones manuales del usuario: (a) H-01/H-02 resueltos en `test/anular_editar_ventas_test.dart` (predicado flexible que acepta 'ya cerrada', imports y variable limpios) → **F1 COMPLETADA**; (b) añadida reimpresión de boletas: `PosHistorialBoletasSheet` + `PosController.obtenerBoleta` (+ retoques en `venta_repository.dart`, `pos_service.dart`, `pos_controller.dart`).
- [18/10/2026] [H-07] SIGUE ABIERTO pese a lo anterior: `pos_service.registrarVenta` (~línea 204) aún espera el PDF sin try/catch y `procesarCobro` no limpia el carrito cuando hay error → el riesgo de doble venta persiste. Resolver en F4.
- [18/10/2026] [F1 residual] Los mensajes de `anularVenta` ('…ya fue cerrada') y `actualizarMetodoPagoVenta` ('…ya cerrada') siguen divergiendo; el test acepta ambos. Mejora opcional (unificar literal); no bloquea.
- [18/10/2026] [F2] H-05 corregido: `Gastos.movimiento_caja_id` (FK explícita, migración v24) se escribe en `registrarMovimientoManual`; `eliminarGasto` borra el movimiento por ID exacto y el fallback difuso solo aplica con 1 candidato único (con 0 o 2+ se conserva el movimiento y queda constancia en auditoría). Suite 49/49 y analyze 0.
- [18/10/2026] [F2] Trampa resuelta: `cleanOrphanForeignKeys` corre dentro de `_migrateToV23` (antes de la etapa v24); la lista `nullableFkCleanup` ahora verifica la existencia de la columna antes de cada UPDATE, para que los upgrades desde v22 no fallen y `Gastos.movimiento_caja_id` quede cubierta por la limpieza.
- [18/10/2026] [F2] Verificado: se mantienen 23 índices IDX_* y 4 triggers (sin índices nuevos); la aserción de versión en `phase3_sqlite_consolidation_test.dart` se actualizó a v24.
- [18/10/2026] [F3] H-06 corregido: eliminados `gasto_controller.dart`, `gasto_service.dart` (+ provider y construcción en `main.dart`) y los métodos huérfanos de `GastoRepository`; además se eliminó `models/gasto.dart` (quedó sin ningún consumidor). `getGastosRaw()` se conserva (único método vivo, usado por `CompraService`). grep residual = 0; suite 49/49; analyze 0.
- [18/10/2026] [F4] H-07 corregido: `PosService.registrarVenta` envuelve la generación del PDF en try/catch (log con ventaId + `return null`, nunca propaga tras el commit); `PosController.procesarCobro` ahora devuelve `ResultadoCobro` (cambio de firma documentado: `null` era ambiguo entre "venta fallida" y "boleta pendiente") que distingue `boletaPendiente` de fallo total; `PosCobroSheet` cierra el cobro con "Boleta pendiente" y `PosVentaExitosaDialog` muestra el texto de reimpresión desde historial cuando no hay PDF. Tests T1–T3 en `test/pos_boleta_resiliencia_test.dart`; suite 52/52; analyze 0.
- [18/10/2026] [General] Decisión WAL pendiente de confirmación en F14 (recomendado: no habilitar).
- [18/10/2026] [F5] H-03 corregido (enfoque A): nueva tabla `FaltantesPreparacion` (esquema v25 + índice `IDX_FaltantesPreparacion_variante_fecha`, 24 índices en total); excepción tipada `StockPreparadoInsuficiente` en `StockMovementWriter.changePreparedStock` (path `anticipado`) y en el punto `ambos` sin receta de `venta_repository`; `registrarVentaCompleta` la registra FUERA de la transacción (sobrevive al rollback) y relanza. `SugerenciasAlgoritmo` vuelve a medir demanda no satisfecha real (weekday-aware, ventana 4 semanas, /4) manteniendo la clave `promedioFaltantes`. Notas anti-trampa: `_migrateToV23` también crea la tabla para que su bucle de índices no falle en upgrades <v23, y `notNullFkCleanup` cubre la tabla nueva. Tests T1–T4 en `test/faltantes_preparacion_test.dart`; suite 57/57; analyze 0.
- [18/10/2026] [General] Decisión enfoque faltantes RESUELTA en F5: aplicado enfoque A (tabla `FaltantesPreparacion`, migración v25).
- [18/10/2026] [F6] H-04a corregido (refactor mecánico, cero cambios de comportamiento): `UsuarioService` queda sin SQL; nuevos métodos en `UsuarioRepository` (`getUsuarios(incluirInactivos)`, `getUsuario`, `usernameExists`, `updateUsuario`, `updateBloqueo`/`updateActivo`) con `AuditLogWriter` en la MISMA transacción del cambio de estado; `OnboardingService.setupInitialSystem` usa `ConfiguracionRepository.runTransaction` (setup transaccional completo en la capa data; rollback C-30 intacto). Test fase 4 verde (+5); suite 57/57; analyze 0; grep `DatabaseHelper|.database` en ambos servicios = 0.
- [18/10/2026] [F7] H-04b corregido (refactor mecánico, flujo de dinero intacto): nuevas consultas en `CajaRepository` (`getNombreUsuario`, `getItemsPorVenta` con el SQL idéntico del arqueo); `CajaService` queda sin SQL (`generarArqueoPDF` consume los métodos del repo; errores siguen silenciados con el mismo `catch`). `CashCloseSummary` intacto (RN-04). Caracterización nueva en `test/caja_arqueo_repo_test.dart` (escenario fijo: apertura 100+50, ventas 20 efectivo + 10 Yape, salida 15 → items y totales escritos a mano). phase3 verde (+4); suite 58/58; analyze 0; grep `DatabaseHelper|.database` en caja_service = 0.
- [18/10/2026] [General] Decisión alcance guardas F9 pendiente (recomendado: solo sesión).
- [18/10/2026] [F8] H-04c corregido (refactor mecánico, RN-05 intacta): los 6 rawQuery pasan a `ReportesRepository` (`lib/features/reporting/data/repositories/reportes_repository.dart`, SQL/parámetros/resultados idénticos); `ReportesService` queda como orquestador (sin `DatabaseHelper` ni SQL) y la construcción del PDF sale a `ReportesPdf` (`lib/features/reporting/application/reportes_pdf.dart`, bloque copiado con fidelidad byte a byte salvo la firma `generarPDF` y el `outputDirectory` inyectable para pruebas sin tocar layout ni números). Caracterización nueva en `test/reportes_repo_test.dart` (dataset fijo: 2 pizzas con receta 250 g de queso S/20/kg + 3 bebidas con costo manual S/2.50; venta anulada y venta fuera de rango excluidas; gasto 'Compras' excluido del agregado → ingresos 68.00, gastos 10.00, COGS 17.50, utilidad 40.50; además se valida la generación de un PDF real en directorio temporal inyectado). phase5 verde; suite 61/61; analyze 0; grep `DatabaseHelper|.database` en reportes_service = 0.
- [18/10/2026] [F9] H-08 corregido (alcance aprobado: solo sesión): nuevo `AuthGuard` (`lib/app/auth_guard.dart`) que lee `AuthController` y muestra `child` con sesión activa o `LoginScreen` sin sesión (sin Navigator extra; el login ya navega con replace). `AppRouter` envuelve las 20 rutas protegidas mediante `_buildProtected` (onboarding y login permanecen públicas y el `default` no cambia); `AuthController` gana el getter mínimo `haySesion`. Test nuevo `test/router_guards_test.dart` que precarga la Poppins real (FontLoader + `GoogleFonts.pendingFonts`) y monta `AppTheme.lightTheme` para que el layout use métricas fieles a producción (sin esto, la fuente de prueba cuadrada desborda filas reales): T1 `/dashboard` sin sesión → LoginScreen y el Dashboard no se monta; T2 `/dashboard` con sesión (admin sembrado con el patrón de fase 4) → DashboardScreen; T3 `/login` y `/onboarding` accesibles sin sesión. Sin cambios en autenticación ni servicios. Suite 64/64; analyze 0.
- [18/10/2026] [General] Decisión F9 RESUELTA en F9: aplicado solo sesión (T4 de rol no aplica; queda flotante solo si se pide "también rol" a futuro).
- [18/10/2026] [F10] H-09 corregido: un build release sin credenciales ya NO se firma con la clave debug; FALLA con el mensaje "key.properties no existe: no se puede firmar un build release. Crea android/key.properties a partir de key.properties.example.". Trampas encontradas y resueltas: (1) el bloque `buildTypes.release {}` se evalúa en TODOS los builds — un `throw` directo ahí rompía también `flutter build apk --debug` (verificado empíricamente: exit 1); (2) en Gradle 9.3.1 el overload de `gradle.taskGraph.whenReady` solo acepta `Closure` (no compila con lambda Kotlin). Solución aplicada: `tasks.matching { name.contains("Release") }.configureEach { doFirst("verificarKeystoreRelease") { ... } }` — perezoso, corre solo cuando una tarea Release llega a ejecutarse (falla en `:app:ReleaseMinSdkCheck`, en segundos) y deja debug/profile intactos. `android/key.properties.example` documentado con las 4 claves y el comando `keytool` para generar el keystore. Evidencia (SDK Android 36.0.0 presente): (a) `flutter build apk --release` sin key.properties → exit 1 con el mensaje exacto; (b) `flutter build apk --debug` → exit 0, `✓ Built build\app\outputs\flutter-apk\app-debug.apk`; (c) suite 64/64 y analyze 0. Sin tocar applicationId/label/SDKs ni código Flutter. Ruta positiva (release con keystore real) no ejecutada por diseño: el repo no debe contener keystore.
- [18/10/2026] [F11] H-11 retirado: `sqlcipher_flutter_libs 0.7.0+eol` eliminado de `pubspec.yaml` (dependencia directa con 0 consumidores en lib/test; su propia descripción dice "Not used anymore" — pertenece al stack de package:sqlite3, no al de sqflite_sqlcipher). `flutter pub get` exit 0 → lock sin la dependencia ("Changed 1 dependency!") y `sqflite_sqlcipher 3.4.1` intacto; confirmado que los binarios nativos los aporta `sqflite_sqlcipher` (su android/build.gradle declara `net.zetetic:sqlcipher-android:4.10.0@aar`) y que el APK debug sigue empaquetando `libsqlcipher.so` para arm64-v8a/armeabi-v7a/x86_64. Evidencia: (a) pub get ok; (b) suite 64/64; (c) analyze 0; (d) `flutter build apk --debug` exit 0 + listado de .so del APK; (e) PENDIENTE EXPLÍCITO de verificación funcional: no hay dispositivo/emulador funcional en este entorno — el AVD Pixel_8 apunta a `system-images\android-37.2\google_apis_playstore_ps16k\x86_64` que NO está instalada y `sdkmanager --list_installed` no reporta ninguna system-image (WHPX sí disponible; sin dispositivo físico). Repro pendiente para cuando haya imagen: instalar la system-image, `flutter emulators --launch Pixel_8`, instalar el APK debug y comprobar que los 16 primeros bytes de `databases/pizzaapp_secure.db` NO son "SQLite format 3" (cifrado SQLCipher real). No se revierte el cambio: (d) y (e) no fallan por el paquete, y la ausencia de la imagen es una limitación del entorno.
- [18/10/2026] [F12] H-10 corregido: `namespace` de `android/app/build.gradle.kts` → `com.kimipizza.pos` (el `applicationId` ya era ese y NO se tocó); `MainActivity.kt` movido con `git mv` a `kotlin/com/kimipizza/pos/` y su `package` actualizado (lógica intacta: `class MainActivity : FlutterActivity()`); directorios antiguos `com/pizzaapp/` eliminados. El manifest ya usaba `.MainActivity` relativo → el manifest fusionado resuelve ahora `android:name="com.kimipizza.pos.MainActivity"` y `package="com.kimipizza.pos"` (verificado en `build/app/intermediates/merged_manifest/`). Limpieza necesaria: `build/app` conservaba 260 restos del namespace viejo (mapas de recursos/intermedios) → borrado y reconstruido limpio (0 restos tras el build); el caché binario `android/.gradle/...executionHistory.bin` conservaba el string viejo → eliminado (caché regenerable, ignorada por git). Evidencia: (a) `flutter build apk --debug` exit 0 (138 s); (b) grep `pizzaapp\.pizzaapp` en android/ → 0 (antes de la fase: 2 en fuentes; tras los cambios solo quedaban 2 en el caché binario, eliminado); (c) suite 64/64 y analyze 0; (d) PENDIENTE EXPLÍCITO: sin dispositivo/emulador funcional (mismo diagnóstico que F11). Prohibiciones respetadas: sin tocar lógica de MainActivity, applicationId, label (`Kimi Pizza POS`) ni backups.
- [18/10/2026] [F13] H-12 corregido (cambios mínimos; sin rediseño ni temas globales): auditadas las acciones del alcance y corregidas con `Semantics(button,label,onTap)` + `ExcludeSemantics` (elimina el doble anuncio etiqueta+texto interno) y áreas táctiles >= 48 px: (a) `PosCartSummary` — quitar ítem con etiqueta única y `IconButton` de 48x48 (se retiró `visualDensity.compact`) y COBRAR con `onTap` en Semantics manteniendo el label 'Cobrar total X soles' que verifica la fase 6; (b) `PosItemDetailSheet` (cortesía) — `Switch.adaptive` etiquetado 'Marcar como cortesía' y steppers −/+ de 42→48 px con etiquetas 'Disminuir/Aumentar cantidad'; (c) `PosHistorialBoletasSheet` — cerrar/ver/compartir con etiqueta propia y área 48x48 (antes 30-34 px sin etiqueta), `PopupMenuButton` con tooltip 'Más acciones de la venta #N' y área 48; los async de ver/compartir se extrajeron a closures locales (`verBoleta`/`comparteBoleta`) para no duplicar lógica; los 3 `PopupMenuItem` usan `Flexible` porque a 2.0x el menú desbordaba (RenderFlex overflowed 120/127 px, fix real de la T2); (d) Caja — `_operationButton` (Entrada/Salida manual), 'Abrir nuevo ciclo' y 'Cerrar caja actual' con `onTap` en Semantics + `ExcludeSemantics`; (e) Gastos (`compras_screen`) — papelera con etiqueta 'Eliminar gasto: <desc>' y área 48x48 (antes 34x34 sin etiqueta). Test nuevo `test/accessibility_test.dart` (patrón fase 9: Poppins real + `AppTheme.lightTheme`): T1 = `ensureSemantics()` + `androidTapTargetGuideline` + `labeledTapTargetGuideline` sobre PosCartSummary (vacío y con ítem), hoja de cortesía, hoja de cobro y diálogo de anulación; T2 = mismos pumps con `textScaleFactorTestValue 2.0` sin excepciones de layout. Sin excepciones de auditoría: todas las guías se cumplieron con los ajustes mínimos. Evidencia: (a) test nuevo 9/9; (b) suite 73/73; (c) analyze 0 issues (exit 0).

---

*Fin de `agent.md`. Toda fase ejecutada debe actualizar la sección 3 y commitear este archivo junto con su código.*
