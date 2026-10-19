---
name: sales-cash-flow
description: Guía de ingeniería para el flujo integral de Ventas (POS), Carrito, Cortesías, Cobros, Boletas PDF, Sesiones de Caja, Arqueo Ciego y Ciclo Nocturno.
---

# Skill: Flujo de Ventas, POS, Boletas y Control de Caja

## 1. Documentación Obligatoria de Referencia
1. `PROMPT_MASTER.md` — Módulos 10, 11 y 13.
2. `docs/SRS.md` — Requisitos FR-035 a FR-054.
3. `docs/SDD.md` — Secciones 2.2, 4 y 5.3.
4. `docs/BUSINESS_RULES.md` — Reglas BR-POS-01 a BR-CSH-05.

## 2. Invariantes Críticas de Ventas y POS
1. **Validación de Caja Abierta:** Antes de añadir productos o cobrar, verificar que `CajaController.tieneCajaAbierta == true`. Si está cerrada, redirigir o mostrar modal de apertura de turno.
2. **Independencia de Precios:** La modificación del precio de un ítem en el carrito para un cliente específico jamás debe alterar el valor en la tabla `variantes_producto`.
3. **Cortesías:** Ítems marcados como cortesía se registran a S/ 0.00 y descuentan el recurso inventariable según el tipo de producto: stock preparado o receta.
4. **Bebidas por vaso:** Para una variante de Bebidas con nombre `Vaso`, consumir por venta o cortesía el volumen de la receta en ml/litros y una unidad del insumo vaso. Si falta cualquiera de los dos componentes, bloquear antes de finalizar inventario.
5. **Validación de Pago en Efectivo:** Si se ingresa "Se pagó con", validar que $\text{Monto Recibido} \ge \text{Total Venta}$. Calcular y mostrar el vuelto.
6. **Persistencia Determinística de Boletas:** Guardar siempre el archivo en:
   `getApplicationDocumentsDirectory()/boletas/boleta_{ventaId}.pdf`.
   Nunca utilizar carpetas temporales volátiles para comprobantes de pago.
7. **Detalle de boleta:** Si se capturó monto recibido, mostrar `Pago con` y `Vuelto`. Desglosar el IGV incluido al 18 % con `IGV = total × 18 / 118`.
8. **Feedback Sensorial:** Tras confirmar el cobro:
   - Reproducir sonido local empaquetado en assets (`assets/sounds/...`). Prohibido usar URLs de internet.
   - Mostrar animación Lottie de éxito (Check).
   - Ofrecer botones directos: "Ver Boleta" (`OpenFilex.open`) y "Descargar / Compartir" (`SharePlus.instance.share`).

## 3. Invariantes Críticas de Sesiones de Caja
1. **Prevalencia del Ciclo Operativo:** Una caja abierta el viernes a las 19:00 y cerrada el sábado a las 02:30 AM pertenece al ciclo del viernes. El campo `ciclo_operativo` debe asignarse en la apertura y respetarse en todas las ventas y gastos.
2. **Arqueo Ciego:** En la pantalla de cierre, el cajero debe ingresar el dinero físico contado (`efectivo_contado`) sin que el sistema le revele el monto teórico esperado.
3. **Semáforo Financiero de Arqueo:**
   - $\text{Diferencia} = 0.00 \implies$ Tarjeta Verde ("Caja Cuadrada").
   - $\text{Diferencia} < 0.00 \implies$ Tarjeta Roja ("Faltante de Caja").
   - $\text{Diferencia} > 0.00 \implies$ Tarjeta Naranja ("Sobrante de Caja").
4. **Reapertura Excepcional:** Solo un usuario con rol `admin` puede reabrir una caja cerrada, registrando motivo y trazabilidad de auditoría.
