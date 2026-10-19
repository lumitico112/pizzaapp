# INFORME CONSOLIDADO DE AUDITORÍA TÉCNICA Y HOJA DE RUTA — KIMI PIZZA POS

**Fecha de consolidación:** 16 de octubre de 2026  
**Estado:** Línea Base Oficial Verificada + 12 Decisiones de Negocio Aprobadas (`RN-01` a `RN-12`)  
**Alcance:** Arquitectura, integridad financiera, inventario/preparación, SQLite/SQLCipher, seguridad, Android Release, rendimiento, pruebas y CI/CD.

---

## 1. Registro Consolidado de Hallazgos (`C-01` a `C-31`)

| ID | Hallazgo Consolidado | Prioridad | Origen (Auditoría A / B) | Estado en Código |
|---|---|---|---|---|
| **C-01** | Edición de compra a crédito (`corregirCompra`) sobrescribe `monto_pagado` con el adelanto y duplica gasto/movimiento del adelanto | **P0** | B: `DAT-01` | Verificado (`purchase_repository.dart:486-527`) |
| **C-02** | Eliminación de gasto (`eliminarGasto`) borra en `MovimientosCaja` por coincidencia difusa de monto/fecha y no revierte deuda en CxP | **P0** | B: `DAT-02` | Verificado (`purchase_repository.dart:709-714`) |
| **C-03** | `procesarSobrantesPendientes` recorta el descuento de stock por `currentStock` pero inserta `Merma` por el `waste` completo sin validar límite preparado | **P0** | B: `DAT-03` | Verificado (`preparacion_repository.dart:573-624`) |
| **C-04** | Traslado `llevarParaManana` no comprueba filas afectadas del `UPDATE` e inserta sin `UPSERT` en mañana | **P0** | B: `DAT-07` | Verificado (`preparacion_repository.dart:453-484`) |
| **C-05** | `UsuarioRepository.authenticate` filtra `activo = 1` pero omite `bloqueado = 0` | **P0** | A: `H-02` / B: `SEC-01` | Verificado (`usuario_repository.dart:12-20`) |
| **C-06** | `HashUtils` aplica SHA-256 directo sin sal ni KDF lenta; recuperación de cuenta sin caducidad ni límite de intentos | **P1** | A: `H-03` / B: `SEC-02` | Verificado (`hash_utils.dart:14-48`) |
| **C-07** | Claves foráneas declaradas en esquema pero `PRAGMA foreign_keys = ON` no se activa en `onConfigure` | **P1** | A: `H-01` / B: `DAT-04` | Verificado (`database_helper.dart:40-54`) |
| **C-08** | Desincronización entre `db_schema.dart` (35 tablas), `onUpgrade` no lineal (36 tablas con `PromocionProductos`) y `hotRestartPatches` en cada arranque | **P1** | A: `H-04` / B: `DAT-05` | Verificado (`database_helper.dart:61-650`) |
| **C-09** | Valor centinela `insumo_id: 0` en `CuentasPorPagar` para activos fijos a crédito (`asset_service.dart:43`) y tablas legadas coexistentes | **P1** | A: `H-05` / B: `§6 SQLite` | Verificado (`asset_service.dart:40-53`) |
| **C-10** | Columna `ItemsPreparacion.sobrante` nunca se actualiza al cerrar sobrantes, degradando `SugerenciasAlgoritmo` | **P1** | A: `H-06` / B: `DAT-08` | Verificado (`sugerencias_algoritmo.dart:132`) |
| **C-11** | `CashCloseSummary` ignora `tarjeta`/`mixto` y existen cálculos de cierre duplicados en servicios/pantallas | **P1** | B: `DAT-09`, `ARC-01` | Verificado (`cash_close_summary.dart:75-109`) |
| **C-12** | Suite de pruebas limitada a 9 tests unitarios; sin cobertura de compras, caja, preparación, migraciones ni backups | **P1** | A: `H-07` / B: `TST-01` | Verificado (`test/`) |
| **C-13** | Migración parcial a `lib/features/*`, pantallas de hasta 1.818 líneas y servicios que mezclan SQL, reglas y PDF | **P2** | A: `H-08` / B: `ARC-01/02`, `QUA-01` | Verificado |
| **C-14** | Consultas SQL directas a `DatabaseHelper` desde servicios y creación de dependencias fuera de `MultiProvider` | **P2** | A: `H-08/H-10` / B: `ARC-01` | Verificado |
| **C-15** | `ReportesService` calcula costo solo con `costo_estimado_manual` (ignorando receta); `reporte_service.dart` y `recetas_screen.dart` son código muerto/roto | **P2** | A: `H-08` / B: `QUA-05` | Verificado (`reportes_service.dart:49-60`) |
| **C-16** | `Timer.periodic(5s)` en `DashboardScreen`, consultas N+1 y 0 sentencias `CREATE INDEX` en el esquema | **P2** | A: `H-09` / B: `DAT-06`, `PER-02` | Verificado (`dashboard_screen.dart:54-59`) |
| **C-17** | Cifrado PBKDF2 (310k iteraciones) + ZIP ejecutado en el Isolate principal durante el arranque cuando toca backup diario | **P2** | B: `PER-01` | Verificado (`main.dart:82`, `backup_service.dart:469`) |
| **C-18** | Estado residual en controladores globales tras `logout()` o restauración de backup; navegación mixta | **P1/P2** | A: `H-10` / B: `UX-02` | Verificado (`auth_controller.dart:59-64`) |
| **C-19** | `flutter analyze` reporta 79 `info` (código de salida `1`), incluyendo 12 `use_build_context_synchronously` e import de `sqflite` no declarado | **P2** | A: `H-11` / B: `§1/2` | Verificado (`sugerencias_algoritmo.dart:1`) |
| **C-20** | Release firmado con clave debug, `applicationId` `com.example.pizzaapp` y falta de exclusión de DB en Android Auto Backup | **P1** | A: `H-12` / B: `SEC-03`, `AND-02` | Verificado (`build.gradle.kts`, `AndroidManifest.xml`) |
| **C-21** | `GoogleFonts.poppins` sin permiso `INTERNET` en `main/AndroidManifest.xml` y sin fuentes `.ttf` locales en `pubspec.yaml` | **P1** | A: `H-13` / B: `AND-01` | Verificado (`pubspec.yaml`, `AndroidManifest.xml`) |
| **C-22** | 9 dependencias en `pubspec.yaml` sin ningún import en `lib/` y `sqlcipher_flutter_libs: ^0.7.0+eol` deprecado | **P3** | A: `H-13` / B: `DEP-01/02` | Verificado (`pubspec.yaml`) |
| **C-23** | Ausencia de pipeline CI/CD en `.github/workflows/` | **P2** | A: `H-14` / B: `CI-01` | Verificado |
| **C-24** | `README.md` genérico de plantilla Flutter y archivos temporales en raíz (`fix.py`, `old_repo.txt`) | **P2/P3** | A: `H-14` / B: `DOC-01`, `GIT-01` | En resolución en Fase 0 |
| **C-25** | Mensajes de error con `\$e` literal escapado y bloques `catch` silenciosos | **P2** | B: `QUA-03/04` | Verificado (`caja_controller.dart:39`, `insumo_controller.dart:26`) |
| **C-26** | Escaso uso de `Semantics`/tooltips y alturas fijas ante escalado de fuentes | **P2** | A: `UX` / B: `UX-01` | Verificado |
| **C-27** | `LoginScreen` etiqueta `'Usuario / Correo'` pero autentica solo por `username` | **P2** | B: `UX-02` | Verificado (`login_screen.dart:166`) |
| **C-28** | Baja lógica de usuario (`activo = 0`) sin opción de reactivación ni auditoría consistente | **P2** | B: `UX-03` | Verificado (`usuario_service.dart`) |
| **C-29** | `AssetController.registrarReparacion` puede dejar `_isLoading = true` si ocurre excepción | **P2** | B: `§7 estado` | Verificado (`asset_controller.dart`) |
| **C-30** | `OnboardingService.completeOnboarding` guarda configuración y crea el admin en transacciones separadas | **P1** | B: `§6 transacciones` | Verificado (`onboarding_service.dart:14-60`) |
| **C-31** | Uso directo de `GoogleFonts.poppins` y colores locales en lugar de `AppTextStyles`/`AppColors` | **P3** | B: `QUA-02` | Verificado |

