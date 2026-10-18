# Kimi Pizza POS (`pizzaapp`)

Sistema Punto de Venta (POS) y gestión operativa **offline-first** para pizzería desarrollado en **Flutter / Dart** para **Android**, con base de datos local cifrada mediante **SQLCipher (`sqflite_sqlcipher`)** y respaldos portátiles cifrados (`.kpzbackup`).

---

## Módulos Principales

- **POS y Ventas:** Catálogo por variantes, promociones, bebidas por vaso, cortesías, cálculo de vuelto, pago en Efectivo y Digital (Yape/Plin/Transferencia/Tarjeta con visor QR) y emisión de boletas PDF persistentes con desglose de IGV (18%).
- **Caja y Arqueo Ciego:** Sesiones operativas nocturnas regidas por `sesion_caja_id`, movimientos de entrada/salida, cuadre centralizado (`CashCloseSummary`), reporte PDF de cierre y reapertura auditada.
- **Inventario, Recetas y Preparación Diaria:** Doble inventario (insumos en almacén y productos preparados), conversión automática de unidades (`kg`/`g`, `L`/`ml`, `Paquetes`/`Unidades`), transformaciones en vivo, control de sobrantes/mermas y algoritmo heurístico de sugerencias de producción.
- **Compras, Proveedores, Cuentas por Pagar y Activos Fijos:** Registro transaccional de compras al contado y crédito, gestión de abonos parciales (`PagosCuentaPorPagar`), control de equipamiento y registro de mermas.
- **Seguridad y Respaldos:** Base de datos `pizzaapp_secure.db` cifrada con AES-256 (clave en `FlutterSecureStorage`), copias diarias automáticas y exportación/restauración portátil `.kpzbackup` (AES-256-GCM + PBKDF2 310.000 iteraciones).

---

## Gobernanza Técnica y Documentación

Antes de realizar cualquier modificación en el código o esquema SQLite, consulta obligatoriamente:

1. **[`AGENTS.md`](file:///c:/D/ProyectoPizza/pizzaapp/AGENTS.md):** Constitución técnica del proyecto, las **12 Reglas de Negocio Oficiales (`RN-01` a `RN-12`)**, los **4 Guardrails críticos de SQLite/Seguridad** y el plan de ejecución por fases.
2. **[`kimi_pizza_ai_framework/docs/AUDIT_CONSOLIDATED.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/AUDIT_CONSOLIDATED.md):** Registro consolidado de los 31 hallazgos de auditoría (`C-01` a `C-31`) y hoja de ruta de las Fases 0 a 8.
3. **[`kimi_pizza_ai_framework/docs/BUSINESS_RULES.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/BUSINESS_RULES.md):** Catálogo canónico de reglas de negocio y fórmulas matemáticas.
4. **[`kimi_pizza_ai_framework/README.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/README.md):** Índice completo de la documentación de arquitectura, modelo de datos y casos de prueba.

---

## Comandos de Verificación

```powershell
# Obtener dependencias
flutter pub get

# Ejecutar pruebas automatizadas
flutter test --no-pub

# Ejecutar análisis estático
flutter analyze --no-pub
```
