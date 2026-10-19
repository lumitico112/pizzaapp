# KIMI PIZZA — Matriz de controles y evidencias de seguridad

Esta matriz es un instrumento de trabajo para convertir los requisitos de `docs/SECURITY_BASELINE.md` en verificación reproducible. Los IDs ISO son referencias de control a validar con la edición oficial aplicable. No es una Declaración de Aplicabilidad (SoA) ni certifica cumplimiento.

## Estados

- `No evaluado`: todavía no se revisó implementación/evidencia.
- `No implementado`: falta el control requerido.
- `Parcial`: existe, pero no cubre el riesgo completamente.
- `Implementado`: evidencia revisada y prueba pasada.
- `No aplicable`: justificación formal por arquitectura/riesgo, aprobada por el responsable.
- `Excepción aceptada`: riesgo residual con dueño, compensación y fecha de expiración.

No marcar `Implementado` porque el código parezca correcto. Adjuntar ruta de evidencia, comando, resultado, fecha/commit y revisor.

| ID | Área | Riesgo que cubre | Evidencia esperada | Prueba mínima | Estado inicial |
|---|---|---|---|---|---|
| ISO/IEC 27001 cl. 4–10 | SGSI organizacional | falta de contexto, liderazgo, riesgo, evaluación o mejora | alcance SGSI, evaluación de riesgos, SoA, auditorías, revisiones, mejora | auditoría organizacional | No evaluado |
| ISO 5.8 / 8.25 | Seguridad en proyectos / ciclo seguro | seguridad agregada tarde | Definition of Done y revisiones de seguridad por cambio | PR demuestra modelado/revisión de amenaza si aplica | No evaluado |
| ISO 5.9 / 5.12 | Inventario / clasificación | activos y datos sin dueño o sensibilidad | inventario de datos y clasificación | comprobar campos, exports, backups y logs contra clasificación | No evaluado |
| ISO 5.15 / 5.16 / 5.17 / 5.18 | Acceso, identidades, autenticación y derechos | suplantación o privilegios indebidos | política de roles, flujo de autenticación, ciclo de altas/bajas | empleado prueba acción admin; usuario desactivado no accede | No evaluado |
| ISO 8.2 / 8.3 / 8.5 | Privilegios, restricción de acceso y autenticación segura | acceso indebido a recursos/funciones | autorización por caso de uso/endpoint y sesión | manipular role/ID no concede acceso | No evaluado |
| ISO 5.34 | Privacidad y protección de datos personales | exposición de datos de usuarios | inventario de datos, retención, minimización | inspeccionar logs, exportaciones y backup | No evaluado |
| ISO 8.24 | Criptografía | datos/secretos sin protección adecuada | decisión criptográfica, almacenamiento de claves, TLS | no aceptar TLS inválido; revisar almacenamiento | No evaluado |
| ISO 8.8 / 8.9 | Vulnerabilidades y configuración | SDK/dependencias/configuración insegura | inventario de dependencias, advisory scan, baseline por plataforma | escaneo de dependencias y revisión config release | No evaluado |
| ISO 8.12 / 8.15 / 8.16 | Fuga de datos, logging y monitorización | secretos en logs o incidentes no detectados | política de redacción, eventos de auditoría y retención | búsqueda automática de tokens/secrets en logs/pruebas | No evaluado |
| ISO 8.20 / 8.21 / 8.22 | Seguridad de red/servicios/segmentación | tráfico interceptado o entorno mezclado | TLS, endpoints configurados por ambiente, reglas de red | probar que release no usa HTTP ni endpoint dev | No evaluado |
| ISO 8.26 / 8.27 / 8.28 | Requisitos, arquitectura segura y código seguro | fallos de diseño/inyección | revisión de arquitectura, validación y threat model | pruebas de input, permisos y rutas | No evaluado |
| ISO 8.29 | Pruebas de seguridad | vulnerabilidad no detectada antes de release | CI, test reports, plan MASTG | ejecución de casos negativos y SAST/SCA | No evaluado |
| ISO 8.30 | Desarrollo externalizado, cuando aplique | código/servicios externos no gobernados | evaluación de proveedor, contrato, acceso y revisión de código | verificar dependencias/servicio externo | No evaluado |
| ISO 8.31 / 8.32 | Separación de ambientes y gestión de cambios | cambios sin control o producción desde configuración de dev | configuración por ambiente, revisión PR, protección ramas | release no apunta a staging/dev | No evaluado |
| ISO 8.33 / 8.34 | Datos de prueba y protección durante auditoría | filtración de producción durante testing | fixtures sintéticos, plan de prueba autorizado | verificar ausencia de datos reales y límites de entorno | No evaluado |
| MASVS-STORAGE | Almacenamiento móvil | datos/tokens extraíbles o incluidos en backup | diseño local, política de backup, uso de almacenamiento seguro | inspección de almacenamiento y backup | No evaluado |
| MASVS-CRYPTO | Criptografía móvil | cifrado incorrecto o clave embebida | librerías reconocidas, decisiones de clave | buscar claves constantes y revisar flujo TLS/cifrado | No evaluado |
| MASVS-AUTH | Autenticación móvil | bypass, sesión expirada o rol manipulado | diagramas de login/logout/refresh y política de permisos | token expirado/revocado; empleado intenta admin | No evaluado |
| MASVS-NETWORK | Tránsito | MITM o tráfico claro | config Android/iOS, endpoints HTTPS | proxy de prueba controlado y TLS inválido | No evaluado |
| MASVS-PLATFORM | Interacción SO | exportación de componentes/archivos/permisos excesivos | manifest, plist, deep links, permisos | revisar components exported, URLs y archivos compartidos | No evaluado |
| MASVS-CODE | Código/dependencias | vulnerabilidades en código/SDK | analyzer, dependencias y CI | análisis estático y pruebas | No evaluado |
| MASVS-RESILIENCE | Manipulación/reversión | binario alterado o ingeniería inversa | threat model, firma, release hardening | revisar firma y build release; no se espera inmunidad absoluta | No evaluado |
| MASVS-PRIVACY | Privacidad | datos excesivos o telemetría no deseada | inventario y finalidad de datos/SDKs | permisos y red saliente revisados | No evaluado |
| Integridad POS: venta | Fraude/doble registro | doble cobro o venta duplicada | operación idempotente, Sale/Payment ligados | doble toque/reintento no genera duplicidad | No evaluado |
| Integridad POS: inventario | Stock falso | consumo duplicado o ajuste no auditado | flujo único de StockMovement | compra/venta/merma producen movimientos esperados | No evaluado |
| Integridad POS: caja | Manipulación financiera | cierres o reaperturas no autorizadas | política de permisos y audit log | empleado no reabre caja; acción admin auditada | No evaluado |
| Integridad QR | Sustitución de destino de pago | QR falso | edición restringida, fallback/versión y auditoría | empleado no cambia; fallo al guardar mantiene QR previo | No evaluado |
| PDF/documentos | Fuga o archivo malformado | datos expuestos o errores de parsing | validación/tamaño/ubicación/retención | archivo grande/malformado se rechaza sin crashear | No evaluado |
| Secret scanning | secreto committed | credenciales históricas expuestas | reporte Gitleaks u otra herramienta y proceso de rotación | secret canary de prueba detectado, sin valores reales | No evaluado |
| Incident response | retraso en contención | compromiso prolongado | runbook, canales, responsables y ejercicios | simulacro de token comprometido | No evaluado |

