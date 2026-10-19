# KIMI PIZZA — Línea base técnica de seguridad

**Tipo:** estándar interno de ingeniería segura y referencia de verificación  
**Aplicación:** aplicación Flutter de KIMI PIZZA, configuración de compilación, almacenamiento local, servicios/API asociados si existen, procesos de desarrollo y despliegue.  
**Estado:** baseline propuesto; debe verificarse contra la implementación real y el contexto de operación antes de declararse implantado.

> **Aviso de conformidad.** Este documento busca alinear controles técnicos con ISO/IEC 27001:2022, los controles de ISO/IEC 27002:2022 y OWASP MASVS/MASTG. No demuestra por sí solo conformidad ni certificación. ISO/IEC 27001 requiere un sistema de gestión organizacional basado en alcance, riesgos, responsabilidades, evidencia, auditoría y mejora continua; una auditoría formal debe evaluar el sistema completo y la aplicabilidad de los controles.

## 1. Lenguaje normativo

- **DEBE / PROHIBIDO:** requisito obligatorio, salvo excepción documentada, aprobada por responsable y con riesgo residual aceptado.
- **DEBERÍA:** recomendación por defecto; cualquier desviación debe justificarse.
- **PUEDE:** opción contextual.
- **Evidencia:** prueba reproducible, configuración revisada, resultado CI, registro de auditoría o documento aprobado. Una afirmación del agente no es evidencia.

## 2. Objetivos de seguridad

Proteger la confidencialidad, integridad, disponibilidad, autenticidad y trazabilidad de los datos y operaciones de KIMI PIZZA. La solución debe resistir razonablemente pérdida o robo del dispositivo, cuentas comprometidas, empleados con permisos excesivos, manipulación del cliente, errores de integración, dependencias vulnerables, datos malformados, reintentos, concurrencia y fallos operativos.

La seguridad se implementa de forma proporcional al riesgo, sin convertir el código en una arquitectura innecesariamente compleja. No se deben sacrificar integridad financiera o de inventario por conveniencia visual.

## 3. Alcance y supuestos

El agente debe descubrir y documentar antes de evaluar:

1. si la aplicación es local, cliente-servidor, híbrida u offline-first;
2. dónde reside la fuente de verdad de usuarios, roles, productos, stock, compras, ventas y caja;
3. qué base de datos, API, servicios de terceros y almacenamiento de archivos se utilizan;
4. cómo se distribuyen los APK/IPA y quién firma las compilaciones;
5. qué datos personales y comerciales procesa realmente la aplicación;
6. qué capacidades están disponibles sin conexión y qué se sincroniza más adelante.

No debe asumir que existe backend ni inventar controles que no se pueden desplegar en el contexto actual. Si el sistema es exclusivamente local, deberá identificar explícitamente los límites de seguridad: un atacante con control del dispositivo o acceso a la base de datos puede alterar el estado local; un control de rol implementado solo en Dart no es una barrera fuerte frente a quien controla el dispositivo.

## 4. Normas y marcos de referencia

### 4.1 Referencias primarias

- **ISO/IEC 27001:2022**, incluyendo la enmienda 1:2024 cuando resulte aplicable: requisitos de un sistema de gestión de seguridad de la información (SGSI).
- **ISO/IEC 27002:2022:** guía de controles de seguridad de la información.
- **ISO/IEC 27701:2025**, cuando aplique al tratamiento de información personal: sistema de gestión de información de privacidad.
- **OWASP MASVS:** controles de seguridad y privacidad para aplicaciones móviles.
- **OWASP MASTG:** guía técnica para verificar esos controles mediante pruebas.
- **Documentación oficial de Flutter, Android y Apple:** prácticas de configuración y seguridad específicas de plataforma.

### 4.2 Cómo aplicar las referencias

El agente DEBE usar los controles como referencias de diseño y evidencia, no como una declaración automática de cumplimiento. La organización debe realizar análisis de riesgos, definir alcance, seleccionar controles, justificar exclusiones y conservar evidencia. Las obligaciones legales de protección de datos, consumo, empleo y conservación de comprobantes deben identificarse con asesoría competente en las jurisdicciones donde se opere.

### 4.3 Perfil móvil OWASP

Como mínimo, evaluar las ocho familias de MASVS:

- `MASVS-STORAGE`: almacenamiento local y exposición involuntaria.
- `MASVS-CRYPTO`: uso correcto de criptografía y gestión de claves.
- `MASVS-AUTH`: autenticación, sesión y autorización.
- `MASVS-NETWORK`: canales de comunicación.
- `MASVS-PLATFORM`: interacción segura con el sistema operativo y otras aplicaciones.
- `MASVS-CODE`: calidad, actualización y configuración segura.
- `MASVS-RESILIENCE`: resistencia proporcionada ante manipulación/reversión.
- `MASVS-PRIVACY`: minimización y protección de datos personales.

