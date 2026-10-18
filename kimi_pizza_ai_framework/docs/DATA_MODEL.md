# DICCIONARIO DE DATOS Y MODELO RELACIONAL CANÓNICO — KIMI PIZZA
**Documento:** DATA-MODEL-2026-V3.0  
**Motor:** SQLite 3 con SQLCipher (AES-256) (`sqflite_sqlcipher`)  
**Proyecto:** KIMI PIZZA POS (`com.kimipizza.pos`)  
**Estado:** Modelo relacional sincronizado con la Auditoría Consolidada (`C-07`, `C-08`, `C-09`, `C-16`)  

---

## 1. DICCIONARIO DE DATOS Y NOTA DE SINCRONIZACIÓN FÍSICA (`C-07`, `C-08`, `C-09`)

> **Guardrails de Esquema Verificados en Auditoría:**
> 1. **36 tablas en runtime (`C-08`):** `lib/core/database/db_schema.dart` declara 35 tablas y `lib/core/database/database_helper.dart` crea 1 tabla adicional (`PromocionProductos`) en `onUpgrade`. Además, `ItemsCombo`, `RecuperacionCuenta`, `Proveedores` y `TransferenciasInsumos` están en `db_schema.dart` pero faltaban en migraciones antiguas. En la **Fase 4**, ambos archivos deben quedar 100% alineados en las 36 tablas.
> 2. **Requisito previo a `PRAGMA foreign_keys = ON` (`C-07` / `C-09`):** En el esquema físico actual (`CuentasPorPagar`), `insumo_id` debe migrarse a `INTEGER NULL` (agregando `activo_fijo_id INTEGER NULL`) y eliminando el valor centinela `insumo_id = 0` de `asset_service.dart` **antes** de activar `PRAGMA foreign_keys = ON` en `onConfigure`.
> 3. **Columna `bloqueado` en `Usuarios` (`C-05` / `RN-10`):** La tabla `Usuarios` posee `activo INTEGER DEFAULT 1` y `bloqueado INTEGER DEFAULT 0`. Toda consulta de autenticación debe exigir `activo = 1 AND bloqueado = 0`.

### 1. `configuracion` (Ajustes Globales e Identidad)
Almacena los metadatos corporativos de la pizzería y la ruta del código QR de pagos.
| Campo | Tipo SQL | Nulo | Default | Clave / Restricción | Descripción |
|---|---|---|---|---|---|
| `id` | INTEGER | NO | AUTOINCREMENT | PK | Identificador único de configuración |
| `nombre_negocio` | TEXT | NO | 'KIMI PIZZA' | | Nombre comercial para cabeceras y tickets |
| `ruc` | TEXT | SÍ | NULL | | Número de RUC o identificación tributaria |
| `direccion` | TEXT | SÍ | NULL | | Dirección física del establecimiento |
| `telefono` | TEXT | SÍ | NULL | | Teléfono de contacto / pedidos |
| `mensaje_ticket` | TEXT | SÍ | NULL | | Frase de despedida o agradecimiento en boleta |
| `qr_pago_path` | TEXT | SÍ | NULL | | Ruta local persistente de la imagen QR (Yape/Plin) |
| `updated_at` | TEXT | NO | | | Timestamp ISO8601 de última actualización |

---

### 2. `usuarios` (Control de Acceso y Colaboradores)
| Campo | Tipo SQL | Nulo | Default | Clave / Restricción | Descripción |
|---|---|---|---|---|---|
| `id` | INTEGER | NO | AUTOINCREMENT | PK | Identificador único del usuario |
| `username` | TEXT | NO | | UNIQUE | Alias único para inicio de sesión |
| `password_hash` | TEXT | NO | | | Hash de contraseña con salt |
| `salt` | TEXT | NO | | | Sal criptográfica aleatoria |
| `nombre_completo`| TEXT | NO | | | Nombre y apellidos del colaborador |
| `rol` | TEXT | NO | | CHECK('admin','empleado') | Rol persistido; el formulario presenta al empleado como cajero/preparador |
| `correo` | TEXT | SÍ | NULL | | Correo electrónico de contacto |
| `foto_perfil_path`| TEXT | SÍ | NULL | | Ruta local de la imagen de perfil |
| `recovery_code_hash`| TEXT | SÍ | NULL | | Hash del token de rescate de 24 caracteres |
| `activo` | INTEGER | NO | 1 | CHECK(0 ó 1) | Estado de habilitación (1 = activo, 0 = inactivo)|
| `created_at` | TEXT | NO | | | Timestamp ISO8601 de registro |

---