---

## 2. Resolución Oficial de Discrepancias Documentales

1. **Salida de `flutter analyze` (`C-19`):** El comando reporta `0 errors, 0 warnings, 79 infos`, pero en Flutter 3.47.5 retorna `exit code 1` por defecto ante cualquier issue informativo.
2. **Conteo exacto de tablas (`C-08`):** `db_schema.dart` declara **35 tablas** y `database_helper.dart` declara **1 tabla adicional** (`PromocionProductos`), sumando **36 tablas** en tiempo de ejecución.
3. **Dependencias sin uso (`C-22`):** Confirmadas 9 dependencias de producción sin uso en `lib/` (`cached_network_image`, `fl_chart`, `screenshot`, `flutter_local_notifications`, `flutter_svg`, `printing`, `audioplayers`, `lottie`, `cupertino_icons`). Se conservan `sqflite_common_ffi` y `mocktail` en `dev_dependencies` para la suite de pruebas de la Fase 1.

---

## 3. Decisiones de Negocio Aprobadas (`RN-01` a `RN-12`)

Las 12 decisiones funcionales de la Sección 8 han sido aprobadas e incorporadas como reglas obligatorias en [`AGENTS.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/AGENTS.md) y [`docs/BUSINESS_RULES.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/BUSINESS_RULES.md).

