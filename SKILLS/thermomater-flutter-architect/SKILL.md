---
name: thermomater-flutter-architect
description: Diseña la arquitectura Flutter de ThermoMater AI y dirige la migración desde la app Android/Kotlin original. Usa esta skill cuando el usuario pida estructura de proyecto, capas, módulos, paquetes, servicios, integración iOS/Android o estrategia de portabilidad.
---

# ThermoMater Flutter Architect

## Goal

Diseñar una base Flutter mantenible y lista para iOS y Android que conserve la lógica principal de ThermoMater AI: gestión de pacientes, análisis termográfico, resultados históricos y base de datos de casos.

## When to Use

Usa esta skill cuando la tarea incluya cualquiera de estos puntos:

- crear la estructura inicial del proyecto Flutter
- decidir carpetas, capas y módulos
- migrar responsabilidades desde Activities Kotlin a pantallas, controladores y servicios Flutter
- escoger la separación entre UI, dominio, persistencia y ML
- definir integración con inferencia on-device, OCR, archivos y gráficos
- preparar la app para iOS aunque el desarrollo se haga desde Windows/Linux

## Do Not Use

No uses esta skill como skill principal cuando la tarea sea exclusivamente:

- implementar una pantalla puntual ya especificada
- escribir pruebas de regresión
- depurar un cálculo del pipeline térmico
- generar el árbol de archivos de pacientes o el GIF histórico

En esos casos delega a la skill especializada correspondiente.

## Contexto fijo del producto

Asume siempre estas reglas del proyecto:

- La pantalla principal tiene cuatro módulos: Pacientes, Análisis, Resultados y Base de datos.
- La navegación base incluye Ayuda, Inicio y Configuración.
- El flujo clínico se apoya en imágenes termográficas de ambos pies.
- El análisis detecta temperatura máxima y mínima, permite corrección manual cuando el OCR falla o cuando el rango es clínicamente sospechoso, segmenta pies, registra dermatomas y calcula temperaturas promedio por zona.
- Los resultados deben guardarse por paciente y por sesión temporal `t0`, `t1`, `t2`, etc.
- La app debe manejar español e inglés.
- La persistencia preferida es local y basada en archivos organizados por carpetas, no en una base de datos relacional.

## Principios obligatorios de arquitectura

1. **Portar antes de reinventar**
   - Replica el comportamiento funcional existente antes de optimizar la UX o el pipeline.

2. **Separación fuerte por responsabilidades**
   - UI
   - control de flujo
   - servicios nativos/ML
   - persistencia
   - visualización de resultados

3. **Flutter-first con puentes puntuales**
   - Mantén la mayor parte en Dart.
   - Usa canales nativos o plugins solo para OCR, inferencia o integraciones que no tengan una implementación Flutter robusta.

4. **Compatibilidad iOS desde el diseño**
   - Nunca asumas rutas Android.
   - Nunca acoples la lógica a Activities o permisos exclusivos de Android.
   - Todo acceso a archivos debe pasar por una abstracción de almacenamiento.

5. **Pipeline desacoplado**
   - OCR, segmentación, registro dermatómico, mapeo de temperatura, guardado y visualización deben ser servicios independientes.

## Arquitectura recomendada

Usa esta estructura como base:

```text
lib/
  app/
    app.dart
    router.dart
  core/
    constants/
    errors/
    theme/
    utils/
    i18n/
  features/
    patients/
      data/
      domain/
      presentation/
    analysis/
      data/
      domain/
      presentation/
    results/
      data/
      domain/
      presentation/
    sample_database/
      data/
      presentation/
    settings/
      presentation/
  services/
    ml/
    ocr/
    dermatome/
    storage/
    charts/
    export/
  shared/
    widgets/
    models/
  l10n/
```

## Mapeo desde la app original

Cuando tengas que migrar la app original, usa esta correspondencia conceptual:

- `MainActivity` -> `HomeShell` o `DashboardScreen`
- `FormularioActivity` / `NewPatientActivity` -> flujo `patients/presentation`
- `MamitasAppActivity` -> `analysis/presentation` + `services/ml` + `services/ocr`
- `PlotActivity` -> `analysis_result_screen`
- `ResultadosActivity` + `ChartActivity` -> `results/presentation`
- `BaseDeDatosActivity` -> `sample_database/presentation`
- `FolderActivity` / `FileBrowserActivity` -> exploradores internos o vistas de resultados persistidos
- `SettingsActivity` -> `settings/presentation`

## Decisiones técnicas preferidas

- Inference on-device:
  - prioriza LiteRT/TFLite mediante un wrapper desacoplado
  - no amarres la app a APIs experimentales sin encapsularlas
- OCR:
  - encapsula OCR como servicio reemplazable
  - el OCR solo debe devolver texto crudo y valores parseados
- Localización:
  - usa `flutter_localizations` y archivos `ARB`
- Almacenamiento:
  - usa un servicio construido sobre rutas de documentos de la app
- Gráficos:
  - implementa el gráfico histórico como componente reusable
- Estado:
  - usa una estrategia consistente y simple; evita mezclar muchos patrones

## Instrucciones de ejecución

1. Lee primero el requerimiento del usuario.
2. Traduce el requerimiento a uno o más módulos Flutter.
3. Identifica qué partes pertenecen a:
   - dominio
   - UI
   - servicio OCR
   - servicio ML
   - almacenamiento
   - visualización de resultados
4. Propón o genera archivos solo dentro de la capa correcta.
5. Si una decisión técnica afecta iOS, explícalo explícitamente.
6. Cuando generes código, incluye:
   - nombres de carpetas
   - nombres de clases
   - contratos entre capas
   - dependencias mínimas necesarias
7. Evita meter lógica clínica directamente en widgets.
8. Evita que un solo archivo controle pantalla, ML, OCR y persistencia al mismo tiempo.

## Restricciones

- No uses SQLite como solución principal salvo que el usuario lo pida de forma explícita.
- No conviertas el análisis clínico en llamadas remotas obligatorias.
- No introduzcas backend para tareas que hoy son locales.
- No cambies el significado de las zonas dermatómicas.
- No reemplaces la numeración temporal `t0..tN` por timestamps opacos si eso rompe la trazabilidad del proyecto.

## Output esperado

Cuando esta skill se active, la respuesta debe entregar una o más de estas salidas:

- árbol de carpetas Flutter
- lista de archivos a crear
- contratos de clases y servicios
- estrategia de migración por fases
- justificación técnica de cada módulo
- código base listo para implementar

## Example

### Input
“Quiero arrancar la app Flutter y necesito la arquitectura inicial para pacientes, análisis y resultados.”

### Output behavior
- crear estructura `features/`
- separar `services/ml`, `services/ocr` y `services/storage`
- definir router base
- proponer modelos `Patient`, `AnalysisSession`, `DermatomeTemperature`
- dejar claro qué parte irá a iOS/Android nativo y cuál queda en Dart
