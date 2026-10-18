---
name: flutter-refactoring
description: Directivas para refactorización de código sin regresiones, extracción de componentes de UI, simplificación de métodos extensos y principio DRY.
---

# Skill: Refactorización y Deuda Técnica Flutter

## 1. Principio Fundamental
**La refactorización mejora la estructura interna del software sin alterar su comportamiento observable externo.**

## 2. Indicadores de Necesidad de Refactorización (Code Smells)
- Archivos de pantalla con más de 400 líneas de código.
- Métodos `build()` gigantes con árboles anidados de más de 5 niveles.
- Widgets duplicados con ligeras variaciones de color o tamaño.
- Cálculos matemáticos o consultas a base de datos dentro de clases `StatefulWidget`.

## 3. Protocolo de Refactorización Segura
1. **Verificación Previa:** Ejecutar `flutter analyze` y `flutter test` para validar el estado verde antes de iniciar.
2. **Extracción Anatómica:**
   - Extraer widgets de tarjetas, listas o diálogos a `widgets/` dedicados dentro de la feature correspondiente.
   - Pasar dependencias mediante constructor o usar `Provider`.
3. **Verificación Posterior:** Confirmar que no se introdujeron advertencias o errores y que los tests siguen pasando.