## Registro de evaluación por control

Para cada fila con estado distinto de `No evaluado`, registrar en un sistema de gestión o sección adicional:

- fecha y commit;
- ruta/URL de evidencia;
- herramienta y versión;
- resultado;
- revisor;
- limitaciones;
- riesgo residual;
- excepción y caducidad, si aplica.

## Criterio de cierre del baseline

El baseline solo se considera evaluado cuando los controles aplicables se hayan revisado contra el código real, la configuración de plataforma, el backend/infrastructure relevante y los procesos operacionales. Una lista sin evidencia no es evaluación de seguridad.

## Evidencia del proyecto y estados finales (FS-8, 18/10/2026)

Mapeo inicial entre los controles de esta matriz y la evidencia disponible tras el cierre de la auditoría técnica (`C-01`…`C-31`; `H-01`…`H-13`; fases `F0`–`F15`; suite 75/75; `flutter analyze` 0 issues). La columna de estado se actualizó en `FS-8` (18/10/2026) con el resultado final de la evaluación; ratificaciones, excepciones y pendientes en [`docs/SECURITY_CLOSURE_REGISTER.md`](SECURITY_CLOSURE_REGISTER.md).

**Cómo leer esta tabla:** la columna de estado refleja la **consolidación final** de `FS-8` (18/10/2026), acordada con el propietario; hasta `FS-7` fue una propuesta de partida. `Implementado` exige prueba mínima ejecutada y evidencia registrada (fecha/commit, herramienta, resultado, limitaciones y riesgo residual) en [`docs/SECURITY_CLOSURE_REGISTER.md`](SECURITY_CLOSURE_REGISTER.md); `Parcial` mantiene pendientes operativos (P-01…P-05); `No aplicable` está **ratificado** por el propietario (R-01…R-04); `No evaluado` queda para los controles organizacionales fuera del alcance del repositorio; las excepciones aceptadas (E-01…E-06) tienen dueño, compensación y caducidad. Esta tabla no sustituye el registro. La secuencia de ejecución por fases está en `docs/SECURITY_ACTION_PLAN.md`.

