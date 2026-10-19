# Skill: purchases-assets-waste-reporting

## Purpose

Usar esta Skill al corregir, implementar o refactorizar funcionalidades relacionadas con compras, proveedores, cuentas por pagar, activos fijos, mermas o reportes.

## Mandatory references

Antes de tocar código, leer:
- `AGENTS.md`
- `docs/PURCHASES_SUPPLIERS_PAYABLE_ASSETS_WASTE_REPORTS.md`
- `docs/PURCHASES_ASSETS_WASTE_TEST_CASES.md`
- `docs/INVENTORY.md`
- `docs/CASH_FLOW.md`
- `docs/DATA_MODEL.md`
- `docs/BUSINESS_RULES.md`

Si el cambio afecta preparación/ventas, leer también:
- `docs/PRODUCT_RECIPES_INVENTORY_PREPARATION.md`
- `docs/SALES_PAYMENTS.md`

## Workflow

### 1. Discover

Inspeccionar el repositorio antes de editar.
Buscar:
- Purchase / PurchaseItem;
- Supplier;
- Payable / Accounts Payable;
- Asset / FixedAsset;
- Waste / Merma;
- StockMovement;
- report services/repositories;
- providers/controllers/notifiers;
- formularios y widgets compartidos.

### 2. Trace

Seguir el flujo desde UI hasta persistencia.
Identificar dónde se produce cada efecto lateral.

### 3. Root cause

Si hay bug, encontrar la causa raíz antes de modificar.
Determinar si es:
- duplicación;
- doble evento;
- estado inconsistente;
- persistencia parcial;
- cálculo duplicado;
- problema de transacción;
- problema de permisos;
- error de fechas;
- problema de integración con inventario/caja.

### 4. Implement

Modificar la capa correcta.
No sumar/restar stock desde la UI.
No crear un proveedor embebido en una compra.
No crear una segunda lógica de cuentas por pagar.
No crear un sistema de merma alternativo.
No duplicar cálculos de reportes.

### 5. Verify

Ejecutar los casos de prueba relevantes.
Comprobar especialmente:
- una compra = un movimiento;
- una merma = un movimiento;
- una deuda = un saldo consistente;
- una operación histórica = datos preservados;
- reportes = mismos valores que la fuente transaccional.

### 6. Regression

Revisar efectos en:
- inventario;
- preparación;
- ventas;
- caja;
- reportes;
- seguridad;
- auditoría.

### 7. Final quality gate

Antes de terminar:
- no duplicidad;
- SOLID;
- DRY;
- tipado fuerte;
- estados de UI correctos;
- manejo de errores;
- doble submit protegido;
- seguridad revisada;
- pruebas relevantes ejecutadas.
