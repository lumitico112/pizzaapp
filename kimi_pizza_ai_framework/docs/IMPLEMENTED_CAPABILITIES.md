# Capacidades verificadas y estado de auditoría en KIMI PIZZA POS

**Documento:** IMPLEMENTED-CAPABILITIES-2026-10-V3.0  
**Propósito:** Identificar funciones presentes en el código de la aplicación, enlazarlas con sus especificaciones y dejar trazabilidad explícita de los hallazgos consolidados (`C-01` a `C-31`) en proceso de corrección por fases.  
**Documentos relacionados:** [`AGENTS.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/AGENTS.md), [`AUDIT_CONSOLIDATED.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/AUDIT_CONSOLIDATED.md), [`BUSINESS_RULES.md`](file:///c:/D/ProyectoPizza/pizzaapp/kimi_pizza_ai_framework/docs/BUSINESS_RULES.md).

---

## 1. Criterio de lectura

Este inventario resume los módulos implementados en el repositorio real y señala qué aspectos tienen ajustes programados en el Plan de 8 Fases (`C-01` a `C-31`).

## 2. Funciones operativas presentes y referencias de código

| Área | Función verificada | Referencia de implementación | Reglas / Hallazgos vinculados |
|---|---|---|---|
| Inicio y acceso | Onboarding del administrador, inicio/cierre de sesión y recuperación local con clave de rescate | `lib/screens/auth/`, `lib/services/auth_service.dart`, `lib/services/onboarding_service.dart` | `RN-10`, `C-05` (`bloqueado = 0`), `C-06` (PBKDF2), `C-27` (`Usuario`), `C-30` |
| Usuarios | Crear, editar, bloquear/desbloquear y desactivar/reactivar cuentas (`admin` y `empleado`) | `lib/screens/usuarios/`, `lib/services/usuario_service.dart`, `lib/repositories/usuario_repository.dart` | `RN-10`, `RN-11`, `C-05`, `C-28` |
| Perfil y negocio | Perfil personal en pantalla propia; drawer compacto con Configuración del negocio y Gestión de usuarios solo para admin, más Copias de seguridad | `lib/screens/usuarios/`, `lib/screens/configuracion/configuracion_negocio_screen.dart`, `lib/screens/dashboard/dashboard_screen.dart` | `USERS_CONFIGURATION.md` |
| POS | Catálogo por categorías, variantes, promociones, carrito, cortesías, precio personalizado, ventas históricas y consulta de boletas | `lib/screens/pos/`, `lib/controllers/pos_controller.dart`, `lib/services/pos_service.dart`, `lib/repositories/venta_repository.dart` | `RN-04`, `RN-07`, `C-18` (limpieza de carrito al logout) |
| Efectivo y boleta | Si se indica el efectivo recibido, se persisten pago y vuelto; el PDF desglosa base imponible e IGV incluido al 18 % | `lib/models/venta.dart`, `lib/services/pos_service.dart` | `SALES_PAYMENTS.md` |
| Preparación y sobrantes | Exige caja abierta; muestra sobrantes previos con opciones de traslado o merma y confirma cambios en transacción | `lib/screens/preparacion/`, `lib/features/preparation/data/repositories/preparacion_repository.dart` | `RN-03`, `C-03` (invariante merma/stock), `C-04` (`llevarParaManana` idempotente), `C-10` (`sobrante`) |
| Recetas e inventario | Receta por `variante_id`; convierte `kg`/`g`, `L`/`ml` y `Unidades`/`Paquetes` y registra en kardex mediante `StockMovementWriter` | `lib/screens/catalogo/receta_screen.dart`, `lib/features/inventory/data/stock_movement_writer.dart` | `INVENTORY.md`, `PRODUCT_RECIPES_INVENTORY_PREPARATION.md` |
| Bebida por vaso | La variante “Vaso” de Bebidas consume su receta completa por venta o cortesía: volumen y vaso | `lib/repositories/venta_repository.dart`, `lib/controllers/pos_controller.dart` | `SALES_PAYMENTS.md`, `RN-07` |
| Compras y CxP | Registrar compras de insumos, proveedores, pagos parciales (`PagosCuentaPorPagar`), correcciones y cuentas por pagar | `lib/features/purchases/data/repositories/purchase_repository.dart`, `lib/screens/compras/` | `RN-01` (`C-01`: preservar abonos al editar), `RN-02` (`C-02`: bloqueo de borrado directo de gasto) |
| Activos y mermas | Registrar y gestionar activos, adquisiciones, estados, categorías y mermas de insumos o productos preparados | `lib/features/assets/`, `lib/features/waste/` | `C-07`, `C-09` (`insumo_id = NULL` en activos a crédito), `C-29` |
| Caja y reportes | Sesiones de caja nocturnas por `sesion_caja_id`, arqueo/cierre con `CashCloseSummary`, reportes y panel ejecutivo | `lib/features/cash/domain/entities/cash_close_summary.dart`, `lib/services/caja_service.dart`, `lib/services/reportes_service.dart` | `RN-04` (`C-11`), `RN-05` (`C-15`: priorizar costo de receta), `RN-06` |
| Copias de seguridad | Exportar/restaurar copia portátil `.kpzbackup` cifrada (PBKDF2 310k + AES-256-GCM); copias locales diarias (retención de 7) | `lib/features/backup/application/backup_service.dart`, `lib/main.dart` | `RN-08`, `RN-09`, `C-17` (`Isolate.run`), `C-18`, `C-20` |

## 3. Reglas operativas clave alineadas con las 12 decisiones de negocio

1. **Edición de compras a crédito (`RN-01`):** Preserva todos los abonos registrados en `PagosCuentaPorPagar`, bloquea si el nuevo total es menor a lo ya pagado y ajusta el adelanto inicial sin duplicar gastos ni movimientos de caja.
2. **Gastos de compras y abonos (`RN-02`):** No se eliminan desde la lista genérica de Gastos; los abonos se anulan desde Cuentas por Pagar revirtiendo deuda, gasto y movimiento por ID explícito.
3. **Sobrantes, merma y traslado (`RN-03`):** Cumplen la invariante `enviado_merma + llevado_manana <= cantidad_preparada` y `<= stock_actual`, actualizando `ItemsPreparacion.sobrante = enviado_merma + llevado_manana` para `SugerenciasAlgoritmo`.
4. **Métodos de pago y cuadre (`RN-04`):** `CashCloseSummary` centraliza Efectivo y Digital/Bancario (`yape`, `plin`, `transferencia`, `tarjeta`); `mixto` queda deshabilitado hasta tener desglose de importes.
5. **Costo en reportes (`RN-05`):** Prioriza el costo calculado automáticamente por la receta de la variante sobre `costo_estimado_manual`.
6. **Jornada después de medianoche (`RN-06`):** Regida siempre por `sesion_caja_id`.
7. **Productos al momento (`RN-07`):** Bloqueo estricto si falta receta o stock de insumos.
8. **Backups y Android (`RN-08`, `RN-09`):** Exclusión de `pizzaapp_secure.db` en Android Auto Backup, uso exclusivo de `.kpzbackup` e identidad `com.kimipizza.pos` (**Kimi Pizza POS**).
9. **Acceso y ciclo de vida de usuarios (`RN-10`, `RN-11`):** Login exclusivo por `username` con `activo = 1 AND bloqueado = 0`, etiqueta `Usuario`, y soporte para bloquear/desbloquear y desactivar/reactivar con auditoría.
