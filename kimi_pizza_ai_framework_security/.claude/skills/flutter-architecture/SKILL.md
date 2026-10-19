---
name: flutter-architecture
description: Revisar y evolucionar la arquitectura Flutter de forma modular, mantenible, testeable, SOLID y sin duplicidad.
---

# Skill: Flutter Architecture

## Objetivo

Mantener una arquitectura coherente por features, con responsabilidades separadas y dependencias controladas.

## Proceso

1. Inspeccionar la estructura actual.
2. Identificar patrón de estado real.
3. Identificar dependencias y servicios compartidos.
4. Localizar lógica de negocio en UI.
5. Detectar duplicidad.
6. Proponer la mínima refactorización necesaria.
7. Mantener APIs internas estables cuando sea posible.
8. Implementar por capas.
9. Revisar imports y dependencias circulares.
10. Ejecutar análisis/tests.

## Reglas

- UI no hace acceso directo a API/DB.
- Dominio no depende de Flutter UI.
- No crear abstracciones sin necesidad real.
- No duplicar modelos equivalentes.
- No mezclar patrones de estado sin justificación.
- Mantener servicios pequeños y especializados.
- Preferir composición a herencia cuando sea apropiado.
- Toda abstracción nueva debe tener una responsabilidad clara.