### 3. `insumos` (Materia Prima e Ingredientes)
| Campo | Tipo SQL | Nulo | Default | Clave / Restricción | Descripción |
|---|---|---|---|---|---|
| `id` | INTEGER | NO | AUTOINCREMENT | PK | Identificador único del insumo |
| `nombre` | TEXT | NO | | UNIQUE | Nombre del insumo (ej. Harina, Queso) |
| `categoria` | TEXT | NO | | | Categoría de insumo |
| `unidad_base` | TEXT | NO | | CHECK('kg','g','l','ml','und','pqte') | Unidad canónica en almacén |
| `contenido_paquete`| REAL | NO | 1.0 | | Unidades contenidas si es paquete |
| `stock_actual` | REAL | NO | 0.0 | | Existencias físicas en tiempo real |
| `stock_minimo` | REAL | NO | 0.0 | | Umbral para alerta de compra |
| `costo_unitario_promedio`| REAL | NO | 0.0 | | Costo promedio ponderado en unidad base |
| `foto_path` | TEXT | SÍ | NULL | | Foto del empaque/insumo |
| `activo` | INTEGER | NO | 1 | | Borrado lógico (1=activo, 0=inactivo) |

---

### 4. `productos` y `variantes_producto` (Catálogo Comercial)
#### Tabla `productos` (Matriz)
| Campo | Tipo SQL | Nulo | Default | Clave / Restricción | Descripción |
|---|---|---|---|---|---|
| `id` | INTEGER | NO | AUTOINCREMENT | PK | Identificador del producto |
| `nombre` | TEXT | NO | | UNIQUE | Nombre (ej. Pizza Margherita) |
| `categoria` | TEXT | NO | | | Categoría de venta |
| `descripcion` | TEXT | SÍ | NULL | | Descripción comercial |
| `imagen_path` | TEXT | SÍ | NULL | | Imagen del producto |
| `activo` | INTEGER | NO | 1 | | Estado de disponibilidad |

#### Tabla `variantes_producto` (Presentaciones de Venta)
| Campo | Tipo SQL | Nulo | Default | Clave / Restricción | Descripción |
|---|---|---|---|---|---|
| `id` | INTEGER | NO | AUTOINCREMENT | PK | Identificador de la variante |
| `producto_id` | INTEGER | NO | | FK -> `productos(id)` | Producto padre |
| `nombre_variante` | TEXT | NO | | | Ej. "Personal 4 Porciones", "Familiar" |
| `precio_venta` | REAL | NO | | | Precio estándar de venta al público |
| `stock` | INTEGER | NO | 0 | | Unidades preparadas listas para venta |

---

### 5. `recetas` (Formulación Escalar)
| Campo | Tipo SQL | Nulo | Default | Clave / Restricción | Descripción |
|---|---|---|---|---|---|
| `id` | INTEGER | NO | AUTOINCREMENT | PK | Identificador del ingrediente en receta |
| `variante_id` | INTEGER | NO | | FK -> `variantes_producto(id)` | Variante a la que aplica |
| `insumo_id` | INTEGER | NO | | FK -> `insumos(id)` | Insumo crudo requerido |
| `cantidad` | REAL | NO | | | Cantidad dosificada |
| `unidad_medida` | TEXT | NO | | | Unidad de formulación (g, ml, und) |
| *Restricción* | | | | UNIQUE(`variante_id`, `insumo_id`) | Regla de no duplicidad de insumo |

---

### 6. `sesiones_caja` y `movimientos_caja` (Gestión Financiera de Turno)
#### Tabla `sesiones_caja`
| Campo | Tipo SQL | Nulo | Default | Clave / Restricción | Descripción |
|---|---|---|---|---|---|
| `id` | INTEGER | NO | AUTOINCREMENT | PK | Identificador de la sesión |
| `fecha_apertura` | TEXT | NO | | | Timestamp ISO8601 de apertura |
| `ciclo_operativo`| TEXT | NO | | | Fecha YYYY-MM-DD del ciclo de negocio |
| `monto_apertura` | REAL | NO | 0.0 | | Fondo de caja inicial para cambio |
| `usuario_apertura_id`| INTEGER | NO | | FK -> `usuarios(id)` | Usuario que abrió el turno |
| `estado` | TEXT | NO | 'abierta' | CHECK('abierta','cerrada','reabierta') | Estado actual de la caja |
| `fecha_cierre` | TEXT | SÍ | NULL | | Timestamp ISO8601 de cierre |
| `usuario_cierre_id`| INTEGER | SÍ | NULL | FK -> `usuarios(id)` | Usuario que cerró el turno |
| `total_efectivo_sistema`| REAL | NO | 0.0 | | Efectivo teórico calculado |
| `total_yape_plin` | REAL | NO | 0.0 | | Total en billeteras digitales del turno |
| `efectivo_contado`| REAL | NO | 0.0 | | Dinero físico contado (Arqueo ciego) |
| `diferencia` | REAL | NO | 0.0 | | $Contado - Esperado$ |
| `nota_cierre` | TEXT | SÍ | NULL | | Explicación de descuadres |

