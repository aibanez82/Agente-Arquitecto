# Handoff Arquitecto → Agente n8n — Revertir placas obligatorias (Issue #51)

> Autor: Arquitecto-IA-Qualitas · 20 jul 2026
> Ejecutor: **Agente n8n**.
> Gobernanza: reportas al Arquitecto **a través de Alberto**. No hablas con otros agentes.
> Copia canónica: `Agente-Arquitecto:docs/2026-07-20-handoff-agente-n8n-revertir-placas-obligatorias.md` — deja también copia en `Agente-n8n/handoffs/`.
> **Prioridad: ALTA** — confirmado con caso real (cotización 3033, cliente Jesús Alfonso, 20 jul ~16:17, ver `qualitas-issues#51`) que esto bloquea/desvía leads reales ahora mismo.
> **Rama destino: `stg` primero**, como siempre — pero dado que es alta prioridad y el cambio es acotado (3 ediciones de texto, sin lógica nueva), Alberto puede pedir acelerar la promoción a `main` apenas se valide en STG.

## Objetivo

Issue `aibanez82/qualitas-issues#51`. Las placas del vehículo deben ser **opcionales** — Alberto
confirmó (20 jul) que el webservice de Quálitas no las requiere para emitir. Si el lead no las
tiene o no las da, el bot debe continuar sin ellas, exactamente como funcionaba antes del 13 jul.

## Causa raíz (confirmado vía n8n REST API contra PROD vivo — no uses el JSON local sin
## re-verificar primero, hasta hace unas horas estaba desactualizado, ver `qualitas-issues#30`)

El commit `2fe5352` (13 jul 2026, aplicando la spec **M19 "flujo de data_capture sin fricción"**
de Agente Mejoras Conversación) introdujo "placas obligatorias" como parte de ese paquete.
Alberto no recuerda un motivo puntual detrás de esta parte específica del cambio — probablemente
fue exceso al aplicar el paquete completo, no una necesidad real. El resto de M19 (INE ya no se
pide, menos confirmaciones intermedias, personalización con nombre) **no se toca** — solo la
parte de placas.

## Dónde vive (confirmado leyendo el workflow vivo de PROD vía API, 20 jul 2026)

Tres lugares en el nodo **`AI Agent`** (`@n8n/n8n-nodes-langchain.agent`,
`parameters.options.systemMessage`) y uno en **`Validate Personal Data`**
(`@n8n/n8n-nodes-langchain.toolCode`, `parameters.jsCode`):

### 1. Bloque de regla (`AI Agent`, systemMessage)

Texto actual (ubicado justo antes de "GRUPO 1 - DATOS PERSONALES"):
```
**PLACAS DEL VEHÍCULO (OBLIGATORIAS — ya no opcionales):**
- Las placas son un dato obligatorio para continuar. Si el usuario no las proporciona en el
  Grupo 2, NO avances al Grupo 3 — pide explícitamente: "Necesito las placas de tu vehículo
  para continuar con la cotización."
- Si el usuario dice que no las tiene a la mano (trámite en proceso, etc.), sigue las
  instrucciones de escalamiento estándar para datos faltantes obligatorios — no inventes
  ni dejes el campo vacío.
```

Cambiar a:
```
**PLACAS DEL VEHÍCULO (OPCIONALES):**
- Pide las placas en el Grupo 2, pero si el usuario no las tiene o no las proporciona,
  continúa sin ellas — el webservice de Quálitas no las requiere para emitir. No insistas ni
  bloquees el avance al Grupo 3 por este dato.
```

### 2. Línea de solicitud en Grupo 2 (`AI Agent`, systemMessage)

Buscar (dentro de "GRUPO 2 - DATOS DEL VEHÍCULO"):
```
- Placas del vehículo (6 a 7 caracteres) — OBLIGATORIAS
```
Cambiar a:
```
- Placas del vehículo (6 a 7 caracteres, opcional)
```

