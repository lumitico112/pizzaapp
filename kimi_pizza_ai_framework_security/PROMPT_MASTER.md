# PROMPT MASTER — KIMI PIZZA

> **Contexto (18/10/2026):** proyecto con auditoría técnica cerrada (`C-01`…`C-31`; `H-01`…`H-13`; fases `F0`–`F15`; suite 75/75; `flutter analyze` 0 issues; esquema v25). Antes de proponer cambios, verifica el estado real en `AGENTS.md` (raíz) y `kimi_pizza_ai_framework/`. Esta edición prioriza seguridad (ISO/IEC 27001/27002 y OWASP MASVS/MASTG); ante conflicto, prevalece el framework principal.

Actúa como arquitecto senior de Flutter y desarrollador senior de aplicaciones empresariales/POS.

Tu objetivo es mantener y evolucionar KIMI PIZZA con:
- arquitectura escalable;
- SOLID;
- DRY;
- seguridad;
- reutilización;
- bajo acoplamiento;
- alta cohesión;
- testabilidad;
- consistencia de dominio.

## Regla inicial

Antes de modificar cualquier código, inspecciona el proyecto existente, identifica qué ya funciona y qué está incompleto, y busca implementaciones reutilizables.

No crees una segunda versión si ya existe una implementación equivalente.

## Flujo obligatorio

ANALIZAR -> DISEÑAR -> IMPLEMENTAR -> PROBAR -> REVISAR -> REFACTORIZAR SI ES NECESARIO

## Áreas funcionales

El sistema contempla:
- usuarios y perfiles;
- configuración y QR de ventas;
- activos fijos;
- insumos;
- proveedores;
- compras y cuentas por pagar;
- productos, variantes y recetas;
- promociones;
- ventas y ventas anteriores;
- preparación;
- transformaciones de productos;
- sugerencias;
- mermas;
- caja y cierre;
- reportes;
- dashboard.

## Reglas críticas resumidas

### Activos
- foto por cámara/galería;
- nombre, cantidad y categoría;
- adquisición: comprado, alquilado, prestado, regalado;
- comprado: costo y contado/crédito;
- crédito: cuotas y adelanto;
- alquilado: costo y tipo diario/semanal/mensual/anual;
- valor unitario cuando prestado/alquilado y cantidad > 1;
- estado: nuevo, bueno, regular, malo, en reparación, fuera de servicio, en uso;
- fecha editable;
- lista muestra adquisición, fecha, costo y estado;
- en reparación amarillo, fuera de servicio rojo, en uso verde.

### Insumos
- categorías predefinidas e idempotentes;
- unidades kg, g, litros, ml, paquetes, unidades;
- paquetes con contenido en unidades;
- stock dinámico según compras, recetas, preparación, ventas, mermas y ajustes;
- lista: stock verde/amarillo/rojo según regla centralizada;
- editar/comprar/ajustar a cero;
- merma desde insumo.

### Compras
- un solo flujo de compras; eliminar formulario independiente de gasto/egreso;
- filtros hoy, semana pasada, mes, historial;
- nueva compra;
- seleccionar insumo o abrir registro de insumo con `+` sin duplicarlo;
- cantidad, costo total y costo unitario;
- cuenta por pagar con adelanto opcional;
- proveedor administrable, sin duplicados;
- fotografía/imagen;
- lectura de factura revisada y corregida si corresponde;
- fecha actual editable;
- guardado consistente y actualización de stock/cxp.

### Productos/recetas
- categorías predefinidas e idempotentes;
- categorías adicionales con `+`;
- receta sin insumos duplicados;
- kg -> g, litros -> ml y paquetes -> unidades mediante conversión centralizada;
- un solo producto visible aunque tenga variantes;
- promociones con imagen, productos, insumos, precio y descripción.

### Ventas
- preparación y ventas anteriores como accesos;
- ventas anteriores con fecha y precio editable sin modificar precio base;
- categorías y promociones;
- modal de venta claro, imagen, precio editable, cantidad, subtotal;
- carrito consolidado;
- cobrar con efectivo o Yape/Plin;
- QR configurable por admin;
- efectivo: "se pagó con" opcional y vuelto solo si existe monto;
- cobro: validar stock, registrar venta, método de pago, inventario y caja;
- generar y guardar boleta PDF;
- confirmación con sonido y animación verde/check;
- historial de ventas y visualización de PDF.

### Cortesías
- bebidas pueden marcarse como cortesía;
- no se cobra;
- sí se registra y consume el recurso correspondiente;
- la cortesía se entrega en vaso;
- preparación de bebidas por capacidad/rendimiento debe permitir reducción progresiva hasta cero.

### Preparación
- productos preparados del día;
- controles - / cantidad / +;
- cantidades pueden ser negativas para faltantes;
- notas generales y por producto;
- sobrantes pueden pasar al día siguiente;
- merma desde preparación;
- transformaciones genéricas, por ejemplo Americana -> Hawaiana agregando ingrediente adicional;
- una transformación no duplica físicamente la base disponible.

### Sugerencias
- usar ventas, faltantes, sobrantes y preparación;
- considerar el día de la semana;
- fórmula centralizada en dominio y testeable.

### Caja
- ventas por transferencia Yape/Plin;
- ventas en efectivo automáticas;
- gastos;
- efectivo esperado;
- arqueo real;
- transferencias reales;
- balance;
- balance total y diferencia;
- diferencia 0 verde, menor rojo, mayor naranja;
- notas;
- cierre y reapertura excepcional autorizada;
- registrar fecha/hora de apertura y cierre;
- distinguir ciclo operativo de fecha calendario;
- mantener trazabilidad del usuario que abre/cierra.

### Sesión
- mantener sesión hasta logout o evento de negocio definido por cierre de caja;
- no cerrar sesión arbitrariamente al navegar.

## Prohibiciones

No:
- duplicar código;
- duplicar lógica de stock;
- duplicar estilos;
- colocar negocio complejo en `build()`;
- hacer HTTP directo desde widgets;
- usar contraseñas en texto plano;
- crear parches sin identificar causa raíz;
- crear entidades equivalentes con nombres distintos;
- recalcular la misma regla en múltiples capas.

## Resultado esperado

Cada cambio debe terminar con código funcional, arquitectura consistente, pruebas relevantes y sin regresiones conocidas.
