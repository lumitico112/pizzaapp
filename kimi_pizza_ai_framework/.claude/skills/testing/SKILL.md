---
name: testing
description: Estrategia de pruebas unitarias, de integración y verificación de invariantes matemáticas para KIMI PIZZA.
---

# Skill: Estrategia de Pruebas y Aseguramiento de Calidad (QA)

## 1. Alcance de las Pruebas Obligatorias
Cada componente nuevo o modificado debe acompañarse de pruebas automatizadas:

### Pruebas Unitarias de Dominio (`test/unit/`)
1. **`ConversionesHelper`:**
   - $1 \text{ Kg} = 1000 \text{ g}$ y reciprocidad inversa.
   - $1 \text{ L} = 1000 \text{ ml}$ y reciprocidad inversa.
   - Paquetes a unidades según factor configurado.
   - Manejo de excepciones ante unidades incompatibles (ej. Kg a Litros).
2. **`SugerenciasAlgorithm`:**
   - Promedio de ventas históricas por día de la semana.
   - Ajuste exacto por faltantes (suman) y sobrantes (restan).
   - Invariante: El resultado nunca puede ser menor a 0.
3. **`CajaService`:**
   - Cálculo del efectivo esperado: $\text{Apertura} + \text{Ventas Efectivo} - \text{Salidas Efectivo}$.
   - Determinación del semáforo: Verde ($0$), Rojo ($<0$), Naranja ($>0$).

### Pruebas de Integración con SQLite (`test/integration/`)
1. **Transacciones ACID:**
   - Registro de venta atómica: Confirmar que si falla la generación del PDF o la inserción de la caja, el stock no se descuenta (Rollback total).
2. **Transformaciones de Producto:**
   - Verificar que convertir una pizza no duplica la base física.

## 2. Comandos de Validación Continua
```powershell
flutter analyze --no-pub
flutter test
```
**Criterio de Aceptación:** 0 errores de compilación y 100% de tests unitarios pasando en verde.
