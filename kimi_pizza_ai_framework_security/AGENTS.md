# AGENTS.md — KIMI PIZZA

## 1. Propósito

Este archivo define las reglas permanentes para cualquier agente de IA que modifique el proyecto Flutter de KIMI PIZZA.

El objetivo no es solo compilar. El objetivo es mantener una aplicación escalable, mantenible, segura, reutilizable, testeable, consistente y con mínima deuda técnica.

## 1.1 Contexto verificado del proyecto y precedencia documental

> **Estado del proyecto (18/10/2026):** el plan de corrección de la auditoría técnica (`C-01`…`C-31` y `H-01`…`H-13`) está **ejecutado y cerrado** (fases `F0`–`F15`; suite **75/75**; `flutter analyze` **0 issues**; esquema **v25**). Fuente autoritativa del estado verificado: `AGENTS.md` de la raíz del repositorio y `kimi_pizza_ai_framework/` (`docs/AUDIT_CONSOLIDATED.md` §4 y `agent.md` de la raíz).

**Precedencia:** este framework es la **edición de seguridad** (planificación y verificación de seguridad con ISO/IEC 27001:2022 + 27002:2022 y OWASP MASVS/MASTG). Donde exista conflicto con el framework principal, **prevalece el framework principal**. Los documentos de dominio de esta carpeta son referencia de diseño (08/10/2026); el detalle físico vigente del esquema v25 está en `lib/core/database/db_schema.dart` y `kimi_pizza_ai_framework/docs/DATA_MODEL.md`.

**Hechos de seguridad ya implementados y verificados (evidencia en el repositorio):**

- **Credenciales:** PBKDF2-HMAC-SHA256 (310.000 iteraciones, sal de 128 bits) con actualización transparente de hashes legacy SHA-256 (`lib/core/utils/hash_utils.dart`; C-06).
- **Base de datos:** SQLCipher AES-256; clave en almacenamiento seguro del dispositivo; `PRAGMA foreign_keys = ON` (desde v23); `busy_timeout = 5000`; WAL deshabilitado por compatibilidad con `.kpzbackup` (v25; H-13 / F14).
- **Autenticación y cuentas:** login exclusivo por `username` validando `activo = 1 AND bloqueado = 0`; ciclo de vida de usuarios (bloquear/desbloquear, desactivar/reactivar) auditado y sin auto-baja del propio administrador (RN-10, RN-11).
- **Backups:** auto-backup Android de la base de datos desactivado (`allowBackup="false"` + reglas de extracción); único mecanismo oficial = `.kpzbackup` (AES-256-GCM + PBKDF2 310k, cifrado en `Isolate.run`) (RN-08, C-17).
- **Red:** el manifiesto no declara permiso `INTERNET`; fuentes Poppins empaquetadas sin descarga en runtime (C-21).
- **Release:** la firma de release exige `android/key.properties` (falla con mensaje claro si falta; nunca usa la clave debug) (H-09 / F10).
- **Integridad del POS:** la boleta no duplica ventas ante fallo de PDF (H-07); movimientos de caja y gastos vinculados por ID explícito (H-05, RN-02); invariantes de sobrantes/traslados con idempotencia (RN-03); cuadre de caja centralizado (RN-04).

**Pendientes de verificación (de entorno, no de código):** comprobación funcional de cifrado/instalación en dispositivo físico o emulador (`F11(e)`, `F12(d)` — sin dispositivo disponible en el entorno actual) y ruta positiva de build release firmado (requiere keystore propio). La evaluación formal de los controles de seguridad es el trabajo pendiente de esta edición (ver `docs/SECURITY_CONTROL_MATRIX.md`; plan de acción por fases y prompts de ejecución en `docs/SECURITY_ACTION_PLAN.md` y `docs/SECURITY_PHASE_PROMPTS.md`).

## 2. Regla de oro

ANTES de modificar o crear código:

1. Inspecciona la implementación existente.
2. Identifica la funcionalidad relacionada.
3. Busca clases, widgets, servicios, modelos, repositorios, helpers, estilos y validadores reutilizables.
4. Determina la causa raíz si existe un bug.
5. Identifica dependencias e impacto cruzado.
6. Decide la capa correcta para el cambio.
7. Reutiliza antes de crear.

Nunca hagas un parche rápido cuando el problema es arquitectónico o de lógica de negocio.

