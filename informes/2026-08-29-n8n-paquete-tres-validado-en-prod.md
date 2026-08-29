# Informe — paquete de los tres validado en PROD: pasada §7 completa, 3 hallazgos, 1 remiendo en espera

**De:** Agente n8n · **Fecha:** 2026-08-29 ~15:1x UTC
**Cierra:** `handoffs/2026-08-29-promover-paquete-tres-a-prod.md` (§6-§8)

## Lo grande primero

**El camino completo del descuento por VIN corrió de cero en PRODUCCIÓN sin una sola intervención manual**: ráfaga → oferta `POR_VIN_40` con el copy real de dos comas (el calco exacto del incidente del 28 ago 17:29Z, ahora en verde) → aceptar → VIN → `provide_required_data` (202→`queued`) → **`Reopen Discount Poll` reabrió el espejo en su primer uso real** → retarificación → **cotización 3511 con el 40% entregada** (`delivery=sent` 14:56:14Z, aplicación 5 `completed`) → conversación heredada en `waq_3511`, guarda en normal. Y el bug del AVEO, muerto: «ok gracias» con aplicación en vuelo devuelve el copy de Django **sin que el agente corra** (exec `17467`).

## §6 — latencia y fail-open, medidos

- **Guarda**: ~**39 ms**/turno (SELECT 18 + router 17 + IF 4), contra 3,1 s del agente. Ruido.
- **Amortiguador**: `Wait Rafaga` **8 000 ms deliberados** + ~280 ms de maquinaria. Todo turno de texto responde ~8,3 s más tarde **por diseño**; botones van por `IF Direct Lane?` sin espera.
- **Fail-open con rastro**: verificado en salida real — `{ruta:'normal', check_fallido:false}`; el caso `check_fallido:true` quedó probado en STG.

## La tabla §7 completa, con el texto recibido en cada paso: en `HYL-WAI#232` (comentario final)

Ids: `17442` normal · `17444` liga · `17445-47` ráfaga · `17454` aceptar · `17465` VIN · `17467` en-vuelo · `17471` post-resolución.

## Hallazgos (todos con issue, ninguno tapado)

1. **La pieza 1 del #244 no viajó** — era jsCode en `Validate Django Resolution`, nodo COMÚN; el paquete se definió (tú) y se construyó (yo) como censo de nodos, ciego a parámetros de comunes. Copy prometedor al aceptar (exec `17454`). **Remiendo en seco listo**: `deploy-244p1-ask-vin-prod.py` (ASK_VIN + `Persist Django Resolution` a array como prerrequisito de las comas), dry-run PASS sobre `1f24d35f`, **espera tu dictamen y la orden**. Lección anotada en #244: los paquetes por issue deben diffear también parámetros de nodos comunes.
2. **#248** — Django sirve UNA frase para todo el ciclo (`_status_copy` → `processing_copy`): «Perfecto! Déjame que arme tu nueva cotización!» ×3 en la misma conversación (queja textual de Alberto: «no parece muy humano»). Propuesta: copies por momento, editables en Wagtail. Pieza de Juan.
3. **#249** (alto) — tras entregar la 3511, «¿son las mismas coberturas?» recibió «no puedo confirmarte… eso no se puede acreditar» (carril RAG, exec `17471`): el dato «mismas coberturas» existe y no llega — `Get Quotation Data` en PROD **no trae `discount_context`**. Además, jerga interna filtrada. Propuesta en el issue; el systemMessage, por su canal.
4. **#207** — «quiero mi liga de pago» no llamó a la tool (respondió desde captura; cero URLs inventadas). Hallazgo contra el punto 1 de Juan, para dictamen.

## Huecos declarados

50+ filas en PROD: no existe (tabla nacida hoy), no se siembra — probado en STG. No-regresión `POR_PRECIO`: Django ruteó a `POR_VIN_40`; no ejercitada hoy. La aplicación **1** de PROD sigue atascada en `awaiting_conversation` desde el 24 ago (la 5 cruzó esa etapa en segundos: su cuadro es otro) — observación, no la toco sin orden.

## Estado de cierre

PROD `1f24d35f` (255 nodos) · STG `ecab128b` (260) · espejos fieles en `stg` y `main` · scripts completos en `chore/scripts-noche-232-243-244` · monitores vivos. Sin trabajo pendiente del ejecutor salvo el mini-paquete, que espera orden.

— Agente n8n
