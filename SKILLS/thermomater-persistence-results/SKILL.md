---
name: thermomater-persistence-results
description: Gestiona la persistencia local, la estructura de carpetas, las sesiones por paciente y la generación de resultados históricos de ThermoMater AI en Flutter. Usa esta skill cuando el usuario pida guardar pacientes, sesiones t0..tN, JSON, imágenes, máscaras, GIFs, gráficas o restauración/borrado de datos.
---

# ThermoMater Persistence and Results

## Goal

Implementar una persistencia local estable y trazable para ThermoMater AI, manteniendo el patrón actual basado en carpetas por paciente y sesiones temporales.

## When to Use

Usa esta skill cuando la tarea incluya:

- guardar pacientes
- crear sesiones `t0..tN`
- persistir `temperaturas.json`
- guardar heatmaps o máscaras de registro
- generar GIF de evolución
- construir datos para gráfica histórica
- borrar datos locales
- reconstruir resultados desde disco

## Do Not Use

No uses esta skill para:

- diseñar la pantalla principal
- correr inferencia del modelo
- programar OCR
- diseñar pruebas end-to-end

## Regla principal de persistencia

Mantén el enfoque **folder-first** del proyecto original.

## Estructura canónica

La estructura base debe conservar este patrón:

```text
ThermoMaterAI/
  Nombre_Apellido/
    patient.json
    Temperaturas/
      t0/
        temperaturas.json
      t1/
        temperaturas.json
    Imagenes/
      t0/
        image.png
      t1/
        image.png
    Registros/
      t0/
        mask.png
      t1/
        mask.png
    Grafica/
      summary.json
      chart_cache.png   # opcional
    anim_imagenes.gif   # opcional
```

También puedes mantener una variante equivalente por sesión si el diseño del código lo exige, pero el resultado final debe ser fácilmente navegable y legible.

## Modelos mínimos

```text
Patient
- id
- firstName
- lastName
- age
- weightKg
- heightCm
- createdAt

AnalysisSession
- sessionIndex
- sessionName
- createdAt
- inputImagePath
- heatmapImagePath
- registrationMaskPath
- temperaturesPath

DermatomeTemperatureRecord
- sessionName
- temperaturesByZone
- minTemp
- maxTemp
```

## Reglas de creación de sesiones

1. La primera sesión es `t0`.
2. Cada nuevo análisis incrementa el índice.
3. No reutilices nombres de sesión.
4. La numeración debe derivarse de las carpetas existentes o del índice persistido.
5. Si hay huecos, no renombres sesiones previas automáticamente.

## Instrucciones de guardado

Cuando se guarde un análisis:

1. asegurar que el paciente exista o permitir crearlo
2. resolver el siguiente nombre de sesión
3. crear directorios necesarios
4. escribir:
   - JSON de temperaturas
   - imagen coloreada
   - máscara o registro
5. actualizar resumen histórico
6. regenerar o marcar para regeneración:
   - GIF
   - datos de gráfica

## Instrucciones de lectura

Cuando el usuario pida resultados:

1. localizar carpeta del paciente
2. descubrir sesiones existentes
3. ordenar por índice temporal
4. reconstruir lista de sesiones
5. cargar datos de gráfica
6. preparar animación histórica si existe o regenerarla

## Borrado de datos

La operación de borrar datos debe:

- ser explícita
- requerir confirmación
- eliminar carpetas del workspace de la app
- restablecer la aplicación a estado inicial
- no dejar referencias huérfanas en memoria

## Reglas de compatibilidad multiplataforma

- Todas las rutas deben salir de un servicio de almacenamiento.
- Nunca hardcodees `/storage/emulated/0`, `Documents/` ni rutas de Android Studio.
- Usa directorios internos de la app.
- Si exportas archivos, separa claramente almacenamiento interno de exportación compartida.

## Generación de resultados históricos

### GIF
- ordenar imágenes por `tN`
- usar duración consistente
- regenerar al agregar nueva sesión o dejar una estrategia de caché válida

### Gráfica
- eje X: `t0..tN`
- eje Y: temperatura promedio
- permitir mostrar u ocultar zonas
- usar una estructura de datos serializable para reconstrucción rápida

## Restricciones

- No guardes solo rutas sin metadatos.
- No mezcles estado temporal de pantalla con persistencia definitiva.
- No uses una base relacional como reemplazo automático del árbol de carpetas.
- No generes nombres de carpetas ambiguos.
- No borres datos ante un error parcial de escritura; implementa manejo transaccional básico o rollback simple.

## Output esperado

Esta skill debe devolver uno o más de los siguientes:

- servicio de almacenamiento
- repositorio de pacientes
- repositorio de sesiones
- serialización JSON
- resolvedor de rutas
- generador de GIF
- adaptador de datos para gráfica histórica
- lógica de borrado seguro

## Example

### Input
“Necesito guardar cada análisis por paciente y sesión, generar el JSON de temperaturas y mostrar la evolución histórica.”

### Output behavior
- crear `StorageService`
- crear `PatientRepository`
- crear `SessionRepository`
- definir estructura `t0..tN`
- guardar artefactos por sesión
- producir datos para GIF y chart