## 3. Principios obligatorios

- SOLID.
- DRY.
- KISS cuando no reduzca la mantenibilidad.
- Alta cohesión y bajo acoplamiento.
- Separación de responsabilidades.
- Tipado fuerte.
- Inversión de dependencias.
- Reutilización real.
- Diseño preparado para extensión.
- Manejo explícito de estados de UI.
- Seguridad por diseño.
- Pruebas para reglas de negocio críticas.

## 4. Arquitectura

Preferir una arquitectura por feature con separación de presentation, domain y data. La estructura exacta puede adaptarse a la arquitectura ya existente, pero las responsabilidades deben permanecer separadas.

La UI no debe contener reglas de negocio, cálculos complejos, acceso directo a persistencia o llamadas HTTP directas.

Flujo conceptual:

UI -> State/Controller/ViewModel/Notifier -> Use Case -> Repository -> Data Source -> API/DB/Storage

Mantener un único patrón de manejo de estado en el proyecto, salvo justificación técnica explícita. No mezclar librerías de estado para resolver el mismo problema.

## 5. No duplicidad

Antes de crear un recurso, buscar uno equivalente.

No duplicar:
- widgets;
- estilos;
- validadores;
- modelos/entidades equivalentes;
- servicios;
- repositorios;
- lógica de fechas;
- selección de cámara/galería;
- diálogos;
- manejo de loading/error/empty;
- conversiones de unidades;
- cálculos monetarios;
- reglas de stock;
- generación/visualización de PDF.

Si existe una implementación válida, reutilizarla. Si existe pero está mal diseñada, refactorizarla en lugar de crear una segunda versión.

## 6. UI y estilos

Centralizar y reutilizar:
- tema;
- colores;
- tipografías;
- spacing;
- tamaños;
- radios;
- sombras;
- iconografía recurrente.

No repetir literales de estilos sin necesidad.

Usar widgets compartidos cuando haya repetición significativa o una responsabilidad visual estable.

## 7. Seguridad

Las reglas resumidas de esta sección son obligatorias y se desarrollan técnicamente en `docs/SECURITY_BASELINE.md`.

- No almacenar contraseñas en texto plano.
- No registrar tokens o datos sensibles en logs.
- Persistir credenciales/tokens solo con almacenamiento seguro cuando corresponda.
- Los permisos por rol no se pueden basar únicamente en ocultar botones.
- Las operaciones críticas deben validar autorización también en backend cuando exista.
- No confiar en el cliente para reglas de seguridad.
- Validar entradas en UI, dominio y servidor según el límite de confianza.
- No degradar TLS ni aceptar certificados inválidos.
- Revisar dependencias, secretos, almacenamiento local, backups y configuración nativa.
- Manejar errores sin filtrar detalles internos al usuario.
- Para tareas de seguridad, cargar `.claude/skills/security-review/SKILL.md` y consultar la matriz y plan de pruebas de seguridad.

## 8. Roles y permisos

Los roles y permisos reales del proyecto son fuente de verdad. Como mínimo, el sistema contempla Administrador y Empleado.

Las operaciones administrativas incluyen, según permisos reales:
- configuración global;
- QR para cobros;
- operaciones de caja excepcionales;
- administración de usuarios;
- acciones sensibles.

## 9. Sesión

La sesión debe mantenerse iniciada hasta que el usuario cierre sesión o el flujo de negocio determine el cierre de la sesión por cierre de caja.

No implementar cierres de sesión arbitrarios al navegar entre módulos.

## 10. Dominio transversal

Las áreas más acopladas del sistema son:
- compras;
- proveedores;
- insumos;
- recetas;
- preparación;
- transformaciones;
- ventas;
- mermas;
- caja;
- reportes.

Cualquier cambio en una de estas áreas debe analizar su impacto en las demás.

## 11. Inventario

El stock debe tener una fuente de verdad clara. Preferir un historial de movimientos como base trazable.

Movimientos relevantes:
- compra;
- consumo de receta/preparación;
- venta;
- cortesía;
- transformación;
- merma;
- ajuste.

Evitar doble descuento del mismo evento.

## 12. Unidades

La aplicación debe manejar conversiones centralizadas para:
- kg <-> g;
- litros <-> ml;
- paquetes <-> unidades cuando el paquete tenga contenido definido.

Las recetas pueden usar una unidad de formulación distinta de la unidad de stock.