La aplicabilidad de cada control se debe registrar por escrito y validar usando pruebas MASTG pertinentes.

## 5. Modelo de amenazas mínimo

### 5.1 Activos a proteger

| Activo | Riesgo principal | Impacto |
|---|---|---|
| Credenciales, sesiones y roles | robo, reutilización o elevación de privilegios | acceso no autorizado |
| Datos de usuarios | divulgación o modificación | privacidad y control administrativo |
| Ventas, pagos registrados y boletas | alteración, duplicidad o pérdida | pérdida financiera y trazabilidad |
| Caja, aperturas y cierres | manipulación de arqueos o reaperturas | pérdida y fraude operativo |
| Compras, deudas y pagos | alteración de saldos | obligaciones financieras incorrectas |
| Stock, recetas, preparación, cortesías y mermas | ajustes o consumos indebidos | inventario y reportes incorrectos |
| QR de Yape/Plin | sustitución no autorizada | pago dirigido a cuenta equivocada |
| Imágenes, facturas y PDF | archivo malicioso, fuga o alteración | privacidad e integridad documental |
| Configuración y claves de firma | manipulación del comportamiento o publicación fraudulenta | compromiso de usuarios y aplicación |
| Copias de seguridad | exposición o pérdida | interrupción y fuga de datos |

### 5.2 Actores y escenarios

Considerar al menos: usuario legítimo que se equivoca; empleado con permisos excesivos; cuenta robada; persona con acceso físico al dispositivo; dispositivo perdido o desbloqueado; dispositivo con root/jailbreak; APK modificado; atacante de red; API caller no autorizado; dependencia comprometida; desarrollador que publica un secreto; actor que reintenta o reproduce peticiones; archivo o imagen malformada; proceso de backup/exportación inseguro.

### 5.3 STRIDE

Para cada flujo crítico documentar, como mínimo:

- **Spoofing:** ¿puede alguien suplantar usuario, rol, dispositivo o servicio?
- **Tampering:** ¿puede alterar petición, precio, stock, importe, QR, PDF, base local o estado de caja?
- **Repudiation:** ¿queda evidencia fiable de quién hizo una operación sensible?
- **Information disclosure:** ¿se exponen datos en logs, copias, archivos temporales, pantalla o API?
- **Denial of service:** ¿puede un bucle, archivo enorme, reintento o consulta bloquear el POS?
- **Elevation of privilege:** ¿puede un empleado ejecutar operaciones de administrador cambiando el estado local o parámetros de una petición?

Las amenazas deben relacionarse con mitigaciones, dueño, severidad, riesgo residual y pruebas. No basta con nombrar STRIDE.

## 6. Clasificación y minimización de datos

Aplicar estas etiquetas internas orientativas:

- **Público:** recursos destinados a mostrarse públicamente.
- **Interno:** catálogo, categorías e información operativa no destinada al público.
- **Confidencial:** ventas, compras, costos, balances, proveedores, datos de usuario y auditoría.
- **Restringido:** contraseñas, tokens, claves privadas, credenciales, secretos de firma y datos de autenticación.

Reglas:

1. Recoger solo los datos necesarios para una finalidad legítima y definida.
2. No almacenar contraseñas de pago, PIN bancarios, CVV ni credenciales de Yape/Plin.
3. No tratar el QR comercial de cobro como secreto criptográfico, pero sí proteger su **integridad** porque cambiarlo puede dirigir pagos a un tercero.
4. Definir retención y eliminación para logs, imágenes, facturas, boletas, exportaciones y backups.
5. No incluir información personal o financiera real en datos de prueba cuando se puedan usar fixtures sintéticos.
6. No transmitir datos a analytics o terceros sin finalidad, configuración y base legal revisadas.

## 7. Ciclo de desarrollo seguro

Toda tarea que toque seguridad sigue el proceso:

1. **Descubrir:** revisar el código, dependencias, configuración y arquitectura real.
2. **Definir el activo y límite de confianza:** qué se protege y quién puede manipularlo.
3. **Modelar amenazas:** identificar abuso, ataque y efectos transversales.
4. **Revisar referencias:** abrir `AGENTS.md`, este documento, la matriz de controles y la Skill de seguridad.
5. **Diseñar la mitigación mínima suficiente:** preferir mecanismo existente probado y reutilizable.
6. **Implementar en la capa correcta:** dominio, infraestructura, plataforma o backend; nunca solo en UI cuando es una regla de autorización.
7. **Probar controles y bypasses:** camino normal, negativo, concurrencia, sesión caducada, roles, datos malformados y fallos.
8. **Ejecutar análisis y regresión:** formatter, analyzer, pruebas, escaneo de secretos/dependencias y verificaciones de plataforma disponibles.
9. **Documentar evidencia:** comandos, resultados, limitaciones y riesgos residuales.
10. **Revisar:** confirmar que el parche no introduce un secreto, permiso excesivo o duplicidad.

No dar por cerrado un riesgo importante con una explicación textual solamente.

## 8. Identidad, autenticación y cuentas

### 8.1 Fuente de verdad

Si existe backend, el backend o proveedor de identidad aprobado es la autoridad para autenticar usuarios y resolver roles/permisos. Flutter puede conservar estado para UX, pero los datos recibidos del cliente son manipulables. La aplicación no debe decidir que una contraseña es válida basándose en un valor hardcodeado, local o codificado en el APK.

Si toda la aplicación funciona en un solo dispositivo sin servidor, documentar la amenaza de acceso físico/root y no presentar el login local como protección fuerte de datos. Evaluar si los activos requieren una autoridad central, protección de base de datos o separación de cuentas del sistema operativo.

### 8.2 Contraseñas

- Nunca persistir contraseñas en texto plano en Flutter, preferencias, ficheros, base local, logs o analítica.
- El cliente envía credenciales solo por un canal TLS validado cuando exista autenticación remota.
- El almacenamiento/validación de contraseñas corresponde al backend. Usar una función de hash de contraseñas moderna y parametrizada, como Argon2id o alternativa aprobada; nunca cifrado reversible ni hash rápido general como SHA-256 sin un esquema específico de password hashing.
- Aplicar longitud y reglas acordes a guía vigente, bloqueo o ralentización progresiva ante intentos, protección frente a credential stuffing y recuperación controlada.
- No mostrar si un usuario existe en contextos donde esa enumeración represente riesgo.
- No usar contraseñas genéricas compartidas para cuentas reales. Si se provisiona una contraseña temporal, forzar cambio por flujo autenticado y expirar el código temporal.

### 8.3 Acceso administrativo

- Aplicar privilegio mínimo y denegar por defecto.
- Evaluar MFA o reautenticación para operaciones administrativas de alto impacto, especialmente cambios de usuarios/roles, cambio del QR de cobro, ajustes de caja, reaperturas y exportación de datos.
- La UI puede ocultar acciones, pero el permiso se verifica en el límite de confianza que protege la operación.
- No permitir a un administrador eliminar o degradar la única cuenta administrativa sin un mecanismo de recuperación aprobado.
- Registrar creación, edición, desactivación, cambio de rol, recuperación y acciones privilegiadas.
- Desactivar cuentas revocando sesiones/tokens pertinentes y bloqueando operaciones futuras.

### 8.4 Autorización

- Usar políticas centralizadas y explícitas, preferentemente RBAC con permisos específicos si los roles simples ya no bastan.
- Aplicar autorización por operación y por objeto/recurso, no solo por pantalla.
- Para API, validar que el usuario tiene permiso sobre el ID solicitado, evitando IDOR/BOLA.
- No confiar en `role`, `isAdmin`, precio, importe, stock, `userId` o `cashSessionId` enviados por el cliente sin validación.
- No mezclar roles de empleado con roles técnicos; evitar privilegios implícitos por valores nulos o desconocidos.
- La falta de permisos produce rechazo seguro, sin cambios parciales.

## 9. Sesiones y tokens

- Distinguir **sesión de autenticación** de **sesión operativa de caja**. No son el mismo objeto ni deben compartir semántica accidentalmente.
- Respetar el requisito de continuidad de la app sin cerrar sesión por navegación normal, pero documentar riesgo por dispositivo compartido y aplicar controles proporcionales (bloqueo de pantalla, reautenticación para acciones críticas o política de inactividad aprobada).
- Logout debe limpiar credenciales/sesión local y revocar sesión remota cuando el proveedor lo permita.
- Ante cuenta desactivada, rol cambiado, sesión revocada o token expirado, volver a validar y denegar acceso.
- No confiar solo en la expiración visual del cliente.
- Cuando se usen access/refresh tokens, minimizar duración del access token, guardar refresh token en almacenamiento protegido, rotarlo/revocar según proveedor y no incluir tokens en URL.
- No persistir tokens en logs, analytics, crash reports, `SharedPreferences` ordinarias ni bases locales sin protección.
- Prevenir carreras donde requests concurrentes reutilicen un refresh token de un solo uso y causen sesiones inconsistentes.
- Rechazar datos de sesión malformados o versiones futuras inesperadas con recuperación segura, no con un bypass.