| Control(es) | Evidencia existente en el proyecto | Estado final (FS-8) | Limitaciones, excepciones y pendientes |
|---|---|---|---|
| ISO 5.15 / 5.16 / 5.17 / 5.18 | Login exclusivo por `username` con `activo = 1 AND bloqueado = 0` (RN-10); ciclo bloquear/desactivar auditado sin auto-baja (RN-11); guardas de sesión en rutas protegidas (F9; `test/router_guards_test.dart`); PBKDF2 con upgrade legacy (C-06); pruebas FS-6: mensaje genérico, bloqueo 30 s, logout con limpieza de carrito, inactivos/bloqueados rechazados, empleado restringido, ciclo auditado, última admin y recuperación (`test/acceso_cuentas_sesion_seguridad_test.dart`, SEC-001…010) | Implementado (FS-8, 18/10/2026) | E-01, E-04 y E-05 (excepciones aceptadas; ver `docs/SECURITY_CLOSURE_REGISTER.md`) |
| ISO 8.2 / 8.3 / 8.5 · MASVS-AUTH | Sin backend: autorización aplicada en dominio y navegación; el rol no se acepta desde la UI; pruebas FS-6: autoescalada de rol rechazada, `authorizeAdminOperation` revalida la BD, edición de otro usuario por ID denegada sin cambios (`test/acceso_cuentas_sesion_seguridad_test.dart`, SEC-006…008) | Implementado (FS-8, 18/10/2026) | Excepción E-04 (límite local-only aceptado y documentado) |
| ISO 5.34 · MASVS-PRIVACY | Sin SDK de analytics/telemetría conocidos; sin permiso de red; datos permanecen en el dispositivo; SEC-033 evaluado en dispositivo (`FS-7`): sin `CAMERA`/`INTERNET`, `READ_MEDIA_*` no concedidos y galería/respaldo operativos sin permisos de medios | Parcial (FS-8, 18/10/2026) | Inventario/retensión formal fuera del alcance del repositorio; E-06 (`READ_MEDIA_*` aceptado como residual documentado) |
| ISO 8.24 · MASVS-CRYPTO | SQLCipher AES-256 con clave en almacenamiento seguro; PBKDF2-HMAC-SHA256 310k; `.kpzbackup` (AES-256-GCM + PBKDF2, en `Isolate.run`); sin claves embebidas conocidas; persistencia local sin credenciales en claro (FS-5); SEC-012 verificado en dispositivo (`FS-7`): APK release sin secretos de servidor embebidos | Parcial (FS-8, 18/10/2026) | Pendientes P-03 (gestión/rotación de la clave de BD) y P-01 (firma de producción) |
| ISO 8.8 / 8.9 · MASVS-CODE | `flutter analyze` 0 issues; 9 paquetes sin uso retirados; dependencia EOL retirada (`sqlcipher_flutter_libs`); CI en `.github/workflows/ci.yml` con secret scanning (Gitleaks v3) y advisories (OSV-Scanner v2.7.0) implementados el 18/10/2026 (SEC-037, commit `a176041`); inventario de 121 paquetes hosted y 0 advisories OSV (FS-5); `DEF-FS7-01` corregido en `FS-7A` con regresión `test/respaldo_dialogo_seguridad_test.dart` (5 pruebas); SEC-035 verificado en `FS-7` (release v2 firmado con keystore de prueba, sin `debuggable`) | Implementado (FS-8, 18/10/2026) | Pendiente P-01 (firma de producción); P-02 ejecutado el 19/10/2026 (canario verificado, job `118319199755`) |
| ISO 8.12 / 8.15 / 8.16 | Operaciones críticas auditadas (`AuditLogWriter`); barrido de los 6 `debugPrint` y regex de secretos → 0 coincidencias (FS-5) | Implementado (FS-8, 18/10/2026) | — |
| ISO 8.20 / 8.21 / 8.22 · MASVS-NETWORK | Manifiesto sin permiso `INTERNET`; fuentes empaquetadas offline; sin backend ni endpoints; SEC-015 verificado en release (`FS-7`): operación completa 100 % offline con modo avión (arranque, restauración y login) | Implementado (FS-8, 18/10/2026) | Ratificación R-01 (SEC-016 sin tránsito): sin red por diseño; reapertura si se incorpora red |
| ISO 8.26 / 8.27 / 8.28 | Validación de dominio reforzada en la auditoría (invariantes RN-01…RN-12; consultas parametrizadas en repositorios) | Implementado (FS-8, 18/10/2026) | — |
| ISO 8.29 | Suite 75/75: equivalencia de esquema (`test/schema_equivalence_test.dart`), guardas de ruta, accesibilidad, resiliencia de boleta, cuadre de caja, faltantes | Implementado (FS-8, 18/10/2026) | — |
| ISO 8.31 / 8.32 | Trabajo por fases con commit por unidad; CI existente; bitácora de cambios (`agent.md`) | Parcial (FS-8, 18/10/2026) | Pendiente P-04 (política de PR y protección de rama; decisión del propietario) |
| ISO 8.33 / 8.34 | Pruebas con datos sintéticos y base de pruebas `sqflite_common_ffi` | Parcial (FS-8, 18/10/2026) | Pendiente P-05 (verificación formal de ausencia de datos reales en pruebas y artefactos) |
| MASVS-STORAGE | SQLCipher; auto-backup Android desactivado + reglas de extracción; `.kpzbackup` con passphrase; inspección estática sin credenciales en claro (sin `SharedPreferences` ni `writeAsString`; claves en secure storage; PDFs/QR en documentos y reportes en temporales) (FS-5); SEC-014 verificado en dispositivo (`FS-7`): exportación/restauración por SAF, sin marcadores en claro y restauración cruzada tras reinstalar el release | Implementado (FS-8, 18/10/2026) | — |
| MASVS-PLATFORM | Manifiesto sin `INTERNET` (solo debug/profile); `applicationId`/namespace `com.kimipizza.pos`; política de backup segura; revisión del manifiesto fuente y fusionado: `MainActivity` exportada solo por el launcher, providers `exported=false`, receiver del sistema con `DUMP`, sin deep links/schemes (FS-5); SEC-033 evaluado en `FS-7` (permisos efectivos en dispositivo) | Implementado (FS-8, 18/10/2026) | Excepción E-06 (`READ_MEDIA_*` aceptado como residual documentado) |
| MASVS-RESILIENCE | Firma release con gate (`key.properties` obligatorio; nunca clave debug) (H-09/F10); SEC-035 verificado en `FS-7`: esquema v2 con certificado de prueba `CN=Kimi Pizza FS7 Test`, distinto de `CN=Android Debug`; sin `debuggable` y `run-as` rechazado | Parcial (FS-8, 18/10/2026) | Pendiente P-01 (firma de producción); sin ofuscación por decisión de alcance (límite declarado S2) |
| Integridad POS: venta | H-07: un fallo de PDF no duplica la venta (`test/pos_boleta_resiliencia_test.dart`, re-ejecutado 3/3 en FS-2); anulación/edición de ventas con pruebas (`test/anular_editar_ventas_test.dart`); importes negativos/no finitos, doble cobro y reintento tras fallo (`test/integridad_cobro_seguridad_test.dart`, T1a–T5) | Implementado (FS-8, 18/10/2026) | Validación en dispositivo de los flujos de UI no exigida por el propietario |
| Integridad POS: inventario | Escritor único de movimientos (`StockMovementWriter`); invariantes de sobrantes/traslados con `UPDATE` condicional (RN-03; `test/gestion_sobrantes_mermas_test.dart`); caracterización de compras/CxP (`test/characterization_phase1_test.dart`); faltantes v25 (`test/faltantes_preparacion_test.dart`); doble submit de compra (`test/compra_doble_submit_seguridad_test.dart`); concurrencia venta/merma/transformación (`test/integridad_inventario_seguridad_test.dart`); entradas inválidas de compra (`test/entradas_invalidas_seguridad_test.dart`); inyección SQL acotada (`test/inyeccion_sql_seguridad_test.dart`) | Implementado (FS-8, 18/10/2026) | — |
| Integridad POS: caja | Cuadre centralizado (`CashCloseSummary`, RN-04; `test/caja_arqueo_repo_test.dart`); gastos/movimientos vinculados por ID (H-05; `test/gastos_movimiento_caja_test.dart`); caja por sesión operativa (RN-06); reapertura autorizada auditada y cierre único (`test/caja_ciclo_operativo_seguridad_test.dart`, SEC-029/030/031) | Implementado (FS-8, 18/10/2026) | — |
| Integridad QR | Configuración con rol y fuente única: el QR (`Configuracion.qr_ventas_ruta`) se administra solo por admin (menú del dashboard bloqueado, pantalla "Acceso Restringido" y guardado denegado a no admin) y se persiste en una única escritura transaccional; el cobro lee la ruta al abrir el sheet y representa el estado ausente; pruebas T1–T6 (`test/qr_administrativo_seguridad_test.dart`): empleado no cambia el QR, fallo de persistencia con rollback conserva el previo y avisa, y la ruta configurada es la única fuente de verdad | Implementado (FS-8, 18/10/2026) | Validación con cámara/galería real ejecutada en `FS-7` |
| PDF/documentos | Boleta persistida y ligada a la venta (H-07); logo corrupto o inexistente → boleta sin logo, error seguro (`test/imagen_pdf_seguridad_test.dart`); imágenes capturadas/seleccionadas con límite de dimensiones (1600 px) y tamaño (5 MB) (`test/imagenes_limite_seguridad_test.dart`) | Implementado (FS-8, 18/10/2026) | — |
| Secret scanning | Barrido de patrones en árbol e historia (42 commits) sin secretos reales; `key.properties` ausente e ignorado; `storePassword` solo en `.example` con placeholders; job de CI `secret-scan` con Gitleaks v3 implementado (SEC-037, commit `a176041`) | Implementado (FS-8, 18/10/2026) | P-02 ejecutado el 19/10/2026 (canario con secreto falso: `secret-scan` falló redactado; PR #2 cerrado sin fusionar) |
| ISO 5.8 / 8.25 | Plan de auditoría por fases, Definition of Done y revisión documental de cambios (F15) | Implementado (FS-8, 18/10/2026) | Límites y amenazas declarados por fase (S2); sostener la práctica por cambio sensible |
| ISO 5.9 / 5.12 | — | No evaluado (fuera del alcance del repositorio) | Inventario y clasificación formal de activos/datos: decisión organizacional del propietario |
| ISO 4–10 · Incident response | — | No evaluado (fuera del alcance del repositorio) | Decisión organizacional del responsable |
| ISO 8.30 | — | No aplicable (ratificado en FS-8, R-04) | Sin desarrollo externalizado; reabrir si se contrata desarrollo o servicios externos |

**Cierre (FS-8, 18/10/2026):** los 40 casos `SEC-*` quedaron con disposición final (`docs/SECURITY_TEST_PLAN.md` §3.3) y el registro de evaluación por control con fecha/commit, evidencia, herramienta, resultado y limitaciones está en `docs/SECURITY_CLOSURE_REGISTER.md`.

**Fuera de esta tabla:** las filas no listadas de la matriz permanecen `No evaluado`. La declaración de `No aplicable` o `Excepción aceptada` siempre requiere justificación formal aprobada por el responsable, según las reglas de esta matriz.
