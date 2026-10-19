# KIMI PIZZA — Plan de pruebas de seguridad

## 1. Reglas

- Ejecutar solo contra entornos, cuentas y dispositivos autorizados.
- Usar datos sintéticos y cuentas de prueba con permisos controlados.
- No modificar la producción ni realizar pruebas destructivas sin autorización escrita, respaldo y ventana aprobada.
- Cada prueba debe tener precondiciones, pasos, resultado esperado, resultado real, evidencia redactada, versión y estado.
- Las pruebas del cliente móvil no reemplazan pruebas del backend, infraestructura ni revisión organizacional.

## 2. Severidad y prioridad

Bloquea una release si existe vulnerabilidad crítica/alta explotable relacionada con autenticación, autorización, secretos, datos sensibles, integridad de ventas/pagos/caja o exposición remota, salvo aceptación documentada del riesgo por responsable autorizado y controles compensatorios verificables.

## 3. Casos base

| ID | Área | Prueba | Resultado esperado |
|---|---|---|---|
| SEC-001 | Login | credenciales inválidas | acceso denegado sin revelar información sensible |
| SEC-002 | Login | repetición rápida de intentos | mitigación proporcional aplicada, evento registrado cuando corresponda |
| SEC-003 | Sesión | token ausente/expirado/malformado | petición protegida denegada; no hay fallback inseguro |
| SEC-004 | Sesión | logout | datos de sesión eliminados y sesión remota revocada cuando sea posible |
| SEC-005 | Sesión | cuenta desactivada o rol revocado | operación posterior denegada |
| SEC-006 | Autorización | empleado abre URL/ruta/pantalla admin | UI bloquea y la capa de autoridad rechaza operación |
| SEC-007 | Autorización | alterar `role`/`isAdmin` en request/local data | no escala privilegios |
| SEC-008 | Autorización | sustituir ID de otro usuario/recurso | acceso denegado; protección contra IDOR/BOLA |
| SEC-009 | Admin | cambiar/crear/eliminar usuario sin permiso | rechazo sin cambios parciales |
| SEC-010 | Admin | eliminar/degradar última cuenta admin | bloqueo o proceso de recuperación controlado |
| SEC-011 | Secretos | escanear repo, historia y assets | sin claves/contraseñas/tokens reales; hallazgo requiere rotación |
| SEC-012 | Secretos | inspeccionar APK/IPA/config de release | no hay secreto servidor embebido |
| SEC-013 | Storage | inspeccionar preferencias y archivos temporales | tokens/contraseñas no quedan en texto plano |
| SEC-014 | Storage | revisar backup/restore | datos incluidos/excluidos según política y restauración verificada |
| SEC-015 | Network | endpoint HTTP en release | bloqueado/no configurado |
| SEC-016 | Network | certificado/hostname inválido | conexión rechazada; nunca se acepta cualquier certificado |
| SEC-017 | Network | timeout o red caída durante compra/venta | no se registra duplicidad ni estado ambiguo sin mecanismo de recuperación |
| SEC-018 | API | JSON malformado, campos extra/tipos erróneos | rechazo explícito, sin crashear ni alterar estado |
| SEC-019 | API | payload con importes negativos/extremos | rechazado por regla de dominio/servidor |
| SEC-020 | SQL/Storage | entradas con caracteres de inyección | consultas parametrizadas; no altera query/estructura |
| SEC-021 | Upload | imagen/PDF demasiado grande/corrupto | rechazado con error seguro y límites de recursos |
| SEC-022 | QR | empleado intenta reemplazar QR | denegado |
| SEC-023 | QR | imagen nueva falla al persistir | QR anterior continúa disponible y el usuario recibe error |
| SEC-024 | QR | QR guardado se muestra en cobro | se usa la fuente de verdad verificada, sin archivo temporal obsoleto |
| SEC-025 | Ventas | doble click o reintento de cobrar | una sola venta/pago/consumo de stock |
| SEC-026 | PDF | falla la generación tras venta confirmada | venta no se duplica; se puede reintentar generación de PDF por separado |
| SEC-027 | Inventario | compra se reenvía por timeout | un movimiento o protocolo de idempotencia evita duplicación |
| SEC-028 | Inventario | venta/merma/transformación concurrente | no hay doble descuento ni stock inconsistente según regla de concurrencia |
| SEC-029 | Caja | empleado intenta reapertura excepcional | denegada y sin cambios |
| SEC-030 | Caja | cierre enviado dos veces | un solo cierre/ciclo de caja |
| SEC-031 | Caja | reapertura autorizada | queda fecha/hora, actor, motivo y referencia al ciclo anterior |
| SEC-032 | Logs | producir errores de autenticación/transacción | no se registran contraseñas, tokens, encabezados de autorización ni datos innecesarios |
| SEC-033 | Privacy | revisar permisos de cámara/galería/otros | permisos mínimos y solicitud contextual |
| SEC-034 | Platform | inspeccionar `AndroidManifest.xml` y `Info.plist` | componentes/entitlements/permisos mínimos, configuración de release correcta |
| SEC-035 | Release | ejecutar revisión de artefacto firmado | firma de release esperada, no debug, endpoints correctos |
| SEC-036 | Dependencies | escanear árbol de dependencias | avisos relevantes identificados, priorizados y con plan de actualización |
| SEC-037 | CI | pull request con secreto canario | pipeline detecta el secreto y falla según política |
| SEC-038 | Exportaciones | exportar reportes/PDF a dispositivo/compartir | acción explícita, acceso/ubicación adecuados y sin filtración accidental |
| SEC-039 | Deep links | deep link con ID o parámetros manipulados | validación y autorización antes de navegar/mostrar recurso |
| SEC-040 | Offline/sync | replay de operación offline | idempotencia y reglas de conflicto previenen duplicidad |