## 10. Autorización de operaciones críticas KIMI PIZZA

Cada operación debe tener comprobación de permiso y registro cuando aplique:

- crear/modificar/desactivar usuarios;
- modificar roles/permisos;
- cambiar el QR de cobro;
- abrir caja, cerrar caja o reabrirla excepcionalmente;
- registrar pagos, devoluciones o anulaciones;
- modificar precios de catálogo, si corresponde;
- alterar stock, hacer ajuste o registrar merma;
- modificar compras, deudas, saldos o pagos;
- consultar/exportar reportes confidenciales;
- borrar o corregir documentos históricos.

Los cambios de precio por operación deben conservar el precio aplicado en el detalle de la venta y no alterar automáticamente el precio base del producto.

## 11. Almacenamiento local, archivos y backups

### 11.1 Almacenamiento sensible

- Usar Keychain de iOS / Keystore de Android mediante una biblioteca Flutter mantenida y revisada para secretos pequeños (tokens, claves de sesión), tras inspeccionar configuración y compatibilidad actuales.
- No usar `SharedPreferences` como bóveda de secretos.
- No implementar criptografía propia ni una clave de cifrado hardcodeada en el APK.
- Proteger bases locales con controles adecuados al modelo de amenaza. Si el contenido comercial/financiero requiere cifrado y se almacena en SQLite, seleccionar y verificar una solución mantenida de cifrado de base de datos; el cifrado de archivos/backups debe tener gestión de claves definida.
- No afirmar que una base es segura solo porque reside en el sandbox de la aplicación.
- Limpiar cachés y archivos temporales sensibles al finalizar su uso; no prometer borrado físico perfecto en memoria flash.

### 11.2 Backups y exportaciones

- Identificar qué se incluye en backup automático de Android/iOS y excluir secretos/datos no necesarios.
- No guardar exportaciones confidenciales en ubicaciones públicas o compartidas por defecto.
- Informar qué se exporta, usar nombres de archivo que no contengan información personal innecesaria y compartir mediante mecanismos del sistema operativo con intención explícita del usuario.
- Proteger backups en tránsito y reposo y probar restauración.
- Cualquier eliminación/retención debe contemplar copias, documentos y requisitos del negocio.

### 11.3 PDF, fotografías y facturas

- Tratar archivos importados, imágenes, metadatos OCR y PDF como entrada no confiable.
- Validar extensión, MIME detectado y firma real del archivo donde sea posible; limitar tamaño, resolución y tiempo de procesamiento.
- No ejecutar ni abrir automáticamente contenido externo.
- Evitar nombres de ruta basados en entrada libre; generar nombres internos seguros y prevenir path traversal.
- No incluir secretos o datos innecesarios en metadatos del PDF.
- Verificar permisos de lectura/escritura, política de compartición, almacenamiento persistente y limpieza de temporales.
- La falla de generación de una boleta no debe duplicar la venta ni ocultar que el cobro ya fue confirmado.

## 12. Criptografía y claves

- Usar primitivas, algoritmos, modos y bibliotecas criptográficas reconocidos y mantenidos; no diseñar algoritmos propios.
- Seleccionar algoritmos y parámetros conforme a recomendaciones vigentes y al ecosistema disponible; registrar la decisión técnica.
- Usar TLS para el transporte de datos confidenciales. No degradar a HTTP en producción.
- Verificar certificados correctamente; nunca aceptar cualquier certificado, ignorar errores TLS ni instalar un `badCertificateCallback` permisivo.
- No usar cifrado como sustituto de la autorización.
- Separar claves de cifrado, claves de firma de app y credenciales de servicios.
- Definir almacenamiento, acceso, rotación, respaldo, revocación y recuperación de claves del lado de la infraestructura pertinente.
- Un secreto introducido en Dart, assets, `--dart-define`, archivo `.env` empaquetado, recursos nativos o configuración de build puede extraerse del binario; no es un secreto seguro.
- Si una clave fue expuesta, revocarla/rotarla; borrarla del último commit no repara la exposición histórica.

## 13. Red, API y servicios externos

