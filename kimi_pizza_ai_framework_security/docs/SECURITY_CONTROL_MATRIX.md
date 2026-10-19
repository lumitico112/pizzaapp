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

## Evidencia inicial del proyecto (18/10/2026)

Mapeo inicial entre los controles de esta matriz y la evidencia disponible tras el cierre de la auditoría técnica (`C-01`…`C-31`; `H-01`…`H-13`; fases `F0`–`F15`; suite 75/75; `flutter analyze` 0 issues).

**Cómo leer esta tabla:** el estado es una **propuesta de partida**, no un registro de evaluación. Ninguna fila se marca `Implementado`: para ello hay que re-ejecutar la prueba mínima del control sobre el artefacto correspondiente y registrar fecha/commit, evidencia, herramienta, resultado y revisor (sección "Registro de evaluación por control"). Esta tabla no sustituye ese registro. La secuencia de ejecución por fases está en `docs/SECURITY_ACTION_PLAN.md`; el registro de evaluación por control se completará conforme cada caso se cierre.

| Control(es) | Evidencia existente en el proyecto | Estado propuesto | Pendiente para cerrar |
|---|---|---|---|
| ISO 5.15 / 5.16 / 5.17 / 5.18 | Login exclusivo por `username` con `activo = 1 AND bloqueado = 0` (RN-10); ciclo bloquear/desactivar auditado sin auto-baja (RN-11); guardas de sesión en rutas protegidas (F9; `test/router_guards_test.dart`); PBKDF2 con upgrade legacy (C-06) | Parcial | Casos SEC-005/006/009/010 sobre build release; prueba empleado → acción admin; revisor |
| ISO 8.2 / 8.3 / 8.5 · MASVS-AUTH | Sin backend: autorización aplicada en dominio y navegación; el rol no se acepta desde la UI | Parcial | SEC-007/008 (manipulación de rol/ID); documentar el límite de la defensa local-only (S2) |
| ISO 5.34 · MASVS-PRIVACY | Sin SDK de analytics/telemetría conocidos; sin permiso de red; datos permanecen en el dispositivo | No evaluado | Inventario de datos y retención; SEC-033 (permisos cámara/galería) |
| ISO 8.24 · MASVS-CRYPTO | SQLCipher AES-256 con clave en almacenamiento seguro; PBKDF2-HMAC-SHA256 310k; `.kpzbackup` (AES-256-GCM + PBKDF2, en `Isolate.run`); sin claves embebidas conocidas | Parcial | Verificación funcional en dispositivo (`F11(e)`); gestión/rotación de la clave de BD; SEC-012/013 |
| ISO 8.8 / 8.9 · MASVS-CODE | `flutter analyze` 0 issues; 9 paquetes sin uso retirados; dependencia EOL retirada (`sqlcipher_flutter_libs`); CI en `.github/workflows/ci.yml` | Parcial | SEC-036 (SCA/advisories); SEC-035 (revisión de artefacto release) |
| ISO 8.12 / 8.15 / 8.16 | Operaciones críticas auditadas (`AuditLogWriter`); sin secretos conocidos en logs | Parcial | SEC-032 (búsqueda automatizada de secretos en logs) |
| ISO 8.20 / 8.21 / 8.22 · MASVS-NETWORK | Manifiesto sin permiso `INTERNET`; fuentes empaquetadas offline; sin backend ni endpoints | Parcial | SEC-015/016 en release; declarar formalmente no aplicabilidad TLS mientras no exista red |
| ISO 8.26 / 8.27 / 8.28 | Validación de dominio reforzada en la auditoría (invariantes RN-01…RN-12; consultas parametrizadas en repositorios) | Parcial | SEC-018/019/020 (entradas malformadas/negativas/inyección) |
| ISO 8.29 | Suite 75/75: equivalencia de esquema (`test/schema_equivalence_test.dart`), guardas de ruta, accesibilidad, resiliencia de boleta, cuadre de caja, faltantes | Parcial | Ejecutar los casos SEC aplicables como pruebas de seguridad formales |
| ISO 8.31 / 8.32 | Trabajo por fases con commit por unidad; CI existente; bitácora de cambios (`agent.md`) | Parcial | Política formal de revisión (PR) y protección de ramas |
| ISO 8.33 / 8.34 | Pruebas con datos sintéticos y base de pruebas `sqflite_common_ffi` | Parcial | Verificar ausencia de datos reales en pruebas y artefactos |
| MASVS-STORAGE | SQLCipher; auto-backup Android desactivado + reglas de extracción; `.kpzbackup` con passphrase | Parcial | SEC-013/014 (inspección y restore en dispositivo) |
| MASVS-PLATFORM | Manifiesto sin `INTERNET`; `applicationId`/namespace `com.kimipizza.pos`; política de backup segura | Parcial | SEC-034 (revisión completa de components/`exported`/permisos); SEC-039 (deep links) |
| MASVS-RESILIENCE | Firma release con gate (`key.properties` obligatorio; nunca clave debug) (H-09/F10) | Parcial | SEC-035 (artefacto firmado); definir apetito de ofuscación sin prometer inmunidad |
| Integridad POS: venta | H-07: un fallo de PDF no duplica la venta (`test/pos_boleta_resiliencia_test.dart`); anulación/edición de ventas con pruebas (`test/anular_editar_ventas_test.dart`) | Parcial | SEC-025 (doble toque/reintento); re-ejecutar SEC-026 |
| Integridad POS: inventario | Escritor único de movimientos (`StockMovementWriter`); invariantes de sobrantes/traslados con `UPDATE` condicional (RN-03; `test/gestion_sobrantes_mermas_test.dart`); caracterización de compras/CxP (`test/characterization_phase1_test.dart`); faltantes v25 (`test/faltantes_preparacion_test.dart`) | Parcial | SEC-027/028 (timeout/replay/concurrencia) |
| Integridad POS: caja | Cuadre centralizado (`CashCloseSummary`, RN-04; `test/caja_arqueo_repo_test.dart`); gastos/movimientos vinculados por ID (H-05; `test/gastos_movimiento_caja_test.dart`); caja por sesión operativa (RN-06) | Parcial | SEC-029/030/031 (reapertura/cierre duplicado) |
| Integridad QR | Verificación pendiente en esta edición | No evaluado | SEC-022/023/024 (edición restringida por rol, fallo de guardado, fuente de verdad) |
| PDF/documentos | Boleta persistida y ligada a la venta (H-07) | Parcial | SEC-021 (archivo grande/malformado) |
| Secret scanning | Repositorio sin secretos versionados conocidos (`key.properties` fuera de git; se versiona `.example`) | No evaluado | Ejecutar herramienta (SEC-011) y canario en CI (SEC-037) |
| ISO 5.8 / 8.25 | Plan de auditoría por fases, Definition of Done y revisión documental de cambios (F15) | Parcial | Revisión de amenaza formal por cambio sensible |
| ISO 5.9 / 5.12 | — | No evaluado | Inventario y clasificación formal de activos/datos |
| ISO 4–10 · Incident response | — | No evaluado | Decisión organizacional del responsable; fuera del alcance del repositorio |
| ISO 8.30 | — | No aplicable (provisional) | Sin desarrollo externalizado actualmente; requiere ratificación formal del responsable |

**Fuera de esta tabla:** las filas no listadas de la matriz permanecen `No evaluado`. La declaración de `No aplicable` o `Excepción aceptada` siempre requiere justificación formal aprobada por el responsable, según las reglas de esta matriz.
