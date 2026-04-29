# Skills de Antigravity para migrar ThermoMater AI a Flutter

Este paquete contiene skills pensadas para que Google Antigravity desarrolle una versión Flutter de ThermoMater AI con paridad funcional respecto a la app Android original.

## Estructura recomendada

Coloca estas carpetas así:

```text
.agent/
└── skills/
    ├── thermomater-flutter-architect/
    │   └── SKILL.md
    ├── thermomater-analysis-pipeline/
    │   └── SKILL.md
    ├── thermomater-ui-flows/
    │   └── SKILL.md
    ├── thermomater-persistence-results/
    │   └── SKILL.md
    └── thermomater-qa-parity/
        └── SKILL.md
```

## Orden sugerido de uso

1. `thermomater-flutter-architect`
2. `thermomater-ui-flows`
3. `thermomater-analysis-pipeline`
4. `thermomater-persistence-results`
5. `thermomater-qa-parity`

## Reglas de trabajo recomendadas

- Mantener paridad funcional con ThermoMater AI antes de introducir mejoras estéticas.
- Preservar la lógica clínica actual: OCR de temperatura mínima/máxima, segmentación, registro no rígido, cálculo por dermatomas, guardado por sesiones y visualización histórica.
- Evitar reescribir la ciencia del proyecto sin evidencia. Primero portar. Luego optimizar.
- Preferir una arquitectura Flutter modular con servicios desacoplados para UI, inferencia, OCR, persistencia y reportes.
- Mantener soporte bilingüe español/inglés desde el inicio.
- Tratar iOS como objetivo de primer nivel, no como adaptación tardía.

## Convención sugerida para el proyecto Flutter

```text
lib/
  app/
  core/
    errors/
    i18n/
    theme/
    utils/
  features/
    patients/
    analysis/
    results/
    sample_database/
    settings/
  services/
    ocr/
    ml/
    dermatome/
    storage/
    charts/
    export/
  models/
  l10n/
```

## Salidas que Antigravity debería producir con estas skills

- estructura de carpetas Flutter
- modelos de dominio
- navegación y pantallas
- wrappers de inferencia y OCR
- pipeline de análisis desacoplado
- persistencia local basada en archivos
- gráficos, GIFs y resultados
- pruebas de paridad funcional

## Nota

Estas skills están escritas para crear una app Flutter que conserve el comportamiento del sistema actual, no para entrenar nuevamente el modelo ni para rediseñar el flujo clínico.