### 3. Nota de `validate_personal_data` (`AI Agent`, systemMessage)

Buscar:
```
- **placas**: OBLIGATORIO. Siempre deben venir provistas por el usuario (ver regla PLACAS DEL
  VEHÍCULO arriba) — no debe llegar aquí una placa vacía.
```
Cambiar a:
```
- **placas**: Opcional. Si el usuario las proporcionó: 6-7 caracteres alfanuméricos. Si NO las
  proporcionó: usar "" (cadena vacía).
```

### 4. Código de validación (`Validate Personal Data`, jsCode)

Texto actual:
```js
// Placas validation (obligatorias, 6-7 caracteres alfanumericos)
if (!data.placas) {
  errors.placas = "Las placas son obligatorias.";
  hasErrors = true;
} else {
  const placasRegex = /^[A-Z0-9]{6,7}$/;
  if (!placasRegex.test(data.placas.toUpperCase())) {
    errors.placas = "Formato inválido. Debe ser 6 o 7 caracteres alfanuméricos (ej. ABC123 o ABC1234)";
    hasErrors = true;
  }
}
```
Cambiar a (revierte exactamente al patrón pre-M19, mantiene la regex 6-7 cuando sí se
proporcionan — sin tocar nada de la validación de `serie`/VIN, que es correcta y no está en
discusión):
```js
// Placas validation (opcionales, 6-7 caracteres alfanumericos si se proporcionan)
if (data.placas) {
  const placasRegex = /^[A-Z0-9]{6,7}$/;
  if (!placasRegex.test(data.placas.toUpperCase())) {
    errors.placas = "Formato inválido. Debe ser 6 o 7 caracteres alfanuméricos (ej. ABC123 o ABC1234)";
    hasErrors = true;
  }
}
```

## Confirmado que NO hace falta tocar

- **`Issue Policy`** (httpRequestTool): el parámetro `placas` ya es un simple
  `$fromAI(..., "License plates (7 alphanumeric)", 'string')` — no fuerza nada, ya reenvía lo que
  venga (vacío incluido). No requiere cambios.
- **`RAG IA Agent`** (KB assistant): no tiene lógica de captura de datos ni menciona placas
  obligatorias — es un flujo de preguntas informativas, no de contratación. No requiere cambios.
- La foto de tarjeta de circulación (extracción automática de VIN+placas) sigue funcionando
  igual — solo cambia qué pasa si el dato no está disponible ni por texto ni por foto.

## Tareas

1. Aplicar los 4 cambios de arriba en `stg`.
2. Probar en STG (pin data o Execute workflow): simular un lead que responde "no tengo placas"
   o "el auto no tiene placas" en el Grupo 2 — debe continuar al Grupo 3 sin bloquear, y
   `validate_personal_data` no debe marcar error de placas si viene vacío.
3. Confirmar que si el usuario SÍ da placas, la validación de formato (6-7 caracteres) sigue
   funcionando igual que antes (no debe aceptar cualquier string).
4. Confirmar que la extracción por foto de tarjeta de circulación no se ve afectada — el
   comportamiento de guardar lo que la foto detectó (si detectó placas) no cambia; solo cambia
   qué pasa si NO se detecta ni se escribe.
5. Reportar el commit + resultado de la prueba. Dado que es prioridad alta, avisar apenas esté
   validado en STG para que el Arquitecto decida con Alberto si se acelera a `main`.

## Fuera de alcance

- El resto del paquete M19 (INE ya no se pide, confirmaciones reducidas, personalización con
  nombre) — se queda igual, no es parte de este bug.
- La validación de `serie`/VIN (regex estricto de 17 caracteres) — correcta, no se toca.
- Re-exportar el JSON de referencia tras este cambio — el Arquitecto ya lo tiene resuelto como
  proceso (ver `qualitas-issues#30`, cerrado 20 jul) y lo vuelve a hacer cuando este fix esté
  aplicado.