## 13. Reglas de negocio críticas

- Un insumo no debe duplicarse.
- Un proveedor no debe duplicarse.
- Una categoría no debe duplicarse.
- Un insumo no debe repetirse dentro de una receta.
- Un precio especial de una venta no debe alterar el precio base del producto.
- Una bebida de cortesía no se cobra, pero se registra y consume el recurso correspondiente.
- Las transformaciones de productos no deben duplicar físicamente el stock base.
- Las mermas deben registrar motivo y afectar inventario.
- El balance de caja debe provenir de las operaciones registradas, no de cifras manuales que contradigan los datos.
- El cierre después de medianoche debe respetar el ciclo operativo de caja y no solo la fecha calendario.

## 14. Modificación de código existente

No reemplazar módulos completos por comodidad.

Primero identificar si el problema es:
- bug funcional;
- bug de integración;
- problema de estado;
- problema de persistencia;
- problema de arquitectura;
- problema de UX;
- problema de concurrencia;
- falta de validación.

Corregir en la capa correcta.

## 15. Clases y archivos

Evitar:
- clases gigantes;
- pantallas gigantes;
- servicios con múltiples responsabilidades;
- funciones de negocio embebidas en widgets;
- dependencias circulares;
- variables globales innecesarias;
- `dynamic` sin justificación.

Si un archivo crece demasiado, evaluar separación por responsabilidad y feature.

## 16. Formularios

Todo formulario debe contemplar:
- valores por defecto válidos;
- validación;
- loading de envío;
- prevención de doble submit;
- manejo de éxito/error;
- recuperación adecuada ante fallo;
- limpieza posterior al guardado cuando corresponda.

## 17. Errores y estados

Las pantallas de datos deben poder representar, según el caso:
- loading;
- success;
- empty;
- error;
- refreshing;
- submitting.

Los mensajes visibles deben ser orientados al usuario, no trazas técnicas.

## 18. Fechas

Centralizar fecha actual, selector, formato y conversiones. Diferenciar fecha calendario de fecha/ciclo operativo de caja cuando aplique.

## 19. Cámara, galería y documentos

Reutilizar un servicio/componente común para captura/selección de imágenes y otro para visualización/documentos cuando corresponda.

## 20. PDF

La boleta generada por una venta debe guardarse persistentemente y quedar relacionada con la venta. No depender solo de archivos temporales.


## 21. Compras, proveedores, cuentas por pagar, activos, mermas y reportes

Antes de modificar estas áreas, consultar obligatoriamente:
- `docs/PURCHASES_SUPPLIERS_PAYABLE_ASSETS_WASTE_REPORTS.md`
- `docs/PURCHASES_ASSETS_WASTE_TEST_CASES.md`
- `.claude/skills/purchases-assets-waste-reporting/SKILL.md`

Reglas críticas:
- no existe un formulario paralelo de “Gasto/Egreso” dentro de Nueva Compra;
- una compra de insumo genera exactamente una entrada de inventario;
- una compra de activo debe poder vincularse al activo sin duplicar la transacción;
- proveedor puede existir tanto en compras pagadas como a crédito;
- una cuenta por pagar mantiene total, pagos/adelantos y saldo;
- una merma usa una única lógica de dominio aunque se origine desde distintos módulos;
- los reportes no crean una segunda contabilidad; derivan de las fuentes transaccionales;
- no borrar silenciosamente transacciones históricas para corregir errores;
- proteger operaciones contra doble submit y reintentos duplicados.

## 22. Cambios funcionales

Cada cambio debe considerar:
- persistencia;
- API/backend;
- estado;
- UI;
- seguridad;
- inventario;
- caja;
- reportes;
- auditoría;
- pruebas;
- regresiones.

## 23. Protocolo de debugging

Cuando se corrija un bug:
1. reproducir;
2. rastrear el flujo;
3. identificar causa raíz;
4. localizar la capa responsable;
5. revisar dependencias;
6. implementar corrección;
7. ejecutar pruebas específicas;
8. ejecutar regresiones relacionadas;
9. revisar duplicidad introducida;
10. verificar que el flujo completo siga consistente.

## 23.1 Documentación que debe consultarse según la tarea