- Producción debe usar HTTPS/TLS; habilitar HTTP solo para entorno de desarrollo aislado y nunca mediante una excepción incluida en release.
- No desactivar validación de hostname/certificado ni permitir conexiones inseguras globales.
- Configurar restricciones de cleartext/Network Security Config en Android según el threat model; mantener ATS de iOS habilitado, salvo excepción técnica documentada, acotada y revisada.
- Certificate pinning no es una opción por defecto: solo introducirlo con análisis de riesgos, proceso de rotación/backup y plan de recuperación para no provocar indisponibilidad.
- Aplicar timeouts, límites de respuesta, manejo de cancelación y límites de reintentos.
- No reintentar automáticamente operaciones no idempotentes sin idempotency key o protocolo equivalente.
- Para backend: autenticación y autorización en cada endpoint; validación de esquema; límites de tasa y tamaño; controles de concurrencia; protección contra IDOR/BOLA, mass assignment, inyección, SSRF cuando aplique y abuso de endpoints.
- No enviar secretos en query strings, URLs, nombres de archivo ni mensajes de error.
- No confiar en validaciones de Flutter: validar de nuevo en servidor importe, rol, estado de caja, stock, relación de objetos y reglas críticas.
- Manejar CORS donde aplique sin usar `*` para autorizar credenciales en un backend web.
- Si el sistema tiene sincronización offline, definir resolución de conflictos, idempotencia, origen temporal de cada dato y estrategia contra replay/manipulación.

## 14. Integridad de transacciones y lógica de negocio

La seguridad incluye prevenir estados financieros u operativos falsos, no solo proteger contraseñas.

- La autoridad de precios, importes, roles, stock y estado de caja debe quedar clara.
- Cada operación crítica debe ejecutarse de forma atómica en su límite transaccional cuando la tecnología lo permita.
- Proteger doble clic, reintentos, concurrencia y sincronización usando idempotencia, identificadores de operación, restricciones únicas y/o transacciones.
- Una venta confirmada no se debe duplicar por fallo posterior del PDF o por reintentar la interfaz.
- Compra, movimiento de stock, cuenta por pagar y pago/adelanto deben quedar consistentes o recuperarse mediante compensación explícita.
- Una merma o ajuste debe registrar motivo, usuario y fecha/hora; no realizar cambios invisibles.
- En transformaciones de producto, no permitir la creación ficticia de unidades: consumir la base y el ingrediente adicional una vez y registrar el destino.
- Cierre y reapertura de caja deben ser operaciones autorizadas, auditadas, idempotentes y relacionadas con el ciclo operativo correcto.
- El QR de Yape/Plin debe poder cambiarlo solo el usuario autorizado; registrar el actor, fecha y referencia/versionado del cambio. No publicar una nueva imagen si falla su guardado y lectura de verificación.
- Si la app no tiene backend, documentar que las garantías frente al propietario del dispositivo o frente a un APK modificado son limitadas; no declarar que una verificación local evita fraude por sí sola.

## 15. Validación de entradas y prevención de inyección

- Usar tipado fuerte; no usar `dynamic` para datos confiables sin validación.
- Parsear JSON y persistencia con manejo explícito de null, rango, longitud y tipos inesperados.
- Validar entradas en UI para UX y en capa de dominio/persistencia/API para integridad.
- Para SQL, usar consultas parametrizadas. Nunca construir SQL concatenando cadenas de usuario.
- Para rutas/archivos, normalizar y restringir a directorios permitidos.
- Para texto renderizado, evitar interpretar entrada como HTML/markup sin sanitización; revisar Flutter Web si se compila para navegador.
- Limitar longitud, cantidades, importes, dimensiones de imagen y listas para prevenir agotamiento de recursos.
- Validar enums y estados contra un conjunto permitido; valores desconocidos deben fallar de forma segura.
- No usar validación basada solo en expresiones regulares para reemplazar validación de dominio.

## 16. Gestión de errores y observabilidad

- Los mensajes al usuario deben ser comprensibles y no revelar stack traces, SQL, endpoints internos, tokens, rutas privadas ni detalles del proveedor.
- Los registros de diagnóstico deben minimizar y redactar datos personales y financieros.
- Nunca loguear passwords, access/refresh tokens, claves privadas, headers `Authorization`, cookies de sesión o secretos.
- Registrar eventos de seguridad relevantes: fallos de autorización, acciones administrativas, intentos sensibles repetidos, errores anómalos de integridad y reaperturas.
- Los logs deben tener timestamp consistente, actor/resultado cuando corresponda, correlación por request/operación y protección contra alteración según infraestructura.
- No recolectar logs de auditoría únicamente en el dispositivo que se intenta proteger si un atacante puede manipularlo; trasladar registros a un backend/control central cuando el riesgo lo requiera.
- Evitar auditar cada pulsación o contenido sensible innecesario; documentar retención y permisos de consulta.

