---
name: thermomater-ui-flows
description: Diseña y genera las pantallas, navegación y microflujos de ThermoMater AI en Flutter. Usa esta skill cuando el usuario pida construir o refinar la interfaz, formularios, validaciones, estados de pantalla, navegación inferior, detalles de pacientes, análisis o resultados.
---

# ThermoMater UI Flows

## Goal

Reproducir en Flutter la navegación y los flujos de ThermoMater AI con una interfaz clara, bilingüe y fiel a la operación clínica del sistema original.

## When to Use

Usa esta skill cuando el usuario pida:

- home dashboard
- bottom navigation
- formularios de pacientes
- flujo de análisis
- pantallas de resultados
- base de datos de casos
- configuración e internacionalización visible
- diálogos de confirmación y borrado
- estados vacíos, errores o loaders

## Do Not Use

No uses esta skill para:

- implementar el algoritmo del heatmap
- decidir persistencia de archivos
- diseñar pruebas de regresión
- escoger librerías de inferencia

## Estructura funcional obligatoria

La app debe incluir, como mínimo:

### Pantalla principal
Cuatro accesos principales:

- Pacientes
- Análisis
- Resultados
- Base de datos

### Barra inferior fija
Tres accesos persistentes:

- Ayuda
- Inicio
- Configuración

### Configuración
Debe permitir:

- cambiar idioma entre español e inglés
- borrar datos locales con confirmación explícita

## Flujos que debes preservar

### 1. Pacientes
- listado de pacientes
- crear paciente
- editar paciente
- ver información
- eliminar paciente con confirmación

Campos mínimos del paciente:
- nombre
- apellido
- edad
- peso
- estatura

### 2. Análisis
- seleccionar o cargar imagen termográfica
- mostrar la imagen elegida
- mostrar `minTemp` y `maxTemp`
- pedir validación/corrección manual si el rango es dudoso
- botón de inicio del análisis
- pantalla de resultado con heatmap y lista de temperaturas
- opciones finales:
  - nueva imagen
  - guardar

### 3. Resultados
- seleccionar paciente
- listar sesiones
- ver GIF de evolución
- ver gráfica histórica
- acceder a detalles por sesión

### 4. Base de datos
- explorar casos de ejemplo
- navegar imágenes y máscaras
- mantenerlo como módulo separado del flujo clínico real

## Reglas de diseño

1. **Claridad operativa**
   - La interfaz debe ser simple para un entorno clínico.
   - Evita pantallas saturadas.

2. **Un paso por pantalla cuando sea posible**
   - Formularios separados de resultados
   - Validaciones visibles
   - Acciones críticas confirmadas

3. **Mensajes explícitos**
   - Error de OCR
   - Imagen inválida
   - No se detectaron ambos pies
   - Guardado exitoso
   - Eliminación de datos

4. **Bilingüe desde el primer commit**
   - No dejes strings quemados en widgets.
   - Toda cadena debe salir de localización.

## Instrucciones de implementación

1. Si el usuario pide una pantalla, primero ubícala en el flujo correcto.
2. Construye la UI usando widgets reutilizables.
3. Mantén formularios y validación desacoplados.
4. Usa estados bien definidos:
   - idle
   - loading
   - success
   - error
5. Si una pantalla depende del análisis, no calcules nada en el widget.
6. Si una acción borra datos, exige confirmación.
7. Si una lista está vacía, muestra estado vacío útil.

## Widgets recomendados

Crea componentes reutilizables como:

- `MainModuleCard`
- `BottomActionBar`
- `PatientFormFields`
- `ThermalRangeReviewCard`
- `AnalysisPrimaryAction`
- `DermatomeTemperatureList`
- `HistoricalChartCard`
- `DangerConfirmationDialog`

## Checklist por pantalla

### Home
- título de la app
- cuatro accesos grandes
- navegación inferior visible

### Pacientes
- botón crear paciente
- lista de pacientes
- menú contextual por paciente
- acceso a detalle

### Análisis
- selector/cargador de imagen
- preview
- rango térmico detectado
- acción de corrección
- botón iniciar análisis

### Resultado de análisis
- heatmap
- lista de temperaturas
- acción guardar
- acción nueva imagen

### Resultados
- selector de paciente
- GIF
- gráfica
- acceso a sesiones previas

### Configuración
- idioma
- borrar datos

## Restricciones

- No cambies el nombre de los módulos principales.
- No ocultes el cambio de idioma en una zona difícil de encontrar.
- No combines “guardar” y “analizar” en un solo botón.
- No dispares borrado de datos sin confirmación.
- No metas texto clínico importante dentro de imágenes.

## Output esperado

Esta skill debe producir:

- pantallas Flutter
- rutas y navegación
- widgets reutilizables
- estados de pantalla
- formularios con validación
- textos de UX e internacionalización
- flujos de diálogo y confirmación

## Example

### Input
“Haz la pantalla de análisis con selección de imagen, vista previa, temperaturas detectadas y botón Start.”

### Output behavior
- crea un `AnalysisScreen`
- separa estado y UI
- incluye preview de imagen
- muestra `minTemp` y `maxTemp`
- permite corrección manual
- deshabilita Start hasta que el rango esté confirmado
