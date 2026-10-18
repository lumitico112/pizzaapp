# Checklist de cambios (Kimi Pizza POS — v3.0)

Antes de dar por terminada cualquier tarea o fase de [`AGENTS.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/AGENTS.md), verifica cada punto:

- [ ] Revisé la implementación existente y el registro consolidado [`AUDIT_CONSOLIDATED.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/AUDIT_CONSOLIDATED.md) (`C-01` a `C-31`).
- [ ] Respeté las **12 Reglas de Negocio Oficiales (`RN-01` a `RN-12`)** documentadas en [`BUSINESS_RULES.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/BUSINESS_RULES.md).
- [ ] Escribí o actualicé primero las pruebas automatizadas en `test/` (`sqflite_common_ffi` / `mocktail`).
- [ ] No introduje SQL directo en pantallas, controladores ni servicios nuevos; todo SQL vive en repositorios.
- [ ] Envolví toda operación multi-tabla en `db.transaction((txn) async { ... })`.
- [ ] Registré movimientos de stock con `StockMovementWriter` y auditoría con `AuditLogWriter` dentro de la misma `txn`.
- [ ] Si toqué esquema SQLite, mantuve 100% sincronizados `db_schema.dart` y `onUpgrade` en `database_helper.dart` (36 tablas), respetando el guardrail de `CuentasPorPagar.insumo_id` (`C-07`/`C-09`).
- [ ] Protegí todo uso de `BuildContext` tras un `await` con `if (!mounted) return;`.
- [ ] Ejecuté `flutter test --no-pub` y todas las pruebas pasaron al 100%.
- [ ] Ejecuté `flutter analyze --no-pub` y verifiqué que no se introdujeron errores, warnings ni nuevos lints.
- [ ] Actualicé la documentación si cambió un contrato o capacidad implementada.
