# Informe F4 (reintento) — ACEPTADO: el bot de 229 procesó un mensaje real en `success`

> Agente n8n · 24 ago 2026 · Handoff `2026-08-24-f4-reintento-import-del-bot.md` (GO `23e3943`).
> **La primera línea es la que pediste:**

## La aceptación — una ejecución real, cruzada en las tres fuentes

**Ejecución `9769`: `success`, 17,8 s** (03:43:16 UTC) — «hola» de Alberto al bot de 229 nodos.

1. **n8n**: `9769` en `success`. Primera ejecución completa del candidato en producción.
2. **`n8n_chat_histories`**: filas 10742–10743 — turno humano con contexto (qid=3501, FORD EDGE
   2020) y la respuesta del agente con la cotización.
3. **El ledger S1, estrenándose en PROD**: fila en `n8n_outbound_dispatch` —
   `dispatch_id s1.reply.7790f45b…`, `outcome=sent`, **`provider_message_id` real de Meta**
   (`wamid.HBgNNTIxNTU1MTA3NDE0NBUC…`), `reserved_at 03:43:33` → `settled_at 03:43:34`,
   `attempts=1`, sesión `waq_3501_5d59ffa2a02f`, epoch 0. El fence reserva→envía→asienta funcionó
   a la primera con un mensaje real.

**F4 CERRADA por el criterio del handoff.**

## Cronología del reintento (UTC)

| Hora | Qué |
|---|---|
| 03:39:07 | Primer PUT del candidato `167c5c18`. Mi verificación dio **FALSO ROJO** en la comprobación nueva de data tables → **reversión automática inmediata** (sin ventana: nadie escribió). |
| 03:39–03:40 | Causa del falso rojo, medida contra el vivo de STG: **el GET de la API devuelve el grafo DOS veces en el cuerpo** (8 apariciones = 4 refs × 2 copias) y yo contaba «exactamente 4» sobre el texto crudo. La comprobación pasó a contar **estructurada sobre los nodos**. Gotcha documentable. |
| 03:40:42 | Reimport. Estructura en verde contada sobre nodos: 229, `active`, `errorWorkflow`→`oTZ86TYMitK2bSur`, timezone CDMX, webhooks 6/6 (`18c1b498` intacto), guard `SEKpp6E4gggaHj11`, **data table `prod=4 / stg=0`**, `WA Config`→`1028815256982638`, cero staging. `versionId` **`8c43fdd0-fd0b-4392-aab4-11ca188f3ccc`**. |
| 03:43:16 | El mensaje de Alberto. `success` en 17,8 s. |

## Estado final de PROD

Bot de **229 nodos** vivo y aceptado; auxiliares intactos; red de error en los 7 workflows del
sistema; capa S1 completa por debajo (F1) y su ledger ya con la primera fila real. Exports
sincronizados a `stg` y `main` (`sync(F4 reintento)`).

Marcha atrás si algo asomara: snapshot de 119 en el repo del ejecutor y `versionId 29bd78b2`
(el del revert verificado).

## Límites

Sin flags, sin variables, nada de BD (solo lecturas de verificación), nada en STG (solo lecturas),
landing cerrada. El falso rojo de 03:39 costó una reversión innecesaria y 95 segundos; lo doy por
bien pagado — la política «revierte primero» está para eso y el diagnóstico se hizo con el bot
sano puesto, como ordenaste.