Antes de cambios relevantes, consultar el documento de negocio/arquitectura que corresponda:
- arquitectura -> `docs/ARCHITECTURE.md`
- reglas generales -> `docs/BUSINESS_RULES.md`
- inventario -> `docs/INVENTORY.md`
- ventas -> `docs/SALES_FLOW.md`
- caja -> `docs/CASH_FLOW.md`
- modelo de datos -> `docs/DATA_MODEL.md`
- pruebas -> `docs/TESTING_STRATEGY.md`

Para un bug, usar además `docs/BUG_REPORT_TEMPLATE.md` como referencia.

## 24. Criterio de terminado

Una tarea no está terminada solo porque compila.

Debe:
- compilar;
- pasar análisis estático relevante;
- pasar las pruebas aplicables;
- no romper el flujo original;
- no introducir duplicidad evidente;
- respetar seguridad;
- respetar arquitectura;
- actualizar documentación si cambió una regla estructural.

## 25. Comunicación del agente

Antes de cambios complejos, informar brevemente:
- causa raíz detectada;
- archivos/áreas afectadas;
- enfoque de solución.

Después, informar:
- qué se cambió;
- qué pruebas se ejecutaron;
- qué queda pendiente, si existe.

No afirmar que algo fue verificado si no se ejecutó.

## 26. Usuarios y Configuración

Las reglas detalladas de estos módulos están en `docs/USERS_CONFIGURATION.md`.

Antes de modificar autenticación, autorización, sesión, perfiles, roles o configuración global, leer ese documento.

Reglas obligatorias:
- No confundir "mi perfil" con administración de usuarios.
- Las restricciones administrativas deben validarse en lógica/backend, no solo ocultando controles.
- La sesión no debe cerrarse por navegación normal.
- No almacenar contraseñas en texto plano.
- El QR de ventas es configuración global y tiene una única fuente de verdad.
- Solo el rol autorizado puede cambiar el QR.
- Cámara, galería y visor de imágenes deben reutilizar servicios/componentes existentes.
- Si falla un cambio de configuración, conservar el valor anterior.
- Si no existe QR, el sistema debe representar explícitamente el estado de configuración faltante.

## 27. Productos, recetas, insumos y preparación

Antes de modificar cualquiera de estas áreas, leer:
- `docs/PRODUCT_RECIPES_INVENTORY_PREPARATION.md`
- `docs/PRODUCT_PREPARATION_TEST_CASES.md`

Estas reglas son obligatorias para evitar doble descuento de stock, conversiones inconsistentes, preparación duplicada y transformaciones incorrectas.

## 28. Selección de Skill

Usar la Skill especializada cuando la tarea corresponda:
- arquitectura → `.claude/skills/flutter-architecture/`
- bug/error/flujo roto → `.claude/skills/flutter-debugging/`
- refactor/duplicidad → `.claude/skills/flutter-refactoring/`
- stock/recetas/preparación/compras/ventas/mermas → `.claude/skills/inventory-validation/` y `.claude/skills/product-inventory-flow/`
- seguridad/roles/sesión/QR administrativo → `.claude/skills/security-review/`
- pruebas/regresión → `.claude/skills/testing/`

Si una tarea cruza varias áreas, cargar todas las Skills relevantes, evitando repetir la misma instrucción varias veces.

## 29. Ventas, pagos y caja

Antes de tocar ventas o caja, consultar:
- `docs/SALES_PAYMENTS.md`
- `docs/CASH_FLOW.md`
- `docs/SALES_CASH_TEST_CASES.md`
- `docs/INVENTORY.md`
- `docs/PRODUCT_RECIPES_INVENTORY_PREPARATION.md`

Usar `.claude/skills/sales-cash-flow/SKILL.md`.

Reglas críticas:
- El precio personalizado de una venta nunca cambia el precio base.
- Yape/Plin usa el QR configurado por administración.
- La cortesía se registra con precio cero y consume el recurso correcto.
- Cobrar debe ser idempotente.
- El PDF de la boleta se persiste y no puede causar una venta duplicada si falla su generación.
- Una venta confirmada alimenta automáticamente la caja y reportes.
- La fecha operativa de una caja puede diferir de la fecha calendario.
- Cerrar a las 00:30 pertenece al ciclo operativo abierto el día anterior.
- Reabrir una caja cerrada requiere autorización y auditoría.

## 30. Orden de lectura según tarea

