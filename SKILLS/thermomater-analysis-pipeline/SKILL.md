---
name: thermomater-analysis-pipeline
description: Implementa y protege el pipeline de análisis termográfico de ThermoMater AI en Flutter. Usa esta skill cuando el usuario pida OCR de temperaturas, segmentación de pies, registro de dermatomas, cálculo de temperaturas promedio, heatmaps, validación clínica o guardado técnico del análisis.
---

# ThermoMater Analysis Pipeline

## Goal

Construir el pipeline completo de análisis para imágenes termográficas de pies manteniendo la lógica del proyecto original y desacoplando cada etapa para que pueda ejecutarse y probarse de forma independiente.

## When to Use

Activa esta skill cuando la tarea incluya:

- capturar o seleccionar una imagen termográfica
- extraer temperatura mínima y máxima visibles en la imagen
- validar o corregir manualmente esas temperaturas
- correr inferencia del modelo `.tflite`
- separar pie derecho y pie izquierdo
- registrar plantillas de dermatomas sobre la máscara segmentada
- calcular temperaturas promedio por dermatoma
- generar mapa de calor, máscara registrada y JSON de resultados

## Do Not Use

No uses esta skill como skill principal para:

- dibujar la pantalla de Pacientes
- definir navegación global
- estructurar almacenamiento por carpetas
- diseñar pruebas finales de aceptación

## Suposiciones fijas del sistema

La lógica debe respetar estas reglas:

- La imagen de entrada es termográfica.
- La segmentación identifica pies/extremidades inferiores en la imagen.
- El OCR estima temperatura máxima y mínima visibles en la captura.
- Si las temperaturas detectadas son menores de 15 °C o mayores de 40 °C, la interfaz debe pedir revisión manual.
- El resultado final debe incluir 10 zonas:
  - Medial PD
  - Medial PI
  - Lateral PD
  - Lateral PI
  - Sural PD
  - Sural PI
  - Tibial PD
  - Tibial PI
  - Saphenous PD
  - Saphenous PI
- Debe existir una salida visual coloreada y una salida estructurada en datos.

## Contrato del pipeline

Implementa el análisis con este orden:

1. `loadInputImage`
2. `extractVisibleTemperatureRange`
3. `validateOrRequestManualRange`
4. `runSegmentationModel`
5. `extractFeetRois`
6. `registerDermatomeTemplates`
7. `buildTemperatureMap`
8. `computeDermatomeAverages`
9. `renderHeatmapAndContours`
10. `serializeAnalysisArtifacts`

## Diseño obligatorio

### 1. OCR como etapa separada

- El OCR no puede quedar mezclado con la inferencia del modelo.
- El OCR devuelve:
  - texto crudo detectado
  - números parseados
  - `minTemp`
  - `maxTemp`
  - banderas de confianza o error
- Si no logra detectar valores confiables, debe habilitar corrección manual.

### 2. Inference service separado

- El servicio de inferencia solo recibe la imagen preprocesada.
- El servicio devuelve la máscara del pie o pies.
- El servicio no debe escribir archivos ni mostrar UI.

### 3. Registro dermatómico separado

- La lógica de registro no rígido debe quedar en un servicio específico.
- El servicio recibe:
  - máscara segmentada
  - plantilla de pie derecho
  - plantilla de pie izquierdo
- El servicio devuelve:
  - dermatomas registrados
  - contornos
  - coordenadas o metadatos de región

### 4. Cálculo térmico separado

- El mapeo de temperatura debe convertir valores de la imagen a una escala usando `minTemp` y `maxTemp`.
- El cálculo por zona debe devolver un diccionario o lista tipada.
- Nunca guardes solo texto suelto: guarda modelos de datos.

## Modelos mínimos sugeridos

```text
ThermalRange
- minTemp
- maxTemp
- source
- wasManuallyCorrected

SegmentationResult
- maskPath or maskBytes
- rightFootBounds
- leftFootBounds

DermatomeTemperature
- zoneCode
- zoneName
- footSide
- meanTemperature

AnalysisArtifacts
- heatmapPath
- registrationMaskPath
- temperaturesJsonPath
- summary
```

## Instrucciones de implementación

1. Cuando el usuario pida código del análisis, divide la tarea en servicios.
2. Conserva los nombres clínicos de las zonas.
3. Mantén la lógica de validación manual del rango térmico.
4. Siempre genera un resultado estructurado, no solo visual.
5. Si el usuario pide refactor, conserva los contratos de datos.
6. Si la inferencia falla:
   - no inventes temperaturas
   - devuelve error controlado
   - sugiere reintento o revisión de imagen

## Validaciones obligatorias

Antes de considerar terminado un flujo de análisis, comprueba:

- existe imagen de entrada
- existen `minTemp` y `maxTemp`
- `minTemp < maxTemp`
- hay al menos una máscara válida
- se calcularon temperaturas para las zonas detectadas
- se pudo renderizar el heatmap o se generó un error explícito
- el resultado es guardable

## Reglas de UI ligadas a esta skill

Cuando esta skill genere lógica conectada a UI:

- mostrar vista previa de la imagen
- mostrar temperaturas detectadas
- abrir corrección manual si el rango es dudoso
- no correr el pipeline hasta que el usuario confirme el rango
- mostrar loader y estado por etapa
- al finalizar, mostrar heatmap y lista de temperaturas

## Restricciones

- No hardcodees la ruta de archivos como si solo existiera Android.
- No mezcles parseo OCR con widgets.
- No uses nombres genéricos como `temp1`, `temp2`, `mask1`.
- No descartes el registro no rígido solo por simplificar.
- No cambies los nombres de dermatomas sin orden clínica explícita.

## Output esperado

La respuesta debe producir uno o más de los siguientes:

- servicios Dart del pipeline
- interfaces para OCR e inferencia
- modelos de dominio
- pseudocódigo de la cadena de análisis
- implementación de parsing/validación
- contratos de errores y estados
- checklist de paridad con la app original

## Example

### Input
“Haz el servicio que procesa una imagen térmica, corre el modelo y devuelve el heatmap con las temperaturas por dermatoma.”

### Output behavior
- crear `ThermalAnalysisService`
- delegar OCR a `TemperatureRangeOcrService`
- delegar inferencia a `FootSegmentationService`
- delegar registro a `DermatomeRegistrationService`
- devolver `AnalysisArtifacts` + lista `DermatomeTemperature`
