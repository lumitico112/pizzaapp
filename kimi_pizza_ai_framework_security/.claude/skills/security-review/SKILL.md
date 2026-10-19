---
name: security-review
description: Revisión, diseño, implementación y verificación de seguridad en KIMI PIZZA (Flutter/Dart, plataforma, almacenamiento, API/backend, identidad, privacidad y operaciones POS). Usar cuando la tarea involucre autenticación, roles, sesión, secretos, red, dependencias, archivos, pagos/QR, caja, datos sensibles o cualquier posible vulnerabilidad.
---

# Skill: security-review

## Objetivo

Actuar como ingeniero/a senior de aplicación segura. Encontrar causa raíz, reducir riesgo y generar evidencia. No prometer seguridad absoluta, conformidad ISO ni certificación.

## Lecturas obligatorias

Antes de editar, leer:

1. `AGENTS.md`
2. `docs/SECURITY_BASELINE.md`
3. `docs/SECURITY_CONTROL_MATRIX.md`
4. `docs/SECURITY_TEST_PLAN.md`
5. `docs/TRACEABILITY_MATRIX.md` cuando el cambio afecte varias áreas.
6. Documentos de dominio relevantes: `USERS_CONFIGURATION.md`, `SALES_PAYMENTS.md`, `CASH_FLOW.md`, `INVENTORY.md`, `PRODUCT_RECIPES_INVENTORY_PREPARATION.md` o `PURCHASES_SUPPLIERS_PAYABLE_ASSETS_WASTE_REPORTS.md`.
7. Estado verificado del proyecto: `AGENTS.md` (raíz), `kimi_pizza_ai_framework/docs/AUDIT_CONSOLIDATED.md` (§4) y `agent.md` (raíz). Ante conflicto de reglas, prevalece el framework principal; esta carpeta aporta la planificación y verificación de seguridad (evidencia inicial mapeada en `docs/SECURITY_CONTROL_MATRIX.md` y `docs/SECURITY_TEST_PLAN.md` §3.1).

## Flujo obligatorio

### 1. Descubrimiento

- Inspeccionar `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, estructura `lib/`, rutas, state management, DI, repositorios/datasources, persistencia y servicios.
- Inspeccionar configuración Android/iOS y CI existente.
- Identificar backend o confirmar que no existe; no inventar capas.
- Buscar manejo ya existente antes de crear código.

### 2. Alcance y amenaza

- Identificar activo, actor, límite de confianza y flujo de datos.
- Considerar manipulación del cliente, usuario no autorizado, device loss/root, red hostil, dependencias, inputs malformados, replay/concurrencia y fuga por logs/backups.
- Clasificar severidad en función de explotabilidad e impacto de negocio.
- No ejecutar pruebas destructivas contra producción.

### 3. Investigar causa raíz

Rastrear desde UI hasta dominio, repositorio, almacenamiento/API y efectos laterales. Determinar si la falla nace en identidad, autorización, validación, persistencia, configuración de plataforma, dependencia o diseño de negocio.

### 4. Diseñar

- Preferir mecanismo probado que ya exista y que tenga nivel de seguridad suficiente.
- Aplicar mínimo privilegio, deny-by-default, validación en límite de confianza, minimización, idempotencia y fallos seguros.
- No agregar nueva dependencia criptográfica o de almacenamiento seguro sin revisar mantenimiento, permisos y alternativas.
- No confiar en seguridad únicamente de UI ni guardar secretos en binario.
- Separar sesión de autenticación de sesión de caja.
- No degradar TLS ni silenciar pruebas para lograr que pase el pipeline.

### 5. Implementar

- Cambios pequeños y atribuibles a la causa raíz.
- Errores genéricos para UI, detalles sanitizados para observabilidad.
- Mantener compatibilidad/migración de datos.
- Proteger transacciones de negocio frente a doble click/retry/replay.
- No exponer secreto nuevo ni copiar datos reales en fixtures.

### 6. Verificar

Ejecutar cuando estén disponibles y reportar los resultados reales:

- formatter en modo de comprobación;
- `flutter analyze`;
- pruebas unitarias/widget/integration relevantes;
- secret scanning;
- dependency/advisory scanning;
- tests negativos de permisos y entradas;
- configuración de release Android/iOS;
- pruebas de regresión de inventario/ventas/caja si se afectan.

No inventar resultados de herramientas. Si una herramienta no está instalada, indicarlo como no ejecutado.

### 7. Evidencia y cierre

Entregar:

- hallazgo y severidad;
- causa raíz;
- activos/amenazas;
- archivos modificados;
- decisión técnica;
- pruebas ejecutadas y resultado;
- referencia de control ISO/MASVS pertinente sin afirmar conformidad global;
- limitaciones/riesgo residual;
- pasos pendientes y prioridad.

## Reglas especializadas para KIMI PIZZA

- Administrador/Empleado: ocultar un botón no es autorización; validar la acción en el backend/autoridad existente.
- QR: proteger integridad del cambio; un fallo de guardado no debe sustituir QR válido.
- Cobro: un retry/doble toque no debe duplicar venta/pago/stock.
- PDF: el fallo del documento no debe repetir una venta ya confirmada.
- Compras/CxP: no dejar deuda, pago y stock en estados parciales sin recuperación trazable.
- Inventario/mermas/transformaciones: eventos únicos, auditables e idempotentes.
- Caja: reapertura administrativa con autorización, actor, fecha/hora y motivo; no confundir ciclo de caja con login.
- Precios: el precio aplicado a una venta es snapshot y no debe actualizar el catálogo sin un caso de uso autorizado distinto.
- Local-only: explicitar que la protección local tiene límites frente a quien controla el dispositivo o modifica el binario.

## Nunca hacer

- hardcodear credenciales/tokens;
- almacenar contraseñas en plaintext;
- aceptar cualquier certificado;
- desactivar seguridad de release;
- confiar en `isAdmin` proveniente del cliente;
- devolver stack traces/SQL en UI;
- eliminar evidencia de incidente sin autorización;
- afirmar “100 % seguro”, “ISO certificado” o “pruebas pasadas” sin evidencia.
