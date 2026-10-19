# Registro de evaluación por control y cierre del ciclo (FS-8)

> **Fecha documental:** 18/10/2026 · **Fase:** `FS-8` (cierre del ciclo de evaluación) · **Fuente:** estado verificado del repositorio y artefactos de prueba generados en `FS-0`…`FS-7A`.
> **Firmado por:** propietario — aprobación explícita de las ratificaciones R-01…R-04, las excepciones E-01…E-06 y la consolidación de estados finales en la sesión de ejecución de `FS-8` (preguntas 1–4).
> **Límite:** este registro **no** es una Declaración de Aplicabilidad ni certifica ISO/IEC 27001/27002; documenta evidencia, herramientas, resultados, limitaciones y riesgo residual de la evaluación realizada, sin sustituir auditoría del SGSI.

## 1. Resultado del cierre

- **40/40 casos `SEC-*`** con disposición final (tabla completa en `docs/SECURITY_TEST_PLAN.md` §3.3): 37 cubiertos por prueba/inspección y 3 `No aplicable` ratificados.
- **24 filas de control** consolidadas: **16 `Implementado`**, **5 `Parcial`**, **2 `No evaluado`** (organizacionales, fuera del alcance del repositorio) y **1 `No aplicable`** (ratificado).
- **4 ratificaciones** `No aplicable` (R-01…R-04) aprobadas por el propietario.
- **6 excepciones aceptadas** (E-01…E-06) con dueño, compensación y caducidad.
- **5 pendientes operativos** (P-01…P-05), no bloqueantes del cierre y con responsable; **P-02 quedó ejecutado el 19/10/2026** (canario de CI verificado), por lo que quedan 4 abiertos.
- **Revisor de la consolidación:** propietario (aprobación del 18/10/2026). La preparación técnica y la evidencia por fase corrieron a cargo del agente sobre el repositorio local; no se ejecutaron pruebas destructivas ni con datos reales.

## 2. Ratificaciones `No aplicable` (R-01…R-04)

| ID | Caso / control | Declaración | Justificación verificada | Condición de reapertura |
|---|---|---|---|---|
| R-01 | SEC-016 · ISO 8.20–8.22 | TLS no evaluable hoy | Sin tránsito de red: manifiesto release sin `INTERNET`, sin backend ni endpoints; operación 100 % offline verificada (`FS-7`) | Incorporación de red, backend o sincronización → reevaluar TLS, endpoints y config de red |
| R-02 | SEC-017 · ISO 8.2–8.5 | Autorización server-side no aplicable | Sin backend: la autorización se aplica en dominio, navegación y servicios (`FS-6`) | idem R-01 |
| R-03 | SEC-040 | Anti-sync/replay remoto no aplicable | Sin sincronización remota ni operaciones replicadas hoy | idem R-01 |
| R-04 | ISO 8.30 | Desarrollo externalizado no aplicable | Sin proveedores externos de desarrollo o servicios gestionados | Contratación de desarrollo o servicios externos → evaluación de proveedor |

## 3. Registro de evaluación por control (estado final)

Entradas con fecha/commit, evidencia, herramienta y versión, resultado y limitaciones/riesgo residual. Estados según `docs/SECURITY_CONTROL_MATRIX.md`.

