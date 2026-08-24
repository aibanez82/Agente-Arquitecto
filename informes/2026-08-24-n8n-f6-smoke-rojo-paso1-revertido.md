# Informe F6 — smoke ROJO en el paso 1; bot revertido; ningún cliente afectado

> Agente n8n · 24 ago 2026 · Handoff `2026-08-24-f6-smoke-e2e-en-produccion.md` (GO `d63a882`).
> **Resultado: FALLO ESTRUCTURAL en el paso 1, smoke abortado, bot de PROD revertido a 119 nodos y
> respondiendo. Los pasos 2–7 no se alcanzaron.**

## Los 7 pasos

| # | Qué acreditaba | Resultado |
|---|---|---|
| 1 | trigger + webhookId `18c1b498` | **ROJO a medias, y el matiz importa**: el trigger y el webhook SÍ entregaron (el mensaje de Alberto llegó y disparó la ejecución). Lo que murió fue el procesamiento: ejecución **9763**, 03:11:46 UTC, error a los **0,6 s** en `Check Delivery Idempotency`: `Could not find the data table: 'bIxZXnNOotosIa5q'`. Sin respuesta a Alberto, cero turnos persistidos. |
| 2–7 | — | **NO ALCANZADOS.** |

## Evidencia cruzada del paso 1 (las tres fuentes)

1. **n8n**: ejecución 9763, `status=error`, 0,6 s, `lastNodeExecuted=Check Delivery Idempotency`.
   Nodos que sí corrieron: trigger → `Phone Number ID Guard` → `WA Config` → `Discount Reply
   Intake` → … → el carril de descuentos hasta el candado de idempotencia. Stack trace confirmado
   también por Alberto desde la UI (DataTableService.validateDataTableExists).
2. **`n8n_chat_histories`**: cero filas nuevas sobre el baseline (max id 10737). El turno no se
   persistió — coherente con la muerte antes del agente.
3. **`qualitas_whatsappmessage`**: cero filas nuevas (max id 1921). Nada salió.

Baseline previo (03:05:41 UTC): `qualitas_discountoffer` = 0 filas — sigue en 0; ni el #204 ni el
#205 llegaron a poder observarse (la conversación no existió).

## La reversión

- **03:15:11 UTC — REVERTIDO** al snapshot pre-import (119 nodos), por la marcha atrás
  preautorizada: el bot no fallaba «un paso del smoke» — moría con **cualquier** mensaje entrante,
  o sea afectaba a cualquier cliente que escribiera. Verificado leído de la instancia: 119 nodos,
  `active=true`, webhookId del trigger intacto, `versionId` nuevo `29bd78b2-…`.
- **Conservé el `errorWorkflow`** (`oTZ86TYMitK2bSur`) en el bot revertido: inocuo, y funcionó —
  la ejecución 9763 quedó capturada por la red de error estrenada en F4.
- **Ventana rota total: 02:24:45 → 03:15:11 UTC** (~50 min, desde el import de F4 — no desde el
  smoke). Ejecuciones del bot en la ventana: **UNA**, la del teléfono de Alberto. **Ningún cliente
  real escribió; ningún cliente afectado.**
- Export del bot revertido sincronizado a `stg` y `main` (`sync(F6 revert)`).

## Causa raíz — la quinta configuración de entorno sin fila, y su clase

El candidato usa una **Data Table de n8n** (`quote_document_deliveries`, id STG
`bIxZXnNOotosIa5q`) en 4 nodos del candado de idempotencia de entrega del documento
(`Check Delivery Idempotency`, `Claim Delivery Processing`, `Mark Delivery Sent`,
`Mark Delivery Failed`). Las Data Tables son **recurso de instancia** — como las credenciales y los
workflows referenciados — y en PROD no existe ninguna. El id viaja embebido en el JSON sin nada que
lo declare id-de-instancia: los dos candidatos lo comparten igual y el espejo no puede verlo. Misma
clase que el guard (F3) y las URLs de Django (F4), tercera aparición.

**El lead y la conversación del smoke quedan como evidencia, sin tocar.** La sesión no llegó a
crearse en Django (el flujo murió antes), así que no hay seguimientos que desactivar — lo verifiqué
en el baseline de mensajes: cero filas nuevas.

## Censo pedido a posteriori (para F4.bis)

Referencias a recursos de instancia en el candidato PROD: **91 nodos**, **9 recursos distintos** —
7 credenciales (7 con fila), 1 workflow (`SEKpp6E4gggaHj11`, con fila), 1 data table (**sin fila —
el hueco**). 8 de 9 con fila.

## Límites

Nada tocado durante el smoke salvo la reversión preautorizada. Ni flags, ni variables, ni base, ni
STG (solo lecturas). La landing sigue cerrada. El followup legacy sigue como estaba.
