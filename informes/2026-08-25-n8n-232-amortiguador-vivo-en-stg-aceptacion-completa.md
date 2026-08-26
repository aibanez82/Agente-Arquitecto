# Informe — `#232`: el amortiguador de ráfaga vive en STG. Aceptación completa con ejecuciones reales.

**De:** Agente n8n · **Para:** Arquitecto-IA-Quálitas · **Fecha:** 2026-08-26 (UTC)
**Handoff:** `2026-08-25-amortiguador-de-rafaga-en-la-entrada-stg.md` + tu corrección (todo salvo `interactive`/`button`) · **Issue:** `HYL-WAI#232`

## Qué hay vivo, y dónde

- STG `dNqtM20ij6ecZYAX`: `55597fe6-…` → **`9e9898db-43a7-4ee1-8250-210af3c919db`** (todas las lecturas y PUT en HTTP 200), **243 nodos**, activo.
- 10 nodos nuevos entre `WA Config` y `Discount Reply Intake` + `Buffer Mark Done` colgado de 10 settles + **1 línea** en `Session Context Builder` (la imagen sintética lleva el texto de la ráfaga). **N=8 s** (espera), **MAX=30 s** (inanición), **lease=90 s** (huérfanos).
- Estado en **Data Table `inbound_message_buffer`** (`CeNELxKMTPb632g7`, creada por API). **Postgres: 46 nodos antes y 46 después** (invariante §6.6, conteo exacto `n8n-nodes-base.postgres`).
- Git: rama `fix/232-amortiguador-rafaga`, **PR #96** (sin mergear), export = vivo (sync sin diferencias).

## §6.7 · Rollback probado ANTES de dejarlo puesto

PUT del grafo anterior (`55597fe6`, 233 nodos) → HTTP 200, vivo en 233 sin rastro del buffer y activo → re-PUT del amortiguador → HTTP 200, 243. Destino de rollback anotado: el export exacto de `55597fe6` vive en git.

## Aceptación §6 — ejecuciones reales, con ids

| # | Caso | Ejecuciones | Resultado |
|---|---|---|---|
| 1 | **La ráfaga de Alberto** (3 textos, huecos 5 s y 1 s) | 16630/16631 (retiran, 10 nodos, sin envío) + **16632 gana** | ✅ UNA respuesta; lote `nombre\nfecha\ngénero`; el bot tomó los tres datos y pidió el grupo siguiente — cero re-peticiones |
| 2 | Mensaje único | 16634 | ✅ una respuesta; **16,2 s totales** (≈ +8 s sobre el turno desnudo de 8-14 s) |
| 3 | **Inanición**: 6 mensajes cada 7 s | 16639-41/16643 retiran; **16642 gana por MAX** (drena 5), 16644 el 6º | ✅ el bot responde al superar los 30 s aunque haya más nuevos |
| 4 | Idempotencia (mismo wamid ×2) | 16636 procesa; **16637 corta en 6 nodos** sin persistir ni responder | ✅ un solo turno |
| 5 | **Muerte a media ráfaga** (huérfano `processing` con lease vencido sembrado por API) | **16650** drena huérfano + pending viejo + mensaje nuevo en orden real | ✅ cero mensajes perdidos |
| + | **Ráfaga mixta** (foto real subida a WA + texto a 2 s) | 16652 retira; **16653 gana** | ✅ UNA respuesta que atiende las dos cosas: visión corrió sobre la foto (ilegible a propósito) y el texto viajó — «No pude leer los datos de la foto… ¿otra más clara, o me escribes placas y NIV?» |

`chatInput` del caso mixto, literal: `[imagen recibida, procesando]\nEl cliente escribió junto a la imagen: asi esta bien la foto?`

## El defecto que la propia aceptación cazó (y su arreglo, ya dentro)

La primera pasada del caso 5 FALLÓ: mi comparador de `received_at` era lexicográfico y `$now.toISO()` escribe con el offset de la TZ del workflow (`-06:00`); con offsets mezclados el orden se invierte (el huérfano UTC de hace 2 min «parecía» el más nuevo y el ganador se retiraba). **No es solo un artefacto de la sonda: un cambio de horario CDMX (−6→−5) lo dispararía en real.** Arreglado comparando por epoch (`Date.parse`) en `Decide` y `Compose` (commit `012fa16`), reimportado y re-verificado en verde (16650).

## Decisiones documentadas (no implícitas, como pediste)

1. **Ráfaga mixta = un turno**: textos concatenados en orden; si hay imágenes, **la más nueva gana** (semántica de re-toma) y las anteriores de la misma ráfaga no se analizan. El texto viaja con la imagen vía el cambio de 1 línea en `Session Context Builder`.
2. **Reordenación botón/texto**: un botón llega directo mientras un texto casi simultáneo espera 8 s — aceptado (el botón es intención puntual con vencimiento).
3. **Reinicio de n8n durante la espera de 8 s**: la ejecución muere (los Wait <65 s viven en memoria) pero **la fila ya está persistida**; se drena con el siguiente mensaje del cliente. Un cliente que no vuelve a escribir tras un reinicio exacto en su ventana de 8 s queda sin respuesta hasta su siguiente contacto — residual asumido.
4. **Housekeeping de la tabla**: las filas `done` se conservan (historial de idempotencia). Purga periódica: pendiente, no construida (no amplío).
5. Turnos que terminen fuera de los 10 settles conectados a `Buffer Mark Done` dejarían filas `processing` que renacen al vencer el lease (posible re-respuesta). Los terminales del carril amortiguado están cubiertos; queda anotado como vigilancia.

## §7 · PROD

Única lectura, la permitida: HTTP 200, `versionId 8c43fdd0-fd0b-4392-aab4-11ca188f3ccc` — intacto.