| Control(es) | Estado final | Fecha / commit | Evidencia | Herramienta y versión | Resultado | Limitaciones / riesgo residual |
|---|---|---|---|---|---|---|
| ISO 5.15 / 5.16 / 5.17 / 5.18 | Implementado | 18/10/2026 · `a482224` (FS-6) | `docs/SECURITY_ACCESS_EVIDENCE.md`; `test/acceso_cuentas_sesion_seguridad_test.dart` | Flutter/Dart (`flutter test` 139/139 en FS-6; 144/144 en el cierre) | SEC-001…010 con resultado: mensaje genérico, bloqueo 5/30 s, logout limpia carrito, inactivos/bloqueados rechazados, ciclo auditado, última admin protegida | E-01 (bloqueo en memoria), E-04 (límite local-only), E-05 (autodemoción/auditoría de alta-edición) |
| ISO 8.2 / 8.3 / 8.5 · MASVS-AUTH | Implementado | 18/10/2026 · `a482224` (FS-6) | `docs/SECURITY_ACCESS_EVIDENCE.md` | Flutter/Dart (`flutter test`) | Autoescalada de rol rechazada, `authorizeAdminOperation` revalida la BD, edición de otro usuario por ID denegada sin cambios | E-04 (servicio confía en el rol en memoria; lecturas sin autorización por objeto) |
| ISO 5.34 · MASVS-PRIVACY | Parcial | 18/10/2026 · `FS-7` (dispositivo) + `FS-8` (decisión) | `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §6 | `adb` / `dumpsys package` (build-tools 36.0.0) | Permisos efectivos: `READ_MEDIA_*` no concedidos; sin analítica ni SDK de telemetría; datos permanecen en el dispositivo | Inventario y retención formales (organizacional, fuera del repositorio); E-06 |
| ISO 8.24 · MASVS-CRYPTO | Parcial | 18/10/2026 · `FS-5`/`FS-7` | `docs/SECURITY_STATIC_EVIDENCE.md`; `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §3 | `flutter analyze`; `apksigner`/`aapt2` 36.0.0 | SQLCipher AES-256, PBKDF2 310k, `.kpzbackup` AES-256-GCM; sin claves embebidas; APK release sin secretos de servidor | P-01 (firma de producción), P-03 (gestión/rotación de la clave de BD) |
| ISO 8.8 / 8.9 · MASVS-CODE | Implementado | 18/10/2026 · `a176041` (CI) y `5cb05f0` (FS-7A) | `.github/workflows/ci.yml`; `test/respaldo_dialogo_seguridad_test.dart`; `docs/SECURITY_STATIC_EVIDENCE.md` | Gitleaks v3 + OSV-Scanner v2.7.0 (configuración validada localmente); `flutter test` | 121 paquetes revisados, 0 advisories OSV; `DEF-FS7-01` corregido con regresión 5/5 | P-01 (firma de producción); P-02 ejecutado el 19/10/2026 (canario verificado: job `118319199755`) |
| ISO 8.12 / 8.15 / 8.16 | Implementado | 18/10/2026 · `73df1aa` (FS-5) | `docs/SECURITY_STATIC_EVIDENCE.md` | Búsqueda por patrones en `lib/` | 6 `debugPrint` revisados sin secretos; operaciones críticas auditadas con `AuditLogWriter` | — |
| ISO 8.20 / 8.21 / 8.22 · MASVS-NETWORK | Implementado | 18/10/2026 · `FS-7` | `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §5 | `aapt2`; `adb` (modo avión) | Release sin `INTERNET` ni endpoints; arranque, restauración y login 100 % offline | R-01: reapertura si se incorpora red |
| ISO 8.26 / 8.27 / 8.28 | Implementado | 18/10/2026 · `da97b2f` (FS-2) | Tests de entradas/integridad (`test/entradas_invalidas_seguridad_test.dart`, `test/inyeccion_sql_seguridad_test.dart`, `test/integridad_*_seguridad_test.dart`) | Flutter/Dart (`flutter test`) | SEC-018/019/020 con resultado; invariantes RN-01…RN-12 cubiertas por pruebas | — |
| ISO 8.29 | Implementado | 18/10/2026 · `FS-1`…`FS-7` | `docs/SECURITY_TEST_PLAN.md` (§3.1–§3.3) | `flutter test` (144/144) y `flutter analyze` (0) | 40 casos ejecutados o ratificados; suite y analyze verdes en el cierre | — |
| ISO 8.31 / 8.32 | Parcial | 18/10/2026 · `FS-0`…`FS-8` | `agent.md`; historial de commits | Git | Trabajo por fases con commit unitario y CI presente | P-04 (política de PR y protección de rama) |
| ISO 8.33 / 8.34 | Parcial | 18/10/2026 · `FS-5`/`FS-8` | `docs/SECURITY_STATIC_EVIDENCE.md` | Inspección de pruebas y artefactos | Pruebas con datos sintéticos y base efímera `sqflite_common_ffi` | P-05 (verificación formal de ausencia de datos reales en pruebas/artefactos) |
| MASVS-STORAGE | Implementado | 18/10/2026 · `FS-5`/`FS-7` | `docs/SECURITY_STATIC_EVIDENCE.md`; `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §4 | Inspección estática; SAF/`adb` | Sin credenciales en claro; `.kpzbackup` cifrado sin marcadores; restauración cruzada tras reinstalar | — |
| MASVS-PLATFORM | Implementado | 18/10/2026 · `FS-5`/`FS-7` | `docs/SECURITY_STATIC_EVIDENCE.md`; `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §3 y §6 | `aapt2`; `dumpsys package` | Manifiesto mínimo (`exported=false`, sin deep links), permisos efectivos acotados | E-06 (`READ_MEDIA_VIDEO`/`AUDIO` declarados por `open_filex`, no concedidos) |
| MASVS-RESILIENCE | Parcial | 18/10/2026 · `FS-5`/`FS-7` | `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §7 | `apksigner` 36.0.0 | Release v2 firmado con keystore de prueba (≠ debug), sin `debuggable`, `run-as` rechazado | P-01 (firma de producción); sin ofuscación por decisión de alcance (límite declarado S2) |
| Integridad POS: venta | Implementado | 18/10/2026 · `da97b2f` (FS-2) | `test/integridad_cobro_seguridad_test.dart`; `test/pos_boleta_resiliencia_test.dart` (SEC-026, 3/3) | Flutter/Dart (`flutter test`) | Doble cobro/reintento sin duplicar; fallo de PDF no duplica la venta (H-07) | Validación en dispositivo de los flujos de UI no exigida por el propietario |
| Integridad POS: inventario | Implementado | 18/10/2026 · `da97b2f` (FS-2) | `test/integridad_inventario_seguridad_test.dart`; `test/compra_doble_submit_seguridad_test.dart` | Flutter/Dart (`flutter test`) | Fuente única `StockMovementWriter`; concurrencia sin doble descuento; compra reenviada sin duplicar | — |
| Integridad POS: caja | Implementado | 18/10/2026 · `e9bce34` (FS-3) | `test/caja_ciclo_operativo_seguridad_test.dart` | Flutter/Dart (`flutter test`) | SEC-029/030/031: reapertura no autorizada denegada, cierre único, reapertura autorizada auditada | — |
| Integridad QR | Implementado | 18/10/2026 · `40dbc6c` (FS-4) + `FS-7` | `test/qr_administrativo_seguridad_test.dart`; validación manual con galería/cámara en la entrada parcial de `FS-7` de `agent.md` | Flutter/Dart; dispositivo (Photo Picker/cámara) | Solo admin administra el QR; rollback conserva el previo; fuente de verdad única en el cobro | — |
| PDF/documentos | Implementado | 18/10/2026 · `da97b2f`/`09dea39` (FS-2/FS-2B) | `test/imagen_pdf_seguridad_test.dart`; `test/imagenes_limite_seguridad_test.dart` | Flutter/Dart (`flutter test`) | Límite 1600 px / 5 MB; logo corrupto → boleta sin logo con error seguro | — |
| Secret scanning | Implementado | 18/10/2026 · `a176041` (FS-5) | `.github/workflows/ci.yml`; `docs/SECURITY_STATIC_EVIDENCE.md` §7 | Gitleaks v3 (job `secret-scan`) | Barrido de árbol e historia (42 commits) sin secretos reales; `key.properties` ignorado | P-02 ejecutado el 19/10/2026 (canario con secreto falso: fallo redactado en CI; PR #2 cerrado sin fusionar) |
| ISO 5.8 / 8.25 | Implementado | 18/10/2026 · `FS-0`…`FS-8` | `docs/SECURITY_ACTION_PLAN.md`; `docs/SECURITY_PHASE_PROMPTS.md`; evidencia por fase | Revisión documental por fase | Definition of Done y límites/menazas (S2) declarados por fase sensible | Sostener la práctica de revisión por cambio sensible; P-04 |
| ISO 5.9 / 5.12 | No evaluado (fuera del alcance del repositorio) | — | — | — | — | Inventario y clasificación formal de activos/datos: decisión organizacional del propietario |
| ISO 4–10 · Incident response | No evaluado (fuera del alcance del repositorio) | — | — | — | — | Decisión organizacional del responsable (runbook, canales, ejercicios) |
| ISO 8.30 | No aplicable (ratificado) | 18/10/2026 · `FS-8` (R-04) | Este registro §2 | — | Sin desarrollo externalizado actualmente | Reabrir si se contrata desarrollo o servicios externos |

## 4. Excepciones aceptadas (E-01…E-06)

> Aceptadas por el propietario el 18/10/2026. Dueño de todas: propietario. Caducidad propuesta: **18/04/2027**, o reapertura anticipada si cambia la arquitectura (backend, red, multiusuario) o una exigencia externa lo requiere. La reapertura se ejecuta como fase aprobada con pruebas y gate propios.

| ID | Residual | Compensación vigente | Reapertura anticipada si… |
|---|---|---|---|
| E-01 | SEC-002: bloqueo de intentos solo en memoria (5 intentos / 30 s por proceso), sin persistencia ni auditoría de intentos | PBKDF2-HMAC-SHA256 310k encarece la fuerza bruta; app local de un solo dispositivo con acceso físico controlado | Se exige bloqueo persistente/auditado o soporte multiusuario |
| E-02 | SEC-005: una sesión ya abierta no se revalida por operación tras desactivar/bloquear al usuario; el cambio aplica al siguiente acceso | Revalidación obligatoria en `login`/`loginRapido`; producto de un solo dispositivo con cambio de estado administrativo controlado | Se exige revocación inmediata (multiusuario/backend) |
| E-03 | SEC-006: la guarda de ruta valida sesión, no rol; la denegación por rol vive en menú/UI ("Acceso Restringido") y servicios | Rutas administrativas deniegan escritura en servicios; alcance aprobado en F9; sin modificación de datos por navegación directa | Se quiere defensa en profundidad explícita en el router |
| E-04 | SEC-007/008: límite local-only — el servicio confía en el rol en memoria y las lecturas no tienen autorización por objeto; root/dueño del dispositivo puede leer la base con la clave | `authorizeAdminOperation` revalida contra la BD; UI no expone edición ajena; límite físico/root declarado (S2) | Se añade backend o requisitos de autorización por objeto |
| E-05 | SEC-010: autodemoción no bloqueada explícitamente en el servicio (la UI oculta el selector propio); alta/edición de usuarios sin evento en `LogsAuditoria` | Auto-baja/auto-bloqueo bloqueados en servicio; ciclo de estados auditado; la operación de edición ajena está denegada | Se aprueba añadir la guarda de autodemoción y auditar alta/edición |
| E-06 | READ_MEDIA_VIDEO/AUDIO declarados por `open_filex` (imágenes también; usuario seleccionado en Android 14+) | Permisos no concedidos (`granted=false`); galería por Photo Picker y respaldo por SAF funcionan sin permisos de medios | Google exige justificación de permisos o el plugin permite acotarlos |

## 5. Pendientes operativos (P-01…P-05, no bloqueantes; P-02 cerrado el 19/10/2026)

| ID | Pendiente | Responsable | Nota |
|---|---|---|---|
| P-01 | Firma de producción con keystore definitivo | Propietario | El release de prueba quedó verificado con keystore local reemplazable; el gate de firma ya falla sin `key.properties` |
| P-02 | Canario de aceptación de la CI (SEC-037) | Propietario / CI | ✅ Ejecutado el 19/10/2026: PR #2 con `AKIAKIMIPIZZACANARY2` (secreto falso); `secret-scan` falló redactado (run `39328148173`, job `118319199755`) y la rama limpia pasó (run `39325175339`); PR cerrado sin fusionar y rama eliminada. Evidencia: `docs/SECURITY_STATIC_EVIDENCE.md` §7.3 |
| P-03 | Gestión/rotación de la clave de la base de datos | Propietario | Hoy en almacenamiento seguro del dispositivo; definir política de rotación/restauración |
| P-04 | Política de PR y protección de rama | Propietario | El trabajo actual es local con commit por fase; decidir si se adopta revisión por PR |
| P-05 | Verificación formal de ausencia de datos reales en pruebas y artefactos | Propietario | Las pruebas usan datos sintéticos y `sqflite_common_ffi`; falta la verificación formal documentada |

## 6. Cierre

- **Revisión final:** ningún caso `SEC-*` sin disposición; ninguna fila de control sin estado final; excepciones con dueño, compensación y caducidad; pendientes identificados y con responsable.
- **Aprobación del propietario (18/10/2026):** ratificaciones R-01…R-04, excepciones E-01…E-06 y consolidación de estados finales (respuestas explícitas 1–4 de la sesión de `FS-8`).
- **Gate de la fase:** documentación sin cambios en `lib/`, `test/` ni `android/` versionado. Puerta de cierre ejecutada en la misma sesión: `flutter test --no-pub` → **144/144** (`All tests passed!`, exit 0) y `flutter analyze --no-pub` → **`No issues found!`** (exit 0).
- **Commit de cierre:** `docs: cierre del ciclo de evaluacion de seguridad`.

*Fin del registro de cierre (`FS-8`).*
