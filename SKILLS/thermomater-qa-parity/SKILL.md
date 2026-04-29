---
name: thermomater-qa-parity
description: Verifica que la versión Flutter conserve la paridad funcional de ThermoMater AI y define pruebas de calidad por módulo. Usa esta skill cuando el usuario pida criterios de aceptación, test plans, regresión funcional, validación de pantallas, validación del pipeline o checklist final antes de cerrar tareas.
---

# ThermoMater QA and Parity

## Goal

Evitar que la migración a Flutter pierda comportamiento clínico o funcional frente a la app original.

## When to Use

Usa esta skill cuando la tarea sea:

- definir criterios de aceptación
- escribir pruebas unitarias, widget o integración
- validar que una pantalla quedó igual en comportamiento
- revisar paridad del pipeline de análisis
- revisar persistencia de sesiones
- hacer checklist final antes de cerrar una feature

## Do Not Use

No uses esta skill como skill principal para:

- implementar la arquitectura desde cero
- escribir la lógica del modelo
- definir navegación inicial
- diseñar assets o branding

## Regla central

Toda feature nueva debe compararse con el comportamiento esperado del proyecto existente, no solo con el diseño propuesto por el desarrollador.

## Áreas de prueba obligatorias

### 1. Pacientes
Comprobar:

- creación de paciente
- edición de paciente
- eliminación con confirmación
- persistencia de datos
- apertura de detalle

### 2. Análisis
Comprobar:

- selección de imagen
- lectura de temperatura mínima y máxima
- corrección manual del rango
- ejecución del análisis
- visualización del heatmap
- listado de temperaturas por zona
- guardado del análisis

### 3. Resultados
Comprobar:

- carga de sesiones previas
- orden temporal `t0..tN`
- GIF de evolución
- gráfica interactiva
- visibilidad de zonas por filtro

### 4. Configuración
Comprobar:

- cambio de idioma en caliente
- borrado de datos con confirmación
- restauración del estado inicial

### 5. Base de datos
Comprobar:

- navegación de casos
- apertura de imágenes y máscaras
- separación respecto a datos reales de pacientes

## Tipos de pruebas esperadas

### Unit tests
Para:
- parseo OCR
- validación de rango térmico
- numeración de sesiones
- cálculo de datasets para gráfica
- serialización JSON

### Widget tests
Para:
- formularios
- diálogos de confirmación
- lista de pacientes
- lista de temperaturas
- pantalla de resultados

### Integration tests
Para:
- crear paciente -> analizar -> guardar -> revisar resultados
- cambiar idioma -> volver a pantallas previas
- borrar datos -> comprobar estado limpio

## Criterios de aceptación por feature

Cada respuesta de esta skill debe producir criterios verificables con formato como este:

```text
Dado ...
Cuando ...
Entonces ...
```

Ejemplo:

- Dado que el usuario selecciona una imagen válida,
- Cuando confirma el rango térmico y pulsa Start,
- Entonces la app debe mostrar el heatmap y la lista de temperaturas por dermatoma.

## Instrucciones de revisión

1. Lee la feature solicitada.
2. Relaciónala con uno de los módulos principales.
3. Escribe:
   - criterios de aceptación
   - casos felices
   - casos de error
   - datos de prueba
4. Si hay persistencia, incluye validación en disco.
5. Si hay localización, verifica ambos idiomas.
6. Si hay análisis, verifica también artefactos generados.

## Casos borde mínimos

Siempre considera estos casos:

- OCR no detecta temperaturas
- solo se detecta un pie
- imagen corrupta o ruta inexistente
- carpeta del paciente vacía
- paciente sin sesiones
- intento de borrar datos sin confirmación
- cambio de idioma durante navegación
- sesión histórica con archivo faltante

## Restricciones

- No aceptes una feature como completa solo porque “compila”.
- No uses criterios ambiguos como “se ve bien”.
- No cierres tareas sin evidencia de resultado esperado.
- No ignores iOS cuando una decisión afecte permisos o archivos.

## Output esperado

Esta skill debe devolver:

- checklist de aceptación
- plan de pruebas
- casos Given/When/Then
- matriz de regresión
- criterios de done
- lista de edge cases
- sugerencias de instrumentación o logs

## Example

### Input
“Terminé la pantalla de análisis y el guardado, ayúdame a validar que sí reemplaza a la app vieja.”

### Output behavior
- listar criterios de aceptación
- cubrir OCR, corrección manual, Start, heatmap, guardado y sesiones
- proponer integration tests
- exigir revisión de archivos generados y lectura posterior
