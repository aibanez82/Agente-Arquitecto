# Informe — Inventario STG vivo vs PROD, con la procedencia de cada delta

**De:** Agente n8n · **Para:** Arquitecto-IA-Quálitas · **Fecha:** 2026-08-25 (UTC)
**Para qué:** el plan de promoción que vas a construir. Solo medición; nada tocado, PROD solo leído.

## 1 · Inventario contra las INSTANCIAS vivas (no exports)

`GET /workflows` — STG **HTTP 200** (16 workflows), PROD **HTTP 200** (8 workflows).

**STG (instancia `n8n-xlqk…`):**

| id | nombre | active | nodos | versionId |
|---|---|---|---|---|
| `dNqtM20ij6ecZYAX` | WhatsApp Insurance Quotation Bot_stg | ✅ | 233 | `55597fe6-a87f-44ca-9b13-97a6ac2fe48a` |
| `Ob5JYHYbc23SLp0A` | …Payment Confirmation (STG) | ✅ | 16 | `4594e0a8-1748-4ae4-a671-47c4231c6213` |
| `nYRaRzU83qDLuEWI` | Retomar Conversacion_stg | ✅ | 27 | `3eb8eccc-0b6f-4c09-b3b0-2e8b373bb9c9` |
| `HAMIxqhZd2TEy6NB` | Atencion Humana (STG) | ✅ | 19 | `5bb5755b-5aa7-4ba5-b712-90f9059b1224` |
| `PuogahK4qv9YOiF4` | Issue Policy Guard (STG) | ✅ | 5 | `c674a58f-65b5-4b24-9bc8-c618e1a4c262` |
| `DeCguAaVtCuW2CUj` | Discount Application Poller Candidate v1 | ✅ | 62 | `2ea5e20c-795c-4207-91bc-e1e0f4c12c5f` |
| `nT6395r2jjMUqVyF` | Error Handler STG | ✅ | 7 | `1aaa4e54-1b85-4be1-9d03-efc3b0573dbb` |
| `liBCn3yBegedmYuR` | METEPEC - Registrar Lead (STG) | ⛔ | 19 | `52e64fd9-8a45-4293-b8a9-e33fa9c81f3a` |
| `biWlbwq4NQdZadwg` | Metepec Liberar (STG) | ⛔ | 4 | `f1455211-96dc-498b-bd24-a1277805a0a3` |
| + **7 `C1-AISLADO — *`** | archivo del `#179` | ⛔ todos | 28/7/19/4/15/9/137 | (en el repo, `workflows/c1-aislado-archivado-2026-08/`) |

**PROD:** los 8 que ya tienes; confirmo `8c43fdd0…` en el bot (intacto).

**Instancia ↔ repo:** los 16 de STG tienen fichero (9 exports de primer nivel + 7 en el archivo C1).
En el otro sentido, todo lo del repo sin workflow en STG tiene causa: `Monitor Qualitas SIO PROD.json`
(solo PROD, deliberado — §4), `s1/` (candidatos, artefactos de build, no instancias),
`borrados-stg-2026-08-14/` (borrados a propósito ese día) y `vivo-stg-2026-08-14/` (snapshot).
**Ni un huérfano en ningún sentido.**

## 2 · Procedencia de los deltas, nodo a nodo (datada con `git log -S`)

**Bot principal (+4):**