---

## 4. Estado Post-Corrección (18/10/2026)

> Cierre del plan por fases ejecutado en la rama `refactor/auditoria-2026-10` (detalle y bitácora en [`agent.md`](file:///c:/D/ProyectoPizza/pizzaapp/agent.md)). No modifica el registro histórico de las secciones 1 a 3.

| ID | Hallazgo | Estado | Fase | Commit |
|---|---|---|---|---|
| **H-01** | Test en rojo: `actualizarMetodoPagoVenta` lanzaba un literal distinto al exigido ('ya fue cerrada') al rechazar operaciones sobre una sesión de caja cerrada | Corregido | F1 (pre-F0) | `b2af7a9` (baseline con las correcciones manuales del usuario) |
| **H-02** | 3 warnings del analyzer en `test/anular_editar_ventas_test.dart` (2 imports sin uso y variable `sesionId`) | Corregido | F1 (pre-F0) | `b2af7a9` (baseline con las correcciones manuales del usuario) |
| **H-03** | `ItemsPreparacion.sobrante` nunca se actualizaba; `SugerenciasAlgoritmo` sin señal real de faltantes | Corregido (enfoque A, v25) | F5 | `17e153a` |
| **H-04a** | SQL directo a `DatabaseHelper` en `usuario_service` y `onboarding_service`; onboarding sin transacción única | Corregido | F6 | `1e5194f` |
| **H-04b** | SQL directo a `DatabaseHelper` en `caja_service` | Corregido | F7 | `cef7c48` |
| **H-04c** | SQL directo a `DatabaseHelper` en `reportes_service` y PDF mezclado en el servicio | Corregido | F8 | `5c3938a` |
| **H-05** | `eliminarGasto` borraba `MovimientosCaja` por coincidencia difusa de monto/fecha; gasto sin vínculo explícito por id | Corregido (v24) | F2 | `1b20355` |
| **H-06** | Ruta paralela muerta de borrado de gastos (`GastoController`/`GastoService`) sin auditoría ni limpieza de caja | Corregido | F3 | `888d38a` |
| **H-07** | Si fallaba la generación de la boleta tras registrar la venta, el cobro quedaba en estado ambiguo (riesgo de doble venta) | Corregido | F4 | `e2a5937` |
| **H-08** | `AppRouter` montaba las rutas protegidas sin verificar la sesión activa | Corregido (solo sesión) | F9 | `ced7b21` |
| **H-09** | Sin `key.properties`, el build release se firmaba silenciosamente con la clave debug | Corregido | F10 | `29c6f0e` |
| **H-10** | Namespace Android `com.pizzaapp.pizzaapp` desalineado del `applicationId` `com.kimipizza.pos` | Corregido | F12 | `2ec343c` |
| **H-11** | Dependencia `sqlcipher_flutter_libs 0.7.0+eol` declarada sin ningún consumidor | Corregido | F11 | `ee23930` |
| **H-12** | Semántica para lectores de pantalla y escalado de texto deficientes en pantallas críticas (POS, Caja, anulación, gastos) | Corregido | F13 | `0bbfa2b` |
| **H-13** | Sin verificación de equivalencia entre esquema nuevo y migrado; sin `busy_timeout` ante bloqueos de escritura | Corregido | F14 | `e76af4c` |

**Regresión final (18/10/2026):** `flutter test --no-pub` = **75/75** (exit 0); `flutter analyze --no-pub` = **No issues found!** (exit 0); `git status --porcelain` = vacío.

**Gobernanza documental:** `AGENTS.md` sincronizado entre la raíz y `kimi_pizza_ai_framework/AGENTS.md` (`git diff --no-index` = vacío).

**Actualización documental (18/10/2026):** la cartilla principal del framework quedó alineada al estado post-corrección verificado: `README.md` y `PROMPT_MASTER.md` pasan a la versión **3.1.0**; `docs/DATA_MODEL.md`, `docs/IMPLEMENTED_CAPABILITIES.md`, `AGENTS.md` (raíz + framework) y `agent.md` reflejan el plan cerrado, las trampas resueltas y el esquema v25.

**Pendientes explícitos acumulados (limitaciones del entorno, no del código):**
- **F11 (e):** verificación funcional del cifrado SQLCipher en el APK instalado — sin dispositivo físico ni system-image de emulador en este entorno.
- **F12 (d):** instalación del APK debug y confirmación de arranque en dispositivo — mismo bloqueo de entorno.
- **F10:** la ruta positiva de firma release (con keystore real) no se ejecutó por diseño: el repositorio no versiona `android/key.properties`.