## 17. Privacidad

- Mantener inventario de datos personales, finalidad, base de tratamiento, acceso, destinatarios, conservación y eliminación donde aplique.
- Minimizar datos en usuarios, empleados, proveedores, facturas y logs.
- No incorporar tracking, analytics o SDK de terceros sin revisar sus permisos, telemetría, política y configuración.
- Permitir corrección, exportación o eliminación cuando corresponda legalmente y no contradiga obligaciones legítimas de conservación de documentos; la solución requiere definición jurídica/organizacional.
- Evitar guardar contactos, ubicación, micrófono u otros permisos sin necesidad real. Cámara/galería solo cuando el usuario activa la función.
- Revisar permisos de Android/iOS después de cada dependencia nueva.
- No inferir consentimiento ni registrar datos no necesarios para el POS.

## 18. Plataforma Android e iOS

### Android

- Revisar `AndroidManifest.xml`: permisos mínimos, componentes/exportados y exposición de activities/services/receivers.
- No establecer `android:usesCleartextTraffic="true"` para release.
- Revisar `network_security_config`, `allowBackup`, reglas de extracción de datos y archivos compartidos según la clasificación de los datos y comportamiento requerido.
- No declarar componentes `exported` innecesariamente; proteger los componentes que lo requieren.
- Evitar `debuggable=true` en release; confirmar configuración de firma de producción.
- Revisar permisos de almacenamiento heredados; preferir APIs modernas y selección mediada por el sistema cuando sea posible.

### iOS

- Mantener App Transport Security activo.
- Revisar permisos/cadenas de propósito (`Info.plist`) con explicación clara y solo para capacidades utilizadas.
- Almacenar secretos de pequeña escala en Keychain mediante una solución mantenida.
- Revisar capacidades, grupos compartidos, URL schemes/deep links y universal links.
- No usar entitlements excesivos ni exponer archivos confidenciales a otras aplicaciones.

### Dispositivos comprometidos

Root/jailbreak detection y checks de integridad pueden elevar coste del ataque, pero pueden evadirse y causar falsos positivos. Usarlos únicamente cuando el análisis de riesgo lo justifique y no como única barrera ni como sustituto de autorización remota.

## 19. Dependencias y cadena de suministro

Antes de añadir o actualizar paquete:

1. Confirmar necesidad y no duplicidad.
2. Revisar mantenimiento, versión, licencias, publicaciones, repositorio, avisos de seguridad y transitive dependencies.
3. Reducir dependencias que accedan a red, archivos, cámara, galería, almacenamiento seguro o código nativo sin necesidad.
4. Fijar y revisar `pubspec.lock` para aplicaciones; no ejecutar actualización masiva no revisada como reparación automática.
5. Registrar la razón de paquetes con permisos sensibles.
6. Usar escáner de dependencias/advisories en CI y establecer SLA de corrección según severidad y exposición.
7. No importar código binario/script desconocido ni pegar soluciones criptográficas de origen no verificable.
8. Revisar changelog y breaking changes antes de actualizar Flutter/Dart o plugin nativo.

Herramientas sugeridas según disponibilidad: `flutter analyze`, `flutter test`, revisión de `flutter pub deps`, escáner de advisory compatible con Dart/OSV, Dependabot/Renovate, secret scanning (por ejemplo Gitleaks) y SAST compatible con Dart. Seleccionar versiones actuales, mantener acciones CI fijadas a versiones/SHAs cuando sea posible y no ejecutar herramientas a ciegas en producción.

## 20. Secretos y repositorio

- Prohibido commitear `.env` real, claves API privadas, JSON de service accounts, keystores, certificados privados, passwords, tokens, dumps de producción o datos personales reales.
- `.gitignore` no sustituye el secret scanning.
- `--dart-define`, flavors y variables de compilación sirven para configurar valores; no convierten un secreto en secreto si el valor se empaqueta dentro del cliente.
- Al detectar exposición: detener el uso, rotar/revocar, evaluar alcance y revisar el historial y artefactos publicados; no limitarse a borrar el texto.
- Las claves de firma deben residir en almacenamiento seguro/secret manager con mínimo privilegio y acceso auditado. No generar, publicar ni rotar claves sin una estrategia que conserve continuidad de distribución.
- Separar configuración de desarrollo, testing y producción. No permitir que un build de release use endpoints de desarrollo ni datos de prueba.

## 21. Builds y releases