#### Tabla `movimientos_caja`
| Campo | Tipo SQL | Nulo | Default | Clave / Restricción | Descripción |
|---|---|---|---|---|---|
| `id` | INTEGER | NO | AUTOINCREMENT | PK | Identificador del movimiento |
| `sesion_caja_id` | INTEGER | NO | | FK -> `sesiones_caja(id)` | Sesión a la que pertenece |
| `tipo` | TEXT | NO | | CHECK('entrada','salida','venta','compra','apertura') | Tipo de flujo |
| `metodo_pago` | TEXT | NO | | CHECK('efectivo','yape','plin','tarjeta') | Canal financiero |
| `monto` | REAL | NO | | | Valor monetario del movimiento |
| `descripcion` | TEXT | SÍ | NULL | | Concepto o justificación |
| `fecha` | TEXT | NO | | | Timestamp ISO8601 del movimiento |

---

### 7. `ventas` y `detalle_ventas` (Facturación)
#### Tabla `ventas`
| Campo | Tipo SQL | Nulo | Default | Clave / Restricción | Descripción |
|---|---|---|---|---|---|
| `id` | INTEGER | NO | AUTOINCREMENT | PK | Identificador de venta correlativo |
| `fecha` | TEXT | NO | | | Timestamp ISO8601 de la venta |
| `ciclo_operativo`| TEXT | NO | | | Fecha del ciclo operativo |
| `sesion_caja_id` | INTEGER | NO | | FK -> `sesiones_caja(id)` | Sesión de caja en que se cobró |
| `usuario_id` | INTEGER | NO | | FK -> `usuarios(id)` | Cajero que cobró la venta |
| `subtotal` | REAL | NO | | | Suma de subtotales de ítems |
| `descuento` | REAL | NO | 0.0 | | Descuento total aplicado |
| `total` | REAL | NO | | | Importe final cobrado al cliente |
| `metodo_pago` | TEXT | NO | | CHECK('efectivo','yape','plin','tarjeta','mixto') | Método de pago principal |
| `monto_recibido` | REAL | SÍ | NULL | | Efectivo entregado por cliente |
| `vuelto` | REAL | NO | 0.0 | | Cambio retornado al cliente |
| `boleta_pdf_path`| TEXT | SÍ | NULL | | Ruta física permanente del PDF |
| `nota` | TEXT | SÍ | NULL | | Observación general de la orden |

#### Tabla `detalle_ventas`
| Campo | Tipo SQL | Nulo | Default | Clave / Restricción | Descripción |
|---|---|---|---|---|---|
| `id` | INTEGER | NO | AUTOINCREMENT | PK | Identificador del ítem vendido |
| `venta_id` | INTEGER | NO | | FK -> `ventas(id)` | Venta a la que pertenece |
| `variante_id` | INTEGER | SÍ | NULL | FK -> `variantes_producto(id)` | Variante vendida (si aplica) |
| `promocion_id` | INTEGER | SÍ | NULL | FK -> `promociones(id)` | Promoción vendida (si aplica) |
| `cantidad` | INTEGER | NO | 1 | | Cantidad de unidades vendidas |
| `precio_unitario`| REAL | NO | | | Precio cobrado por unidad |
| `subtotal` | REAL | NO | | | $\text{cantidad} \times \text{precio\_unitario}$ |
| `es_cortesia` | INTEGER | NO | 0 | CHECK(0 ó 1) | 1 = Cortesía sin cobro (S/ 0.00) |
| `nota_item` | TEXT | SÍ | NULL | | Instrucción especial (ej. sin cebolla) |

---

## 2. ESTRATEGIA DE ÍNDICES PARA ALTO RENDIMIENTO

Para garantizar lecturas instantáneas en el POS y generación de reportes en menos de 100 ms:
```sql
CREATE INDEX IF NOT EXISTS idx_ventas_ciclo ON ventas(ciclo_operativo);
CREATE INDEX IF NOT EXISTS idx_ventas_sesion ON ventas(sesion_caja_id);
CREATE INDEX IF NOT EXISTS idx_detalle_ventas_venta ON detalle_ventas(venta_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_sesion ON movimientos_caja(sesion_caja_id);
CREATE INDEX IF NOT EXISTS idx_recetas_variante ON recetas(variante_id);
CREATE INDEX IF NOT EXISTS idx_items_prep_sesion ON items_preparacion(preparacion_id);
CREATE INDEX IF NOT EXISTS idx_cuentas_pagar_estado ON cuentas_por_pagar(estado);
```