- Arquitectura general: `docs/ARCHITECTURE.md` + `flutter-architecture`.
- Bug general: `flutter-debugging`.
- Refactor: `flutter-refactoring`.
- Usuarios/configuración: `USERS_CONFIGURATION.md` + `security-review`.
- Productos/recetas/stock/preparación: `PRODUCT_RECIPES_INVENTORY_PREPARATION.md` + `product-inventory-flow` + `inventory-validation`.
- Ventas/pagos/caja: `SALES_PAYMENTS.md` + `CASH_FLOW.md` + `sales-cash-flow`.
- Seguridad: `security-review`.
- Pruebas: `testing`.

## 31. Matriz de trazabilidad obligatoria

Consultar `docs/TRACEABILITY_MATRIX.md` antes de modificar un flujo transversal o corregir un bug que pueda afectar más de un módulo.

Toda corrección debe identificar:
- evento o caso de uso afectado;
- módulos dependientes;
- datos que cambian;
- permisos requeridos;
- efectos secundarios;
- pruebas de regresión necesarias.

No dar por terminado un cambio transversal si solo se verificó la pantalla donde apareció el bug.

## 32. Documentos del dominio

Antes de trabajar en una funcionalidad, consultar la documentación aplicable:
- Usuarios/Configuración → `docs/USERS_CONFIGURATION.md`
- Productos/Recetas/Insumos/Preparación/Transformaciones → `docs/PRODUCT_RECIPES_INVENTORY_PREPARATION.md` e `docs/INVENTORY.md`
- Ventas/Pagos → `docs/SALES_PAYMENTS.md` y `docs/SALES_FLOW.md`
- Caja → `docs/CASH_FLOW.md`
- Compras/Proveedores/CxP/Activos/Mermas/Reportes → `docs/PURCHASES_SUPPLIERS_PAYABLE_ASSETS_WASTE_REPORTS.md`
- Trazabilidad transversal → `docs/TRACEABILITY_MATRIX.md`

La documentación sirve como especificación de reglas, pero la implementación existente debe ser inspeccionada antes de modificarla.

## 33. Roadmap de implementación

Antes de abordar cambios grandes, consultar `docs/IMPLEMENTATION_ROADMAP.md`. Seguir sus fases para evitar implementar simultáneamente módulos con dependencias de dominio aún inestables. Cuando un bug afecte varios módulos, identificar primero en qué fase pertenece la causa raíz y cuáles son sus consumidores.


# SEGURIDAD REFORZADA — MANDATO OBLIGATORIO

## S1. Autoridad documental

Antes de cualquier cambio que afecte seguridad, identidad, sesión, roles, almacenamiento, red, archivos, datos personales, dependencias, configuración nativa, builds, QR, ventas o caja, leer:
- `docs/SECURITY_BASELINE.md`
- `docs/SECURITY_CONTROL_MATRIX.md`
- `docs/SECURITY_TEST_PLAN.md`
- `.claude/skills/security-review/SKILL.md`
- las reglas de negocio de los módulos afectados.
- el estado verificado del proyecto: `AGENTS.md` (raíz), `kimi_pizza_ai_framework/docs/AUDIT_CONSOLIDATED.md` (sección 4) y `agent.md` (raíz).

No afirmar conformidad ni certificación ISO por tener documentación o pasar un conjunto limitado de pruebas.

## S2. Seguridad por diseño y modelo de amenazas

Para cambios sensibles, declarar activos, límites de confianza, actores, escenarios de abuso y mitigaciones. Considerar confidencialidad, integridad, disponibilidad, autenticidad, privacidad y trazabilidad. Usar STRIDE como ayuda, no como trámite. Si la arquitectura real es local-only, declarar los límites frente a control físico/root o modificación del APK; no presentar controles en Dart como defensa fuerte contra quien controla el dispositivo.

## S3. Reglas de autenticación y autorización

- Denegar por defecto; mínimo privilegio.
- No confiar en roles, precios, IDs, totales, stock, sesión de caja ni permisos recibidos del cliente.
- Ocultar un botón no reemplaza autorización de la operación.
- Si existe backend, el backend valida autorización por endpoint y recurso/objeto.
- No hardcodear cuentas privilegiadas ni contraseñas temporales permanentes.
- Nunca persistir contraseña en Flutter. No almacenar tokens en preferencias ordinarias, logs, URL ni analytics.
- Separar sesión de autenticación y ciclo operativo de caja.
- Desactivación de usuario, cambio de rol, logout o revocación deben bloquear operaciones posteriores según las capacidades de la arquitectura.
- Evaluar reautenticación/MFA para acciones administrativas de alto impacto cuando el proveedor/arquitectura lo permita.