- Compilar y probar release, no solo debug.
- Utilizar firma de release controlada y protegida; revisar reproducibilidad y procedencia de artefactos donde sea viable.
- La ofuscación de Dart (`--obfuscate` y `--split-debug-info`) solo incrementa la dificultad de ingeniería inversa; no cifra recursos ni oculta secretos embebidos. Guardar símbolos para diagnóstico en almacenamiento privado.
- No distribuir builds `debuggable`, con logs sensibles o endpoints de desarrollo.
- Verificar permisos, cleartext, flags de backup, deep links, configuración de TLS, firma, dependencias y secretos en el artefacto final.
- Documentar versión, commit, entorno, identidad de compilación y pruebas ejecutadas.

## 22. Pruebas mínimas de seguridad

Al menos probar, según aplicabilidad:

- empleado intenta una acción exclusiva del administrador;
- request altera `role`, `userId`, `price`, `total`, `stock`, `cashSessionId` o identificador de recurso;
- usuario desactivado/rol revocado sigue usando token previo;
- token ausente, vencido, malformado o revocado;
- contraseña no aparece en almacenamiento, logs o errores;
- secretos conocidos no se encuentran en repositorio ni artefacto;
- API rechaza IDOR/BOLA y payloads inválidos;
- múltiples requests o doble toque no duplican compra, venta, pago, merma o cierre;
- TLS inválido no se acepta;
- release no permite HTTP no cifrado accidental;
- importación de imagen/PDF grande o malformado falla con seguridad;
- cambiar QR requiere permiso y no pierde configuración previa si falla;
- exportaciones y backups no exponen datos restringidos;
- cierre/reapertura de caja y ajustes sensibles tienen auditoría;
- las pruebas de inventario protegen contra doble descuento y unidades no válidas.

Las pruebas deben hacerse únicamente sobre sistemas, cuentas y datos autorizados. No ejecutar pruebas de penetración destructivas en producción.

## 23. Automatización CI/CD

La pipeline DEBERÍA ejecutar por pull request:

1. formato (`dart format` en modo de comprobación);
2. `flutter analyze`;
3. pruebas unitarias, de widgets e integración pertinentes;
4. secret scanning;
5. escaneo de dependencias y licencias según política;
6. SAST/análisis estático adicional cuando sea compatible;
7. verificación de configuración Android/iOS;
8. build de release en una etapa protegida;
9. generación de artefactos y evidencias identificables.

La pipeline debe fallar en hallazgos bloqueantes definidos por política; no silenciar salidas de seguridad ni marcar un job como exitoso ignorando el código de salida. Documentar falsos positivos y excepciones con propietario, justificación y fecha de vencimiento.

No guardar credenciales de producción dentro del repositorio ni dar permisos de escritura a jobs que solo necesitan lectura.

## 24. Gestión de vulnerabilidades

Clasificar por severidad técnica e impacto de negocio: crítica, alta, media, baja o informativa. Considerar explotación, acceso requerido, alcance, datos afectados, posibilidad de fraude, exposición pública y mitigaciones disponibles.

Cada hallazgo debe tener:

- identificador y fecha;
- activo y módulo;
- descripción y escenario reproducible;
- impacto y severidad;
- evidencia redactada;
- causa raíz;
- mitigación provisional cuando proceda;
- corrección y pruebas de regresión;
- responsable y plazo objetivo;
- riesgo residual y aceptación explícita si no se corrige;
- versión donde queda remediado.

No incluir detalles explotables en un issue público. Usar canal privado autorizado. Ante vulnerabilidad crítica, priorizar contención segura, rotación de secretos, bloqueo de operaciones comprometidas y comunicación a los responsables.

## 25. Respuesta a incidentes

El proyecto debe tener un procedimiento operativo aprobado fuera del código para:

1. recibir el aviso;
2. clasificar severidad y alcance;
3. preservar evidencias sin ampliar exposición;
4. contener la amenaza;
5. revocar tokens o claves comprometidas;
6. publicar versión corregida mediante proceso controlado;
7. recuperar datos de respaldo si corresponde;
8. evaluar impacto y obligaciones de notificación;
9. analizar causa raíz;
10. actualizar pruebas, riesgos, documentación y controles.

El agente no debe borrar logs, resets o datos que puedan ser evidencias sin autorización y plan de conservación.

## 26. ISO/IEC 27001 y 27002: mapeo técnico indicativo

La matriz `docs/SECURITY_CONTROL_MATRIX.md` relaciona familias de controles con evidencia de ingeniería. El mapeo es orientativo y requiere que el responsable del SGSI evalúe aplicabilidad, riesgos, declaración de aplicabilidad y evidencias organizacionales.

