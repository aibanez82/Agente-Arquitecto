> **SUPERSEDED (4 ago 2026):** el plan C2–C9 fue sustituido por Contract-First S1–S5 (enmienda `#140 c.5174994247`). Este doc queda como registro histórico; el candidato `1161dcf` se conserva solo como insumo. Prep vigente: `docs/iniciativas/s2-prep-offline.md`.

# C2 — Matriz núcleo Dual: borrador de runbook E2E (preparación offline, carril B)

> Preparado por el Arquitecto (31 jul, madrugada+mañana) al amparo del carril offline que la
> delimitación de C1 permite ("preparar contratos o suites futuras offline no autoriza
> ejecutar"). NADA de esto se ejecuta sin el GO de C2 con checkpoint operativo completo
> (§10: SHA, target, comando, precondiciones, stop conditions, backup, guardia, rollback).
> Objetivo: que cuando llegue el GO, el E2E arranque sin diseñar nada.

## Alcance (matriz aprobada en #140, §Gates-de-C y re-scope de #132)

| # | Bloque | Qué prueba | Estado previo |
|---|---|---|---|
| M1 | Regresión `qc:` inválidos | Los 5+1 payloads de Juan → Terminal Sink, cero efectos | PASS en E2E del 30 jul (E1) — repetir como regresión |
| M2 | `qc:` v1/v2 válidos | Quick-replies resuelven la sesión correcta (el bug del binding reparado) | Reparado en STG (`40fe572`); nunca probado E2E en vivo |
| M3 | Dos cotizaciones del mismo teléfono | La identidad Dual separa hilos; ninguna operación cruza conversaciones | Núcleo del valor de Dual — estreno E2E |
| M4 | Selección / afinidad | `Apply Affinity Update` con 1 y 2 variantes (el bug latente reparado); afinidad correcta tras selección | Estreno E2E |
| M5 | Variantes 10/52/521 | Canónico único (`525512345678`) en resolución y fencing | Vectores publicados y verificados offline; estreno E2E |
| M6 | Payment exacto/dedupe | `event_id` único → 1 update/1 notificación; repetido → duplicate; identidades cruzadas → contradiction; **sin efecto real** (sink inerte) | Cerrado offline (contrato 3 + 6.8.7); estreno E2E |

## Método (hereda las condiciones duras del GO del 30 jul + delimitación C1)

- Solo plano de prueba: idealmente los **clones aislados de C1** (build reproducible, 24
  sinks) — si el GO de C2 opta por el plano vivo contenido, los gates C1 deben estar
  desplegados y verificados antes.
- Datos: prefijo `E2E-`, teléfonos no numéricos donde aplique (M5 exige variantes numéricas
  sintéticas — usar rangos reservados 5215550xxx/525550xxx documentados como fixtures),
  `quotation_id` ≥ 990001. Limpieza con conteos antes/después.
- Cero Meta/Gmail/red real: sinks deterministas o parada pre-conector. Payment con sink.
- Entrada: POST local al webhook de test del plano aislado (o al de STG solo si el GO lo
  autoriza). Estado por SQL fixture; observación por trazas de ejecución + snapshot SQL.
- Stop condition: primer efecto externo inesperado o FAIL → parar, reportar (heurística 5).

## Fixtures preparados (borrador)

- Sesiones: `E2E-C2-S1..S8` — pares del mismo teléfono para M3 (S3/S4 comparten
  `phone_number`, distinta `conversation_id`/`quotation_id`), variantes 10/52/521 en S5-S7.
- Payloads M1: los 6 del E2E anterior (reuso literal). M2: `qc:v1:l:<lead>:c:<cot>:m:<hex>`
  y `qc:v2:cv:<conv>:l:<lead>:c:<cot>:m:<hex>` válidos contra S1/S2.
- Payment M6: 3 eventos uuid (nuevo/duplicado/contradictorio) contra S8 en
  `payment_pending`.

## Evidencia exigible (formato del 30 jul, que Juan ya aceptó)

Por bloque: resultado, IDs sintéticos, efectos observados, confirmación explícita de cero
efecto real, conteos de limpieza, desviaciones. Ejecutor: Agente QA (handoff se emitirá al
GO de C2 con el checkpoint operativo pegado).

## Suite negativa compartida (arrancada aquí, se separa a su propio doc al crecer)

Estructura propuesta `test/negative-suite/` (rama C1 de Agente-n8n o rama propia):
- `juan/` — las reproducciones de las 6 auditorías (writers stale, identidad cruzada,
  qc-fuzzing, carrera Payment, TOCTOU, GET convergido, IF shape, binding $3/$4).
- `arquitecto/` — las 4+3 pasadas adversariales (writer nº9, fingerprint del sub,
  cross-schema, fixtures incompletos, sub-workflow IF, autoridad INSERT→Gmail).
- `contrato.md` — regla de aceptación: un PASS de fase exige la suite negativa entera en
  verde; toda reproducción nueva de cualquier lado se añade antes del cierre de su fase.