| Nodos | Procedencia | Categoría |
|---|---|---|
| `IF Limitada Observada?`, `Build Limitada Alerta`, `Notify Limitada Observada` | Guardrail «Limitada» **fase 1 — observa y avisa** (`#206`; dictamen tuyo del 24 ago `02347db`, corregido el 25 ago `8c28e75`: el observador a la SALIDA del stash; import firmado `c71cb7d1` → 232 nodos) | **(a)** en observación en STG; pasar a PROD (o a fase 2) es decisión pendiente |
| `Outbound Leak Guard` | Hoy, paquete `#228` (PR #93) | **(a)** pendiente — viaja con el paquete del leak |

**Retomar Conversacion (+15):**

| Nodos | Procedencia | Categoría |
|---|---|---|
| Valla de salida ×7 (`Claim/Stash/Restore/Settle Retomar Reply…`, `Freeze…Identity`, `IF Send…?`, `…Fence Denied`) | `#156` — «fence al 9/9 en STG» (`2395e37`). **Es la misma valla anti-doble-envío que el bot principal SÍ tiene ya en PROD** (`a8a5213`, fence común) | **(a)** pendiente: PROD tiene la valla en el bot pero no en Retomar |
| Checkpoint/descuento ×8 (`Send Checkpoint Message`, `Insert Checkpoint History`, `Build Checkpoint Success/Uncertain`, `Settle Checkpoint Sent/Uncertain`, `IF Discount Offer?`, `Send Discount Offer`) | Módulo de descuentos `#156` — «claim checkpoint v0.6 outbound» (`3e536f5`) | **NO LO SÉ entre (a) y (c)** — la oferta proactiva de PROD acabó yendo por el poller (`#225`); si este carril de Retomar sigue siendo plan o quedó superado, lo debes dictaminar tú |
| `WA Config STG` (y PROD tiene `WA Config`) | Convención de rotación de `phone_number_id` | **(b)** mapeo, no delta: cada entorno lleva SU nodo de config; jamás se copia entre entornos |

**Payment Confirmation (+11):**

| Nodos | Procedencia | Categoría |
|---|---|---|
| Valla de salida ×7 (mismo patrón) | `#156` (`2395e37`) | **(a)** pendiente, mismo caso que Retomar |
| `S1 Payment Request Guard`, `S1 Request Valid?`, `S1 Observable — Payment` | Contrato **S1** (`fd8fa75`, contrato v1; `f11bc93` lo refleja vivo). El main de PROD ya recibió SU capa S1 (F1, 24 ago); **el Payment de PROD no** | **(a)** pendiente, encadenado al checkpoint S1 |
| `WA Config STG` | Convención de rotación | **(b)** mapeo, no delta |

## 3 · Metepec, parqueados y con orden vigente

**Orden de Alberto, comentario de decisiones en `HYL-WAI#177` (20 ago, 20:27Z)** + tu handoff
`2026-08-20-177-archivar-metepec-stg.md` (`a05f06a`). Ejecutado el 20 ago 20:39Z
(`scripts/177/archivar-metepec-stg.py --go`, verificado por relectura): la tool
`registrar_lead_metepec` y los 6 nodos del camino derivado salieron del bot; los dos workflows
quedaron **inactivos a propósito**. **Vigente, no huérfanos.** Nunca existieron en PROD (METEPEC
sigue pendiente de E2E real + credencial Gmail de PROD para plantearse promoción).

## 4 · Monitor Qualitas SIO PROD — deliberado, no hueco

Creado el 18 jul **«solo en PROD»** por diseño (doc `2026-07-18-monitor-qualitas-sio-prod-telegram.md`,
extendido el 20 jul a wsTarifa/QBCImpresion): `scheduleTrigger` cada 10 min que vigila los servicios
de Quálitas **de producción** y alerta por Telegram. En STG no tiene sentido: vigilaría QA con
alertas de mentira. No falta nada.

## 5 · Nota para tu plan (dato, no plan)

La foto «STG perfecto → promover» tiene además tres piezas que no son nodos: los PRs `#93/#94/#95`
sin mergear (el propio fix del leak aún no está en `stg`), el export de PROD del repo que ya lleva
el fix `#228` sin estar en PROD (gemelo semántico que documenté en `#230`), y los pendientes vivos
de CLAUDE.md que nunca entraron en PROD (atención humana, renovación, filtro de horario…). Tu tabla
de deltas de nodos es necesaria pero no suficiente; el paquete lo defines tú.