Las principales áreas relevantes para el código incluyen control de acceso e identidades, información de autenticación, gestión de vulnerabilidades, configuración, logging, red, criptografía, ciclo de vida de desarrollo seguro, requisitos de seguridad de aplicaciones, arquitectura segura, codificación, pruebas, separación de ambientes y gestión de cambios.

Los controles técnicos no sustituyen controles de gobierno, recursos humanos, proveedores, continuidad, auditoría interna, gestión de riesgos ni revisión directiva requeridos por un SGSI completo.

## 27. Criterios de aceptación de una corrección de seguridad

No considerar terminada una tarea a menos que:

- [ ] se identificó el activo y el límite de confianza;
- [ ] se determinó y documentó la causa raíz;
- [ ] se aplicó la mitigación en la capa correcta;
- [ ] se probó el caso negativo/bypass, no solo el flujo feliz;
- [ ] se revisaron roles, sesión, almacenamiento, red y logs afectados;
- [ ] se ejecutaron pruebas y herramientas disponibles, informando resultados reales;
- [ ] se inspeccionaron cambios para detectar secretos y exposición accidental;
- [ ] se verificó impacto transversal en compras, stock, preparación, ventas, caja o reportes cuando aplique;
- [ ] se actualizó matriz/documentación/evidencia;
- [ ] los riesgos residuales se declararon en vez de ocultarlos.

## 28. Conductas expresamente prohibidas

El agente NO DEBE:

- afirmar que el proyecto es “ISO certificado”, “100 % seguro” o “OWASP compliant” por tener esta documentación;
- omitir una vulnerabilidad para lograr que el build pase;
- desactivar TLS, análisis, controles de backup o permisos sin revisión de riesgo;
- hardcodear contraseñas, tokens, claves privadas o cuentas administrativas;
- almacenar password o token en texto plano;
- depender solo de botones ocultos o validación de UI para proteger operaciones;
- crear criptografía propia;
- aceptar todos los certificados TLS;
- registrar payloads, tokens o datos financieros completos para depurar;
- realizar pruebas destructivas fuera de un entorno autorizado;
- incorporar una dependencia sensible sin revisar su mantenimiento y permisos;
- cambiar políticas de autenticación o datos existentes sin migración, compatibilidad, pruebas y plan de recuperación;
- asegurar que un control funciona si no fue probado.

## 29. Referencias oficiales

- ISO/IEC 27001:2022: https://www.iso.org/standard/27001
- ISO/IEC 27002:2022: https://www.iso.org/standard/75652.html
- ISO/IEC 27701:2025: https://www.iso.org/standard/27701
- OWASP MASVS: https://mas.owasp.org/MASVS/
- OWASP MASTG: https://mas.owasp.org/MASTG/
- Seguridad en Flutter: https://docs.flutter.dev/security
- Ofuscación de Dart: https://docs.flutter.dev/deployment/obfuscate
- Android Network Security Configuration: https://developer.android.com/privacy-and-security/security-config
- Android Security Best Practices: https://developer.android.com/privacy-and-security/security-tips
- Apple Keychain Services: https://developer.apple.com/documentation/security/keychain-services

**Mantenimiento:** revisar esta línea base al incorporar nuevos tipos de datos, autenticación, dependencias con permisos sensibles, pagos, sincronización, cloud/backend, cambios de plataforma o incidentes de seguridad; como mínimo, durante una revisión periódica acordada por el responsable del proyecto.

---

## 30. Anexo KIMI — Mapeo con el estado verificado del proyecto (18/10/2026)

El proyecto completó una auditoría técnica con plan de corrección cerrado (`C-01`…`C-31`; `H-01`…`H-13`; fases `F0`–`F15`; suite 75/75; `flutter analyze` 0 issues). Varias exigencias de esta línea base ya cuentan con **implementación verificada** en el repositorio: credenciales PBKDF2 con actualización transparente de hashes legacy, base de datos cifrada con SQLCipher, política de backup (`.kpzbackup` + auto-backup Android desactivado), manifiesto sin permiso `INTERNET`, gate de firma para release e integridad de ventas/inventario/caja.

El mapeo detallado control → evidencia → brecha/pendiente está en la sección **"Evidencia inicial del proyecto (18/10/2026)"** de `docs/SECURITY_CONTROL_MATRIX.md`, y la cobertura inicial de casos en la sección **3.1** de `docs/SECURITY_TEST_PLAN.md`.

**Importante:** este anexo no modifica el estado de esta línea base. Sigue siendo un **estándar propuesto cuya verificación formal está pendiente**: ningún control debe marcarse como `Implementado` sin re-ejecución, evidencia (ruta/comando/resultado), fecha/commit y revisor, según las reglas de la matriz.
