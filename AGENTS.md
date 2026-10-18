# AGENTS.md — PROTOCOLO DE ORQUESTACIÓN Y CONSTITUCIÓN TÉCNICA PARA AGENTES IA
**Versión:** 3.0.0 (Consolidated Audit & Approved Business Rules Edition)  
**Sistema:** KIMI PIZZA POS (`com.kimipizza.pos`)  
**Plataforma Objetivo:** Flutter / Dart / Android / SQLite con SQLCipher (AES-256)  

> **Documentación extendida:** El catálogo detallado de especificaciones, reglas de negocio y auditoría consolidada se encuentra en [`kimi_pizza_ai_framework/`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/README.md) y [`kimi_pizza_ai_framework/docs/AUDIT_CONSOLIDATED.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/AUDIT_CONSOLIDATED.md).

---

## 1. PROPÓSITO Y PRIORIDADES DE INGENIERÍA

Este documento es la **fuente de verdad obligatoria** para cualquier agente autónomo de Inteligencia Artificial o desarrollador humano que modifique el repositorio `pizzaapp` (**Kimi Pizza POS**). Integra los hallazgos verificados del **Informe Consolidado de Auditoría Técnica (`C-01` a `C-31`)** y las **12 Decisiones Oficiales de Negocio (`RN-01` a `RN-12`)** aprobadas.

### Orden estricto de prioridades
1. **Integridad financiera y de inventario** (`C-01` a `C-04`, `C-10`, `C-11`).
2. **Seguridad de acceso, bloqueo efectivo y credenciales** (`C-05`, `C-06`, `C-20`).
3. **Integridad referencial y migraciones SQLite sin pérdida de datos** (`C-07`, `C-08`, `C-09`, `C-30`).
4. **Operación 100% Offline-First, pruebas automatizadas y arquitectura limpia** (`C-12` a `C-19`, `C-21` a `C-31`).

---

## 2. REGLAS ARQUITECTÓNICAS ESTRICTAS (PROHIBIDO VIOLAR)

1. **No reemplazar el stack base:** Mantener `Provider` (`MultiProvider` + `ChangeNotifier`) y `sqflite_sqlcipher`. Prohibido introducir Riverpod, BLoC, Drift o Isar. La evolución es incremental hacia la estructura por *features* (`lib/features/<feature>/{domain,application,data,presentation}`).
2. **Separación de responsabilidades en capas:**
   - `presentation/` (`screens`, `widgets`, `controllers`): Solo estado visual, validación de formularios y llamadas a servicios/casos de uso. **Prohibido** importar `DatabaseHelper` o ejecutar SQL en pantallas o controladores.
   - `application/` / `domain/` (`services`, `entities`, `usecases`): Reglas de negocio puras y coordinación. **Prohibido** escribir sentencias SQL directas en servicios nuevos o mezclar generación de documentos PDF (`package:pdf`) dentro de servicios transaccionales.
   - `data/` (`repositories`, `core/database`): Único lugar autorizado para interactuar con SQLite/SQLCipher y manejar transacciones (`db.transaction`).
3. **Escritores centralizados obligatorios:**
   - **Stock / Kardex:** Toda variación de stock de insumos o productos debe registrarse mediante `StockMovementWriter` (`lib/features/inventory/data/stock_movement_writer.dart`) dentro de la misma transacción (`txn`).
   - **Auditoría:** Toda operación crítica de caja, edición/anulación de deudas o cambio de estado de usuarios debe registrarse mediante `AuditLogWriter` (`lib/core/database/audit_log_writer.dart`) dentro de la misma `txn`.
4. **Higiene de sesión en memoria (`C-18`):**
   - Al ejecutar `AuthController.logout()` o restaurar un respaldo en `BackupScreen`, se debe limpiar el carrito de `PosController` y reinicializar los estados en caché de los controladores activos para impedir fugas de datos entre sesiones.

---

## 3. LAS 12 REGLAS DE NEGOCIO OFICIALES (DECISIONES APROBADAS)

### RN-01. Edición de compras a crédito con abonos previos (`C-01` — `purchase_repository.dart`)
- Se permite editar una compra a crédito que ya tenga abonos en `PagosCuentaPorPagar`, **recalculando el saldo pendiente con la suma real de los abonos existentes** (`monto_pagado = adelanto_actualizado + SUM(abonos_posteriores)`).
- Si el `nuevo_total` de la compra es menor que el total ya abonado (`nuevo_total < monto_pagado`), la operación debe **rechazarse con excepción de negocio**.
- Al editar el adelanto inicial, nunca se debe duplicar el registro en `Gastos` ni en `MovimientosCaja`; se debe actualizar o ajustar únicamente la diferencia contra el registro vinculado por ID.

### RN-02. Eliminación de gastos vinculados a compras o deudas (`C-02` — `purchase_repository.dart`)
- Queda **bloqueada la eliminación directa desde la bandeja genérica de Gastos** para cualquier gasto originado por una compra o por un abono de `CuentasPorPagar`.
- La anulación de un abono solo puede ejecutarse desde el módulo de **Cuentas por Pagar**, revirtiendo atómicamente la deuda en `CuentasPorPagar`, el registro en `PagosCuentaPorPagar`, el `Gasto` y el `MovimientoCaja` mediante **IDs explícitos** (prohibido borrar `MovimientosCaja` por coincidencia difusa de monto/fecha).

### RN-03. Invariante de sobrantes, merma y traslado para mañana (`C-03`, `C-04`, `C-10` — `preparacion_repository.dart`)
- **Invariante física estricta:** Tanto en `registrarPreparacion` como en `procesarSobrantesPendientes`, se debe validar que `enviado_merma + llevado_manana <= cantidad_preparada` y que la cantidad a descontar/trasladar nunca supere el `stock_actual` disponible de la variante (prohibido registrar merma mayor al stock realmente descontado).
- **Idempotencia en traslado (`llevarParaManana`):** Se debe verificar que el `UPDATE` condicional en el origen afecte exactamente `1` fila antes de insertar o acumular (`UPSERT`) en la preparación del día siguiente.
- **Alimentación del algoritmo (`ItemsPreparacion.sobrante`):** Al cerrar sobrantes del día, la columna `sobrante` de `ItemsPreparacion` debe actualizarse con la suma `enviado_merma + llevado_manana` para alimentar `SugerenciasAlgoritmo`.

### RN-04. Métodos de pago oficiales y cuadre de caja (`C-11` — `cash_close_summary.dart`)
- La pizzería opera con dos rubros de cobro en el arqueo: **Efectivo** (`efectivo`) y **Digital/Bancario** (`yape`, `plin`, `yape/plin`, `transferencia`, `tarjeta`).
- Se deshabilita la opción `mixto` hasta que exista una estructura de desglose de montos por medio de pago.
- `CashCloseSummary` es la única clase que calcula el cuadre de caja (pantalla, repositorio y PDF deben consumir su resultado sin recalcular por separado).

### RN-05. Costo de mercadería vendida en Reportes (`C-15` — `reportes_service.dart`)
- Para calcular el costo de ventas (COGS) y la utilidad en reportes, **se prioriza el costo calculado automáticamente por la receta activa** de la variante (`Recetas` + `DetallesReceta` + costo de `Insumos`). Solo cuando una variante no tenga receta configurada se utilizará `costo_estimado_manual` como respaldo.

### RN-06. Jornada operativa después de medianoche
- La jornada operativa de ventas, gastos y cierre se rige por la **sesión de caja activa (`sesion_caja_id`)**, independientemente de si las ventas o el cierre ocurren después de las `00:00` (medianoche).

### RN-07. Venta de productos `'momento'` o `'ambos'` sin receta o sin stock (`venta_repository.dart`)
- Se mantiene el **bloqueo estricto**: no se permite vender un producto de preparación al momento si no tiene receta activa configurada o si los insumos requeridos no tienen stock suficiente, devolviendo un mensaje de negocio claro al cajero.

### RN-08. Política de Android Auto Backup vs. `.kpzbackup` (`C-20` — `AndroidManifest.xml`)
- Se desactiva el backup automático de la base de datos SQLCipher en la nube de Android (`allowBackup="false"` o exclusión explícita de `pizzaapp_secure.db` en `dataExtractionRules` / `fullBackupContent`) para evitar bases de datos huérfanas de su clave de Android Keystore. El único mecanismo oficial de respaldo y restauración es el archivo portátil cifrado `.kpzbackup`.

### RN-09. Identidad de aplicación Android en producción (`C-20` — `build.gradle.kts`)
- El `applicationId` oficial de producción se fija como `com.kimipizza.pos` y el nombre visible (`android:label`) como **`Kimi Pizza POS`**, con firma de release gestionada mediante `key.properties` fuera del control de versiones.

### RN-10. Credencial de inicio de sesión y bloqueo efectivo (`C-05`, `C-27` — `login_screen.dart`, `usuario_repository.dart`)
- La autenticación se realiza exclusivamente por **nombre de usuario (`username`)** y validando obligatoriamente **`activo = 1 AND bloqueado = 0`**. La etiqueta visual del formulario de login debe decir únicamente **`Usuario`** (sin mencionar Correo).

### RN-11. Ciclo de vida y reactivación de usuarios (`C-28` — `usuario_service.dart`)
- El administrador puede tanto **bloquear/desbloquear temporalmente** (`bloqueado = 1 / 0`) como **desactivar/reactivar** usuarios dados de baja lógica (`activo = 0 / 1`), impidiendo siempre el auto-bloqueo/auto-baja del propio administrador en sesión y registrando cada acción en `LogsAuditoria`.

### RN-12. Gobernanza documental y limpieza de raíz (`C-24`)
- `AGENTS.md` vive sincronizado en la raíz del proyecto y en `kimi_pizza_ai_framework/AGENTS.md`. La documentación de `kimi_pizza_ai_framework/docs/` se mantiene alineada con el código real, sin archivos basura temporales en la raíz.

---

## 4. TRAMPAS TÉCNICAS DE SQLITE Y SEGURIDAD (GUARDRAILS CRÍTICOS)

1. **TRAMPA 1 (`C-07` + `C-09` — Foreign Keys vs Activos Fijos):**
   - `DatabaseHelper` actualmente NO activa `PRAGMA foreign_keys = ON`.
   - **PROHIBIDO activar `PRAGMA foreign_keys = ON`** sin antes migrar `CuentasPorPagar.insumo_id` a `INTEGER NULL` (y agregar `activo_fijo_id INTEGER NULL`), convertir los registros con `insumo_id = 0` a `NULL`, eliminar `'insumo_id': 0` en `ActivoFijoService.registrarActivo` (`lib/features/assets/application/asset_service.dart`) y verificar que `PRAGMA foreign_key_check` devuelva 0 filas.
2. **TRAMPA 2 (`C-08` — Sincronización de las 36 tablas):**
   - `db_schema.dart` contiene 35 tablas y `database_helper.dart` crea 1 tabla adicional (`PromocionProductos`) en `onUpgrade`. Además, `ItemsCombo`, `RecuperacionCuenta`, `Proveedores` y `TransferenciasInsumos` están en `db_schema.dart` pero faltan en migraciones históricas. Cualquier cambio de esquema debe dejar `DbSchema.createTables` y `onUpgrade` 100% equivalentes.
3. **TRAMPA 3 (`C-06` — Migración de `HashUtils`):**
   - `HashUtils` actualmente usa SHA-256 sin sal. Al migrar a PBKDF2-HMAC-SHA256 con sal aleatoria por usuario (`pbkdf2_sha256$<iter>$<salt_b64>$<hash_b64>`), se debe conservar la lectura de hashes legacy de 64 caracteres hexadecimales y actualizarlos transparentemente al iniciar sesión.
4. **TRAMPA 4 (`C-21` — Fuentes Offline en Release):**
   - `android/app/src/main/AndroidManifest.xml` no tiene permiso `INTERNET`. Los archivos `.ttf` de `Poppins` deben empaquetarse en `assets/fonts/` y declararse en `pubspec.yaml` con `GoogleFonts.config.allowRuntimeFetching = false`.

---

## 5. PROTOCOLO DE EJECUCIÓN POR FASES (TDD + ZERO REGRESSIONS)

Nunca ejecutes más de una fase en un mismo turno. Sigue estrictamente este orden:

- **Fase 0:** Preservación, limpieza de archivos basura de raíz y actualización del framework documental (`AGENTS.md`, `PROMPT_MASTER.md`, `docs/`).
- **Fase 1 (`C-12`):** Crear suite de pruebas de caracterización en `test/` con `sqflite_common_ffi` para compras/CxP, sobrantes, traslados, cuadre de caja y autenticación.
- **Fase 2 (`C-01` a `C-05`):** Corregir `corregirCompra` (`RN-01`), `eliminarGasto`/anulación CxP (`RN-02`), `procesarSobrantesPendientes` y `llevarParaManana` (`RN-03`), y `bloqueado = 0` en login (`RN-10`).
- **Fase 3 (`C-06`, `C-18`, `C-27`, `C-28`, `C-30`):** Migrar `HashUtils` a PBKDF2 con sal + upgrade legacy, endurecer recuperación de cuenta, limpiar estado en `logout()`/restore, ajustar login a `Usuario`, reactivación auditada de usuarios y onboarding transaccional.
- **Fase 4 (`C-07`, `C-08`, `C-09`, `C-16`):** Eliminar centinela `insumo_id = 0`, alinear las 36 tablas en esquema y migraciones lineales, activar `PRAGMA foreign_keys = ON` y crear índices SQLite.
- **Fase 5 (`C-20`, `C-21`):** Empaquetar fuentes Poppins offline, configurar `com.kimipizza.pos`, reglas de exclusión de Android Auto Backup y firma release.
- **Fase 6 (`C-10`, `C-11`, `C-13`, `C-14`, `C-15`, `C-25`, `C-29`):** Centralizar `CashCloseSummary` (`RN-04`), alimentar `ItemsPreparacion.sobrante` (`RN-03`), priorizar costo de receta en reportes (`RN-05`), corregir literales `$e`, arreglar `isLoading` en `AssetController` y eliminar código muerto (`reporte_service.dart`, `recetas_screen.dart`).
- **Fase 7 (`C-16`, `C-17`, `C-26`, `C-31`):** Mover cifrado PBKDF2 de `BackupService` a `Isolate.run`, eliminar `Timer.periodic(5s)` en `DashboardScreen`, resolver N+1 y mejorar `Semantics`/escalado de texto.
- **Fase 8 (`C-19`, `C-22`, `C-23`, `C-24`):** Retirar los 9 paquetes sin uso (conservando `sqflite_common_ffi` y `mocktail`), dejar `flutter analyze` en 0 issues (exit code `0`), crear workflow CI en `.github/workflows/` y actualizar `README.md`.

### Verificación obligatoria al cierre de cada fase
```powershell
flutter test --no-pub
flutter analyze --no-pub
```