## 3.1 Cobertura inicial del proyecto (18/10/2026)

Estado de partida tras el cierre de la auditoría técnica (`C-01`…`C-31`; `H-01`…`H-13`; fases `F0`–`F15`; suite 75/75; `flutter analyze` 0 issues). **Ninguna fila equivale a la ejecución formal del caso:** son referencias de evidencia existente que debe re-ejecutarse y registrarse según la sección 4.

| Caso | Estado inicial | Referencia |
|---|---|---|
| SEC-001 | Cubierto por pruebas (FS-6) | `test/acceso_cuentas_sesion_seguridad_test.dart` (SEC-001): campos vacíos, contraseña incorrecta y usuario inexistente → mensaje genérico `Credenciales incorrectas o usuario inactivo.` sin abrir sesión |
| SEC-002 | Cubierto por pruebas (FS-6; residual) | `test/acceso_cuentas_sesion_seguridad_test.dart` (SEC-002): 4 fallos genéricos y 5.º → bloqueo de 30 s; durante el bloqueo se rechaza la contraseña correcta y al expirar se resetea. Residual: contador en memoria, sin persistencia ni auditoría de intentos; una instancia nueva pierde el bloqueo (`docs/SECURITY_ACCESS_EVIDENCE.md` §5.1) |
| SEC-003 | Cubierto por pruebas (FS-6; adaptado) | `test/acceso_cuentas_sesion_seguridad_test.dart` (SEC-003): sin tokens remotos; la sesión vive en memoria y una instancia nueva no la hereda; tras logout `haySesion = false` |
| SEC-004 | Cubierto por pruebas (FS-6; adaptado) | `test/acceso_cuentas_sesion_seguridad_test.dart` (SEC-004): `logout()` limpia `currentUser`, invoca `onLogout` (vacía el carrito) y deja `haySesion = false`; no hay sesión remota que revocar |
| SEC-005 | Cubierto por pruebas (FS-6) | `test/acceso_cuentas_sesion_seguridad_test.dart` (SEC-005): `activo = 0` o `bloqueado = 1` no acceden por login ni por `loginRapido`; el activo sí. Observación: una sesión ya abierta no se revalida por operación (`docs/SECURITY_ACCESS_EVIDENCE.md` §5.2); ratificar en release (`FS-7`) si se exige |
| SEC-006 | Cubierto por pruebas (FS-6) | `test/acceso_cuentas_sesion_seguridad_test.dart` (SEC-006): empleado en la pantalla de usuarios ve `Acceso Restringido`; el servicio rechaza crear/bloquear. La guarda de ruta es solo de sesión (F9); el rol se aplica en menú, pantalla y servicios (`docs/SECURITY_ACCESS_EVIDENCE.md` §5.3) |
| SEC-007 | Cubierto por pruebas (FS-6; residual local-only) | `test/acceso_cuentas_sesion_seguridad_test.dart` (SEC-007): autoescalada de rol rechazada (sigue `empleado`); con `currentUser` manipulado, `authorizeAdminOperation` revalida la BD y rechaza. Límite local-only en `docs/SECURITY_ACCESS_EVIDENCE.md` §5.4 |
| SEC-008 | Cubierto por pruebas (FS-6; residual local-only) | `test/acceso_cuentas_sesion_seguridad_test.dart` (SEC-008): edición de otro usuario por ID denegada sin cambios; ID inexistente no inserta. Lecturas sin autorización por objeto y límite local-only (`docs/SECURITY_ACCESS_EVIDENCE.md` §5.4) |
| SEC-009 | Cubierto por pruebas (FS-6) | `test/acceso_cuentas_sesion_seguridad_test.dart` (SEC-009): empleado no crea ni bloquea (sin filas ni auditoría); admin crea/edita y el ciclo bloquear/desbloquear/baja/reactivar deja 4 eventos con actor; un fallo de auditoría revierte la baja |
| SEC-010 | Cubierto por pruebas (FS-6; observación) | `test/acceso_cuentas_sesion_seguridad_test.dart` (SEC-010): auto-bloqueo y auto-baja denegados; queda 1 admin activo; código de rescate hash, incorrecto rechazado y reset efectivo. Observación: autodemoción no bloqueada en el servicio y alta/edición sin auditoría (`docs/SECURITY_ACCESS_EVIDENCE.md` §5.5) |
| SEC-011 / SEC-012 | SEC-011 cubierto por inspección estática (FS-5); SEC-012 cubierto en dispositivo (FS-7) | Barrido de patrones en árbol e historia (42 commits) sin secretos reales; `key.properties` ausente e ignorado; job de CI de secret scanning implementado (SEC-037, commit `a176041`); canario verificado el 19/10/2026 (PR #2, job `118319199755`, salida redactada). APK release inspeccionado (`docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §3): `com.kimipizza.pos` v2.0.0 (code 20), sin `INTERNET`/`CAMERA`, `allowBackup=false`, sin `debuggable`, `run-as` rechazado |
| SEC-013 | Cubierto por inspección estática (FS-5) | Sin credenciales en claro: claves de BD/backup en secure storage, sin `SharedPreferences` ni `writeAsString`; runtime/restore en `FS-7` (SEC-014) |
| SEC-014 | Cubierto en dispositivo (FS-7) | Auto-backup Android desactivado; `.kpzbackup` con passphrase (RN-08); exportación por SAF (20 593 bytes; `KPZB` v1 + envoltura `formatVersion`/`salt`/`nonce` + ciphertext; 0 marcadores en claro), ruta negativa ("La contraseña no es correcta.", datos intactos), ruta positiva (reemplazo verificado) y restauración cruzada tras reinstalar el release sin red (`docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §4); `DEF-FS7-01` corregido en `FS-7A` y re-verificado |
| SEC-015 / SEC-016 | SEC-015 cubierto en dispositivo (FS-7); SEC-016 no aplicable hoy (ratificado en FS-8: R-01) | Manifiesto release sin `INTERNET` (C-21) y sin endpoints; release operando 100 % offline con modo avión (arranque, restauración y login); TLS sin tránsito que evaluar (`docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §5) |
| SEC-017 / SEC-040 | No aplicable (hoy) | Sin backend ni sincronización: no hay tránsito de red ni replay remoto; revisar si se introduce sync |
| SEC-022 / SEC-023 / SEC-024 | Cubierto por pruebas (FS-4) | `test/qr_administrativo_seguridad_test.dart` (T1–T6): el empleado no administra el QR ("Acceso Restringido" y guardado denegado, configuración intacta); un fallo al persistir revierte la transacción, conserva los valores y el QR previos y avisa al usuario; el QR configurado es la única fuente de verdad (reemplazo explícito sin residuo obsoleto y estado "no configurado" al quitarlo) |
| SEC-025 | Pendiente | Doble toque/reintento de cobro sin prueba dedicada; relacionado con la corrección H-07 |
| SEC-026 | Cubierto por automatización | `test/pos_boleta_resiliencia_test.dart` (T1–T3): un fallo de PDF no duplica la venta (H-07 / F4) |
| SEC-027 / SEC-028 | Parcial | Escritor único de stock + invariantes sobrantes/traslados (`test/gestion_sobrantes_mermas_test.dart`); replay/concurrencia fina pendientes |
| SEC-029 / SEC-030 / SEC-031 | Cubierto por pruebas (FS-3) | `test/caja_ciclo_operativo_seguridad_test.dart` (T1–T8): reapertura no autorizada denegada sin cambios ni auditoría; doble cierre (secuencial y concurrente) con un solo cierre y una sola auditoría; reapertura autorizada auditada con actor, motivo, fecha/hora y ciclo previo |
| SEC-032 | Cubierto por inspección estática (FS-5) | 6 `debugPrint` de error/traza revisados; regex de secretos → 0 coincidencias; `AuditLogWriter` para operaciones críticas |
| SEC-033 | Cubierto en dispositivo (FS-7; residual) | Release: `USE_BIOMETRIC`/`USE_FINGERPRINT` concedidos; `READ_MEDIA_*` (de `open_filex`) declarados y `granted=false`; sin `CAMERA`/`INTERNET`; galería y respaldo funcionan sin permisos de medios (`docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §6). Residual: decidir el acotamiento de `READ_MEDIA_VIDEO`/`READ_MEDIA_AUDIO` |
| SEC-034 | Cubierto por inspección estática (FS-5) | Manifiesto fuente y fusionado revisados (components/`exported`/permisos) y reglas de backup; SEC-033 en `FS-7`; evaluar `READ_MEDIA_*` de `open_filex` |
| SEC-035 | Cubierto en dispositivo (FS-7; residual) | Gate de firma release verificado (F10: falla sin `key.properties`; debug intacto); ruta positiva con keystore de prueba: v2 firmado, `CN=Kimi Pizza FS7 Test` ≠ `CN=Android Debug`, sin `debuggable`, `run-as` rechazado (`docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §7). Residual: firma de producción a cargo del propietario |
| SEC-036 | Cubierto por inspección estática (FS-5) | 121 paquetes hosted inventariados; OSV `querybatch`: 0 advisories (18/10/2026); re-ejecutar en CI/Dependabot |
| SEC-037 | Implementado (FS-5 reanudada, 18/10/2026) | Gitleaks v3 + OSV-Scanner reusable v2.7.0 en `.github/workflows/ci.yml` (commit `a176041`; `permissions: contents: read`); YAML validado localmente; canario de aceptación verificado el 19/10/2026 (PR #2, fallo redactado; `SECURITY_STATIC_EVIDENCE.md` §7.3) |
| SEC-039 | Cubierto por inspección estática (FS-5) | Sin deep links/schemes; único `intent-filter` MAIN/LAUNCHER; providers `exported=false`; receiver del sistema con `DUMP` |

Las filas no listadas permanecen **sin cubrir** hasta su ejecución. La secuencia de ejecución por fases y el triaje formal de los 40 casos se organizan en `docs/SECURITY_ACTION_PLAN.md` (fases `FS-0`–`FS-9`; prompts por fase en `docs/SECURITY_PHASE_PROMPTS.md`). Cada caso que se cierre debe registrar fecha/commit/evidencia/herramienta/revisor según la sección 4.

## 3.2 Triaje de ejecución (18/10/2026)

Publica el triaje formal de los 40 casos de la sección 3 (fase `FS-1`), revisado caso por caso contra la evidencia real del proyecto y la §3.1; no es una copia del borrador Anexo A de `docs/SECURITY_ACTION_PLAN.md`. Fija **dónde y cómo** se ejecutará cada caso: no es un resultado; ningún caso queda evaluado con esta tabla y los estados de `docs/SECURITY_CONTROL_MATRIX.md` no cambian. Las discrepancias detectadas respecto a §3.1 quedan anotadas en la fila correspondiente (p. ej., `SEC-002`).

Disposiciones:
- `Ejecutable en escritorio`: prueba o inspección local, sin dispositivo ni keystore.
- `Requiere dispositivo/keystore`: bloqueado hasta que exista el entorno; se agrupa en `FS-7`.
- `No aplicable hoy`: justificación en la nota; requiere ratificación del propietario en `FS-8` (ejecutada: R-01…R-04).
- `Cubierto por automatización`: existe prueba; debe re-ejecutarse y registrarse como evidencia.

| Caso | Disposición | Fase destino | Nota |
|---|---|---|---|
| SEC-001 | Ejecutable en escritorio | FS-6 | Credenciales inválidas: acceso denegado sin revelar información sensible. |
| SEC-002 | Ejecutable en escritorio | FS-6 | §3.1 no registra la mitigación ya presente en `AuthService.login` (contador/bloqueo en memoria: 5 intentos, 30 s, sin persistencia); evaluar su alcance real en la fase. |
| SEC-003 | Ejecutable en escritorio | FS-6 | Adaptado a sesión local (sin tokens remotos); comprobar que no hay fallback inseguro. |
| SEC-004 | Ejecutable en escritorio | FS-6 | Adaptado: `logout()` limpia el estado en memoria (C-18; carrito vía `onLogout`). |
| SEC-005 | Ejecutable en escritorio | FS-6 | Cuenta inactiva/bloqueada no accede (RN-10/RN-11); §3.1 pedía build release: ratificar en `FS-7` si se exige. |
| SEC-006 | Ejecutable en escritorio | FS-6 | Rol empleado en ruta admin: UI y guardas (`test/router_guards_test.dart`); verificar el alcance por rol (hoy las guardas son de sesión). |
| SEC-007 | Ejecutable en escritorio | FS-6 | Manipulación de rol local: sin escalada; documentar el límite de la defensa local-only (S2). |
| SEC-008 | Ejecutable en escritorio | FS-6 | IDs de otro usuario/recurso: denegar; mismo límite local-only. |
| SEC-009 | Ejecutable en escritorio | FS-6 | Ciclo de alta/baja de usuarios admin con autorización y auditoría, sin cambios parciales. |
| SEC-010 | Ejecutable en escritorio | FS-6 | Última cuenta admin protegida (sin auto-baja, RN-11; recuperación controlada). |
| SEC-011 | Ejecutable en escritorio | FS-5 | Secret scanning de árbol e historia; si no hay herramienta, barrido por patrones con limitación documentada. |
| SEC-012 | Requiere dispositivo/keystore | FS-7 | Inspección del APK de release (requiere artefacto firmado). |
| SEC-013 | Ejecutable en escritorio | FS-5 (+FS-7) | Capa estática (preferencias, temporales, PDFs, fotos) en FS-5; inspección runtime en FS-7. |
| SEC-014 | Requiere dispositivo/keystore | FS-7 | Backup/restore en dispositivo (`F11(e)`); única vía oficial `.kpzbackup` (RN-08). |
| SEC-015 | Requiere dispositivo/keystore | FS-7 | Sin endpoints ni permiso `INTERNET` (C-21); confirmar sobre artefacto release. |
| SEC-016 | Requiere dispositivo/keystore | FS-7 | Sin tránsito de red hoy (sin backend); ratificar sobre release. |
| SEC-017 | No aplicable hoy | FS-8 | Sin backend ni sincronización: no hay tránsito de red; ratificado por el propietario en `FS-8` (R-02). |
| SEC-018 | Ejecutable en escritorio | FS-2 | Entradas malformadas/tipos erróneos: rechazo por dominio sin crash ni estado parcial. |
| SEC-019 | Ejecutable en escritorio | FS-2 | Importes negativos/extremos rechazados por regla de dominio. |
| SEC-020 | Ejecutable en escritorio | FS-2 | Inyección SQL: barrido de consultas parametrizadas + prueba acotada. |
| SEC-021 | Ejecutable en escritorio | FS-2 | PDF/imagen corrupta o sobre-dimensionada: rechazo con error seguro. |
| SEC-022 | Ejecutable en escritorio | FS-4 | QR administrable solo por rol autorizado; la parte con cámara/galería real pasa a procedimiento manual. |
| SEC-023 | Ejecutable en escritorio | FS-4 | Fallo al persistir el QR nuevo conserva el previo. |
| SEC-024 | Ejecutable en escritorio | FS-4 | El cobro usa la fuente de verdad del QR (sin temporales obsoletos). |
| SEC-025 | Ejecutable en escritorio | FS-2 | Doble toque/reintento de "Cobrar": una sola venta, un solo movimiento de stock y un solo registro de caja (primera prueba de la fase). |
| SEC-026 | Cubierto por automatización | FS-2 | `test/pos_boleta_resiliencia_test.dart` (T1–T3): re-ejecutar y registrar la salida como evidencia. |
| SEC-027 | Ejecutable en escritorio | FS-2 | Compra reenviada/timeout: sin duplicar stock ni CxP (cobertura parcial existente). |
| SEC-028 | Ejecutable en escritorio | FS-2 | Concurrencia venta/merma/transformación: sin doble descuento (fuente única `StockMovementWriter`). |
| SEC-029 | Ejecutable en escritorio | FS-3 | Reapertura excepcional sin autorización: denegada y sin cambios. |
| SEC-030 | Ejecutable en escritorio | FS-3 | Cierre enviado dos veces: un solo cierre/ciclo. |
| SEC-031 | Ejecutable en escritorio | FS-3 | Reapertura autorizada: fecha/hora, actor, motivo y referencia al ciclo anterior. |
| SEC-032 | Ejecutable en escritorio | FS-5 | Barrido de logs por patrones sensibles (`password`, `token`, `authorization`) en `lib/`. |
| SEC-033 | Requiere dispositivo/keystore | FS-7 | Permisos de cámara/galería/otros y solicitud contextual en dispositivo real. |
| SEC-034 | Ejecutable en escritorio | FS-5 | Revisión completa del manifest (components, `exported`, permisos, intents) y reglas de backup. |
| SEC-035 | Requiere dispositivo/keystore | FS-7 | Ruta negativa ya verificada (F10); la ruta positiva de release requiere keystore propio. |
| SEC-036 | Ejecutable en escritorio | FS-5 | Inventario de dependencias y advisories con lo disponible; documentar la limitación si no hay red. |
| SEC-037 | Ejecutable en escritorio | FS-5 | Job implementado el 18/10/2026 (commit `a176041`); canario ejecutado el 19/10/2026 con secreto falso (PR #2) y verificado redactado. |
| SEC-038 | Requiere dispositivo/keystore | FS-7 | Exportaciones/compartir: acción explícita y sin filtración accidental en dispositivo. |
| SEC-039 | Ejecutable en escritorio | FS-5 | Deep links/intents: ausencia o validación previa. |
| SEC-040 | No aplicable hoy | FS-8 | Sin sync/replay remoto hoy; ratificado por el propietario en `FS-8` (R-03). |

**Conteo de cierre (40 filas):** 30 `Ejecutable en escritorio`; 1 `Cubierto por automatización` (SEC-026); 7 `Requiere dispositivo/keystore` (SEC-012, SEC-014, SEC-015, SEC-016, SEC-033, SEC-035, SEC-038); 2 `No aplicable hoy` (SEC-017, SEC-040). El triaje no evalúa ni cierra ningún caso.

**Ejecución FS-6 (18/10/2026):** los 10 casos SEC-001…SEC-010 ya tienen prueba permanente y resultado registrado en §3.1; evidencia por caso en `docs/SECURITY_ACCESS_EVIDENCE.md`. Las disposiciones de esta tabla no cambian (historial): la validación de entorno se ejecutó en `FS-7` y las decisiones sobre residuales se cerraron en `FS-8` (ver §3.3).

**Ejecución FS-7 (18/10/2026; reanudada y cerrada):** sobre dispositivo físico Motorola Edge 60 Fusion (Android 16/API 36) se validaron los 7 casos de entorno con evidencia redactada en `docs/SECURITY_ENVIRONMENT_EVIDENCE.md`: SEC-012 (inspección del APK release), SEC-014 (exportación/restauración `.kpzbackup`, incluida la restauración cruzada tras reinstalar el release sin red), SEC-015/016 (release sin `INTERNET`; operación 100 % offline; TLS no aplicable hoy, ratificado en `FS-8` como R-01), SEC-033 (permisos efectivos), SEC-035 (release v2 firmado con keystore de prueba) y SEC-038 (nombre explícito vía SAF y PDF por `content://…/cache-path/...`). La ejecución parcial previa había validado la huella `FS-11`, el QR por galería y los permisos, y halló `DEF-FS7-01` (cancelar el diálogo de contraseña del respaldo rompía la app en debug), corregido en `FS-7A` (regresión `test/respaldo_dialogo_seguridad_test.dart`, 5 pruebas) y re-verificado en debug y release. Observación: la confirmación "Reemplazar datos" precede a la validación de la frase, pero el fallo es seguro y no altera datos.

**Reanudación FS-5 (18/10/2026):** con la aprobación del propietario se implementó el caso SEC-037: `.github/workflows/ci.yml` gana `permissions: contents: read` y los jobs `secret-scan` (Gitleaks v3, historia completa) y `dependency-scan` (OSV-Scanner reusable v2.7.0 sobre `pubspec.lock`, con SARIF a Code scanning); el job `validate` actualizó sus refs a runtimes soportados (Node 24). YAML validado localmente (10/10 comprobaciones). El canario de aceptación (rama/PR con secreto falso) se ejecutó el 19/10/2026 en el PR #2 y se cerró sin fusión (ver §3.3 y `SECURITY_STATIC_EVIDENCE.md` §7.3).

## 3.3 Cierre de cobertura (FS-8, 18/10/2026)

Con las ratificaciones R-01…R-04 y las excepciones E-01…E-06 aprobadas por el propietario (`docs/SECURITY_CLOSURE_REGISTER.md`), los 40 casos quedan con disposición final. Esta sección **sustituye como estado vigente** las disposiciones y notas de §3.1/§3.2, que se conservan como historial. La evidencia se ejecutó sobre datos sintéticos y bases efímeras (`sqflite_common_ffi`); no se usaron datos reales.

| Caso | Estado final | Evidencia |
|---|---|---|
| SEC-001 | Cubierto (FS-6) | `docs/SECURITY_ACCESS_EVIDENCE.md`; `test/acceso_cuentas_sesion_seguridad_test.dart` |
| SEC-002 | Cubierto con excepción E-01 | ídem; residual de bloqueo en memoria aceptado (`SECURITY_CLOSURE_REGISTER.md` §4) |
| SEC-003 | Cubierto (FS-6) | ídem |
| SEC-004 | Cubierto (FS-6) | ídem |
| SEC-005 | Cubierto con excepción E-02 | ídem |
| SEC-006 | Cubierto con excepción E-03 | ídem |
| SEC-007 | Cubierto con excepción E-04 | ídem |
| SEC-008 | Cubierto con excepción E-04 | ídem |
| SEC-009 | Cubierto (FS-6) | ídem |
| SEC-010 | Cubierto con excepción E-05 | ídem |
| SEC-011 | Cubierto (FS-5) | `docs/SECURITY_STATIC_EVIDENCE.md` (árbol e historia sin secretos reales) |
| SEC-012 | Cubierto (FS-7) | `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §3 (APK release inspeccionado) |
| SEC-013 | Cubierto (FS-5 + FS-7) | `docs/SECURITY_STATIC_EVIDENCE.md` §3; runtime de restauración en `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §4 |
| SEC-014 | Cubierto (FS-7) | `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §4 (exportación, ruta negativa, restauración cruzada) |
| SEC-015 | Cubierto (FS-7) | `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §5 (operación 100 % offline) |
| SEC-016 | No aplicable (R-01) | `SECURITY_CLOSURE_REGISTER.md` §2: sin tránsito de red |
| SEC-017 | No aplicable (R-02) | `SECURITY_CLOSURE_REGISTER.md` §2: sin backend |
| SEC-018 | Cubierto (FS-2) | `test/entradas_invalidas_seguridad_test.dart` |
| SEC-019 | Cubierto (FS-2) | `test/entradas_invalidas_seguridad_test.dart`; `test/integridad_cobro_seguridad_test.dart` |
| SEC-020 | Cubierto (FS-2) | `test/inyeccion_sql_seguridad_test.dart` |
| SEC-021 | Cubierto (FS-2/FS-2B) | `test/imagen_pdf_seguridad_test.dart`; `test/imagenes_limite_seguridad_test.dart` |
| SEC-022 | Cubierto (FS-4 + FS-7) | `test/qr_administrativo_seguridad_test.dart`; validación manual con galería/cámara en la entrada parcial de `FS-7` de `agent.md` |
| SEC-023 | Cubierto (FS-4) | `test/qr_administrativo_seguridad_test.dart` |
| SEC-024 | Cubierto (FS-4) | `test/qr_administrativo_seguridad_test.dart` |
| SEC-025 | Cubierto (FS-2) | `test/integridad_cobro_seguridad_test.dart` |
| SEC-026 | Cubierto (FS-2, re-ejecutado 3/3) | `test/pos_boleta_resiliencia_test.dart` |
| SEC-027 | Cubierto (FS-2) | `test/compra_doble_submit_seguridad_test.dart` |
| SEC-028 | Cubierto (FS-2) | `test/integridad_inventario_seguridad_test.dart` |
| SEC-029 | Cubierto (FS-3) | `test/caja_ciclo_operativo_seguridad_test.dart` |
| SEC-030 | Cubierto (FS-3) | `test/caja_ciclo_operativo_seguridad_test.dart` |
| SEC-031 | Cubierto (FS-3) | `test/caja_ciclo_operativo_seguridad_test.dart` |
| SEC-032 | Cubierto (FS-5) | `docs/SECURITY_STATIC_EVIDENCE.md` (barrido de logs sin secretos) |
| SEC-033 | Cubierto con excepción E-06 (FS-7) | `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §6 (permisos efectivos) |
| SEC-034 | Cubierto (FS-5) | `docs/SECURITY_STATIC_EVIDENCE.md` (manifiesto y reglas de backup) |
| SEC-035 | Cubierto (FS-7) con pendiente P-01 | `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §7 (release firmado con keystore de prueba; firma de producción pendiente) |
| SEC-036 | Cubierto (FS-5) | `docs/SECURITY_STATIC_EVIDENCE.md` (121 paquetes, 0 advisories OSV) |
| SEC-037 | Cubierto (FS-5/CI); canario verificado el 19/10/2026 | `.github/workflows/ci.yml`; PR #2 (run `39328148173`, job `118319199755`); `docs/SECURITY_STATIC_EVIDENCE.md` §7.3 |
| SEC-038 | Cubierto (FS-7) | `docs/SECURITY_ENVIRONMENT_EVIDENCE.md` §8 (exportación/SAF y PDF) |
| SEC-039 | Cubierto (FS-5) | `docs/SECURITY_STATIC_EVIDENCE.md` (sin deep links; `exported=false`) |
| SEC-040 | No aplicable (R-03) | `SECURITY_CLOSURE_REGISTER.md` §2: sin sync/replay remoto |

**Conteo final (40 filas):** 37 casos cubiertos — FS-6 (10), FS-2 (8), FS-5 (7), FS-3 (3), FS-4 (3) y FS-7 (6) — y 3 `No aplicable` ratificados (SEC-016, SEC-017, SEC-040). Excepciones aceptadas asociadas: E-01 (SEC-002), E-02 (SEC-005), E-03 (SEC-006), E-04 (SEC-007/008), E-05 (SEC-010) y E-06 (SEC-033). Pendientes operativos con seguimiento: P-01 (SEC-035); P-02 (SEC-037) ejecutado el 19/10/2026; P-03…P-05 no afectan casos `SEC-*`.

**P-02 ejecutado (19/10/2026):** canario en el PR #2 (valor sintético; el literal no se reproduce para no reintroducir un patrón detectable): el job `secret-scan` falló redactado (run `39328148173`, job `118319199755`) y la rama limpia pasó (run `39325175339`); el PR se cerró sin fusionar y la rama se eliminó. Hallazgo: `AKIAIOSFODNN7EXAMPLE` no sirve como canario porque la allowlist `.+EXAMPLE$` de Gitleaks lo excluye (run `39326646439` en verde). Detalle: `docs/SECURITY_STATIC_EVIDENCE.md` §7.3.

## 4. Evidencias que conservar

- commit y versión del artefacto;
- comandos y versiones de herramientas;
- resultado de analyzer y pruebas;
- reportes de SAST/SCA/secret scanning;
- capturas redacted o logs sanitizados;
- configuración Android/iOS inspeccionada;
- hallazgos abiertos, compensaciones y dueños;
- revisión de falsos positivos.

Nunca guardar tokens, claves ni datos personales completos como evidencia.

## 5. Gate de lanzamiento

Un release candidato debe tener revisiones de dependencias, secretos, permisos de plataforma, TLS, roles, almacenamiento y flujos transaccionales. Las pruebas deben ejecutarse en build release cuando la diferencia debug/release afecte seguridad/configuración. Todo riesgo alto pendiente necesita resolución o aceptación formal y explícita; el agente no puede aceptar riesgo en nombre del propietario.
