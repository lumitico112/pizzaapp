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
| SEC-002 | Pendiente | Verificar si existe mitigación de repetición de intentos de login; no consta implementada |
| SEC-005 | Parcial | RN-10/RN-11: cuenta inactiva o bloqueada no accede; ejecutar como prueba sobre build release |
| SEC-011 / SEC-012 | Pendiente | Sin secretos versionados conocidos (`key.properties` fuera de git); herramienta de secret scanning sin ejecutar |
| SEC-013 | Parcial | Contraseñas nunca en texto plano: PBKDF2-HMAC-SHA256 con sal (C-06); inspección formal de preferencias/temporales pendiente |
| SEC-014 | Parcial | Auto-backup Android desactivado; `.kpzbackup` con passphrase (RN-08); restore en dispositivo pendiente (`F11(e)`) |
| SEC-015 / SEC-016 | Parcial | Manifiesto sin `INTERNET`; sin endpoints (C-21); confirmar sobre artefacto release |
| SEC-017 / SEC-040 | No aplicable (hoy) | Sin backend ni sincronización: no hay tránsito de red ni replay remoto; revisar si se introduce sync |
| SEC-022 / SEC-023 / SEC-024 | Pendiente | QR: sin verificación en esta edición |
| SEC-025 | Pendiente | Doble toque/reintento de cobro sin prueba dedicada; relacionado con la corrección H-07 |
| SEC-026 | Cubierto por automatización | `test/pos_boleta_resiliencia_test.dart` (T1–T3): un fallo de PDF no duplica la venta (H-07 / F4) |
| SEC-027 / SEC-028 | Parcial | Escritor único de stock + invariantes sobrantes/traslados (`test/gestion_sobrantes_mermas_test.dart`); replay/concurrencia fina pendientes |
| SEC-029 / SEC-030 / SEC-031 | Pendiente | Sin prueba dedicada de reapertura/cierre; cuadre centralizado ya existe (RN-04) |
| SEC-032 | Parcial | `AuditLogWriter` para operaciones críticas; búsqueda automatizada de secretos en logs pendiente |
| SEC-034 | Parcial | Manifest: sin `INTERNET`, `com.kimipizza.pos`, backup desactivado (F10–F12); revisión completa de components/`exported` pendiente |
| SEC-035 | Parcial | Gate de firma release verificado (F10: falla sin `key.properties`; debug intacto); ruta positiva pendiente (requiere keystore) |
| SEC-036 | Parcial | Retiro de paquetes sin uso y dependencia EOL (F8/F11); escaneo SCA/advisories pendiente |
| SEC-037 | Pendiente | El workflow de CI no incluye secret scanning |

Las filas no listadas permanecen **sin cubrir** hasta su ejecución. La secuencia de ejecución por fases y el triaje formal de los 40 casos se organizan en `docs/SECURITY_ACTION_PLAN.md` (fases `FS-0`–`FS-9`; prompts por fase en `docs/SECURITY_PHASE_PROMPTS.md`). Cada caso que se cierre debe registrar fecha/commit/evidencia/herramienta/revisor según la sección 4.

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