## S4. Almacenamiento, criptografía y secretos

- Para secretos pequeños, utilizar Keychain/Keystore mediante paquete mantenido y revisado.
- No usar `.env`, `--dart-define`, assets o configuración empaquetada como bóveda de secretos.
- No implementar criptografía propia ni fijar claves de cifrado dentro del binario.
- No aceptar certificados TLS inválidos ni deshabilitar validaciones.
- Revisar backup, exportación, archivos temporales, cachés, PDF, fotografías y base de datos local.
- La ofuscación no protege secretos y no reemplaza autorización, cifrado ni gestión de claves.
- Si se expone un secreto: rotar/revocar y revisar alcance e historial, no solo borrar el archivo.

## S5. Integridad del POS

La seguridad abarca la integridad financiera y operacional:
- compras, ventas, pagos, movimientos de stock, mermas y cierres deben ser idempotentes donde corresponda;
- doble click, retry, offline sync o error posterior al cobro no deben duplicar la transacción;
- autorización server-side si existe autoridad remota;
- QR de cobro modificable solo por rol autorizado, con cambio persistente y verificable;
- operaciones sensibles quedan auditadas sin registrar secretos ni datos innecesarios;
- no corregir datos históricos borrando silenciosamente evidencia.

## S6. Entradas, API y archivos

Validar datos en capa de dominio y en servidor donde exista. Usar consultas parametrizadas; validar tipos, rangos, tamaños, enums, IDs, formatos, archivos y permisos. Prevenir IDOR/BOLA, inyección, path traversal, reintentos no idempotentes, exceso de recursos y divulgación por mensajes/stack traces. Tratar imágenes, PDFs, datos OCR, JSON, deep links y contenido importado como entrada no confiable.

## S7. Plataformas y release

Revisar permisos y componentes Android/iOS, cleartext HTTP, TLS, backup, deep links, firma y endpoints por ambiente. Mantener configuración segura de release. No introducir `debuggable` ni endpoints de desarrollo en producción. No modificar `AndroidManifest.xml`, `Info.plist`, entitlements, network security config o política de backup sin documentar el objetivo y probar regresión.

## S8. Dependencias, CI y análisis

Antes de agregar/actualizar dependencias, revisar mantenimiento, avisos, permisos, código nativo y transitivas. No realizar upgrades masivos no revisados. Cuando el entorno lo permita, ejecutar y reportar: formatter, `flutter analyze`, pruebas relevantes, análisis de dependencias/advisories, secret scanning, SAST y comprobaciones de release. No ocultar un hallazgo ni afirmar una herramienta ejecutada sin evidencia. Excepciones deben incluir responsable, mitigación, riesgo residual y caducidad.

## S9. Gestión de vulnerabilidades e incidentes

Cada hallazgo debe incluir severidad, escenario, impacto, causa raíz, evidencia sanitizada, mitigación, corrección, responsable, plazo, pruebas y riesgo residual. No ejecutar pruebas destructivas en producción sin autorización. No borrar logs/evidencias de incidentes sin un plan aprobado. Las credenciales comprometidas requieren revocación/rotación y evaluación de alcance.

## S10. Referencias y evidencia

Aplicar el mapeo indicativo de `docs/SECURITY_CONTROL_MATRIX.md`, alineado a ISO/IEC 27001:2022/27002:2022 y OWASP MASVS/MASTG. Para cada afirmación de seguridad especificar la evidencia. La existencia de este archivo no equivale a cumplimiento formal del SGSI ni a certificación.

## S11. Gate obligatorio de seguridad

No cerrar una tarea de seguridad hasta:
- [ ] identificar activo y límite de confianza;
- [ ] investigar causa raíz;
- [ ] aplicar el cambio en la capa correcta;
- [ ] probar el camino negativo/bypass;
- [ ] revisar logs, almacenamiento, permisos y datos sensibles afectados;
- [ ] ejecutar las pruebas y herramientas realmente disponibles;
- [ ] comprobar regresiones transversales;
- [ ] actualizar matriz/documentación si corresponde;
- [ ] informar claramente lo probado y lo no probado.
