# Informe — `Outbound Leak Guard` vivo en STG: la guarda determinista cubre ya los dos carriles

**De:** Agente n8n · **Para:** Arquitecto-IA-Quálitas · **Fecha:** 2026-08-25 (UTC)
**Handoff:** `2026-08-25-guarda-de-salida-cubre-los-dos-carriles.md` · **Issue:** `HYL-WAI#228`

## Corrección aceptada, y dicha bien

Mi frase «por donde pasa TODO lo saliente» era falsa: de los 10 nodos de envío, desde
`Restore Main Reply Payload` solo se alcanza `Send message`. La razón correcta de la ubicación es
la tuya: **es por donde pasa todo el texto generado por los agentes**, que es donde vive el riesgo
de fuga; los otros nueve envíos son copy enlatado o documentos. Queda así dicho, y así va también
en el PR.

## Qué hay vivo

- Nodo nuevo `Outbound Leak Guard` (`n8n-nodes-base.code`, fail-open, jsCode **verbatim** del
  handoff, extraído programáticamente) en la arista `Restore Main Reply Payload → Send message`.
  `Filter System Leaks` sin tocar. Solo STG; el export de PROD no se ha modificado.
- Git: rama `fix/228-outbound-leak-guard`, commit del cambio + **PR #93** (sin mergear; el merge
  es de Alberto). El export de la rama ya es el vivo (sync sin diferencias).
- Import por API: PUT HTTP 200. `versionId` `a0e2595c-…` → **`bbf5a809-d311-4d71-ad25-51274540166e`**,
  `active: true`, **233 nodos**. `webhookId` de los 10 nodos con webhook: idénticos.

**El campo del texto tras `Stash`/`Restore` se llama `output`** — medido en la ejecución 16142
(claves: `detectedPhase, output, phaseMarkerFound, phaseUpdateRequired, phoneNumber, sessionId,
source`) y confirmado en las dos ejecuciones nuevas: el guard lo encontró como primer candidato.

## Aceptación §6

| # | Comprobación | Resultado |
|---|---|---|
| 1 | BFS sobre el grafo importado: guard alcanzable desde `AI Agent` **y** desde `RAG IA Agent` | ✅ y ✅ |
| 2 | `Send message` con un solo predecesor, el guard | ✅ |
| 3 | `Filter System Leaks` intacto (jsCode y conexiones, pre vs post) | ✅ |
| 4 | Nodos | ✅ 233 |
| 5 | Dos ejecuciones reales, una por carril | ✅ ver abajo |
| 6 | Prueba negativa fail-open: item sin campo de texto pasa intacto | ✅ (en frío bajo node; y caso «limpieza vaciaría» conserva el original) |
| 7 | PROD | ✅ HTTP 200, `versionId 8c43fdd0-…` intacto, 229 nodos |

## Las dos ejecuciones reales (sesión del número de prueba, cotización 2207, `qualitas_parameter=30` verificado en Django STG)

**Carril `AI Agent` — ejecución `16152`** (`success`, 18:33Z). Corrió `AI Agent` (RAG no);
`Outbound Leak Guard` ejecutado; `Filter System Leaks` también (ese carril lleva ahora doble
guarda). Término ausente (`/i`), **cifras conservadas** — texto literal:

> Para tu FORD EXPEDITION 2020 tienes estas opciones:
> **Amplia:** • Anual: $12,938.09 MXN • Semestral: $13,478.89 MXN (primer pago $7,186.04, luego 1 pago de $6,292.85) • Trimestral: $13,773.86 MXN (primer pago $4,113.35, luego 3 pagos de $3,220.17 cada uno) • Mensual: $13,970.52 MXN (primer pago $1,983.05, luego 11 pagos de $1,089.77 cada uno)
> **Limitada:** • Anual: $6,868.06 MXN • Semestral: $7,136.32 MXN (primer pago $4,014.76, luego 1 pago de $3,121.56)
> ¿Cuál prefieres?

*Matiz honesto:* en este turno `Get Quotation Data` **no corrió** (no era pregunta de descuento;
el disparador no aplicaba), así que el parámetro no estaba en el contexto del turno. Esta ejecución
acredita **el carril y el paso por el guard**; la que ejercita el campo en contexto es la del RAG.

**Carril `RAG IA Agent` — ejecución `16154`** (`success`, 18:36Z). Corrió el RAG (AI no);
`Get Quotation Data` **sí corrió** (el `discount_context` con `qualitas_parameter=30` estuvo en el
turno); `Outbound Leak Guard` ejecutado **en el carril que antes no tenía guarda ninguna**.
Término ausente (`/i`) — texto literal:

> No puedo acreditar un ahorro adicional porque aún no hay un paquete y forma de pago seleccionados para comparar. Tu cotización ya está al mejor precio disponible. ¿Avanzamos eligiendo una forma de pago? 😊

En las dos, Meta devolvió `wamid` (WhatsApp real entregado) y `outboundLeakGuarded` no se marcó:
el modelo ya venía limpio y el guard no tuvo que redactar. La redacción quirúrgica está probada en
frío (mismos regex del handoff, casos con cifras conservadas y caso-vaciado conservando el original).

## Pendientes que siguen abiertos a propósito

`EDGE CASE` en mayúsculas del `AI Agent`, descripción de la tool `Get Quotation Data`, y PROD
apagado por orden de Alberto (el mismo guard tendrá que viajar a PROD cuando esa orden llegue).
