# Reconciliación de los grafos de n8n en PROD — 3 sep 2026

**Pregunta de partida:** mi foto de cierre del 2 sep decía «grafo final `0265f83b`, **309 nodos**». Hoy el bot vivo tiene **315**. Seis nodos sin explicar delante de cualquier viaje nuevo.

**Veredicto: no hay ningún polizón. El descuadre era mío, de rotulado.**

## Los seis nodos, con nombre y apellido

`0265f83b` (309) es el grafo del **`#260`**, a las 17:46 CDMX — no el final del día. Después entraron dos paquetes más:

| Paso | versionId | Nodos | Hora (CDMX) |
|---|---|---|---|
| `#260` — la sesión en curso va primero | `0265f83b` | 309 | 2 sep 17:46 |
| `#297` — la red de reparación y reintento | `774d2374` | **315** | 2 sep 18:02 |
| `#298` — el guard tipado sin llamada a Django | `bf44e0bb` | 315 | 2 sep 18:22 |

**Los +6 son del `#297`, y son exactamente su red, duplicada por rama (AI y RAG):**

`Repair Window (AI)` · `Repair Window (RAG)` (postgres) · `Restore Retry (AI)` · `Restore Retry (RAG)` (code) · `IF Repaired (AI)?` · `IF Repaired (RAG)?` (if)

Ninguno quitado. **El `#298` no añadió ni quitó nodos al bot** —su nodo nuevo vive en el sub-workflow `Quotation Data Guard`—, y el `#302` tocó solo ese sub-workflow. Por eso el recuento se queda en 315.

## La comprobación fuerte: no el recuento, el contenido

Comparé **los nueve workflows activos** de la instancia PROD contra su espejo en `aibanez82/Agente-n8n:origin/main`, nodo a nodo: `versionId`, hash de los `parameters` de cada nodo y el bloque `connections` completo.

| Workflow | vivo | espejo | |
|---|---|---|---|
| WhatsApp Insurance Quotation Bot | `bf44e0bb` | `bf44e0bb` | idéntico |
| Discount Application Poller | `5267656e` | `5267656e` | idéntico |
| Monitor Qualitas SIO PROD | `d4b84b30` | `d4b84b30` | idéntico |
| Atencion Humana | `e87b5431` | `e87b5431` | idéntico |
| Retomar Conversacion | `fa42a9b4` | `fa42a9b4` | idéntico |
| Payment Confirmation | `b6aef7aa` | `b6aef7aa` | idéntico |
| Issue Policy Guard | `04b20fcd` | `04b20fcd` | idéntico |
| Quotation Data Guard | `b06966a4` | `b06966a4` | idéntico |
| Error Handler | `86bd7ca0` | `86bd7ca0` | idéntico |

**Cero nodos de más, cero de menos, cero parámetros distintos, conexiones idénticas.** La red de seguridad está donde tiene que estar y dice la verdad.

## Dos hallazgos que no buscaba

### 1. La tabla de `CLAUDE.md` llevaba semanas mintiendo por omisión

Decía **cinco** workflows vivos y el bot con «229 nodos (24 ago)». Hay **nueve activos**: faltaban `Discount Application Poller` (68 nodos), `Error Handler`, `Issue Policy Guard` y `Quotation Data Guard` — los tres últimos son sub-workflows por los que pasa la emisión y la consulta de cotización, o sea, camino crítico.

Corregido en el mismo commit. **Y le quité la columna de recuento de nodos**: es estado, envejece sola y no se usa para verificar nada —la propia nota de al lado ya manda verificar por `versionId`—. Hay además un décimo workflow **inactivo**, `#135 CANDIDATO PROD — NO ACTIVAR` (`fqdSLZ5vv2RBtnWE`, 297 nodos), que no tiene espejo en `main`; queda anotado para que nadie lo confunda con el vivo.

### 2. Un JSON con `versionId` heredado, en una rama del `#144`

Buscando la historia me salió una foto de **325 nodos** con el `versionId 5792ebd1` — el mismo que otra de **295**. No es un descuadre de PROD: vive en `feature/issue-144-payment-reminder-context-optout`, **fuera de `main`**, y el clon del ejecutor está parado en `stg`, por eso apareció al listar sin filtrar.

Pero deja una trampa apuntada: **un fichero de trabajo hereda el `versionId` del grafo del que salió**. Si alguien lo importa fiándose de ese campo, el espejo miente con toda la apariencia de verdad. La regla «verificar por `versionId`» solo vale contra la API, nunca leyendo el JSON del repo.

## Lo que me llevo de método

**Un versionId no lleva escrito de qué momento es.** Rotulé como «grafo final del día» el del penúltimo paquete, y al día siguiente eso se lee como seis nodos aparecidos de la nada. La foto de cierre tiene que citar el estado **después del último viaje**, o no citar ninguno.

---

*Ámbito: instancia n8n de PROD (`n8n.srv1325340.hstgr.cloud`) y `aibanez82/Agente-n8n:origin/main`, medido el 3 sep 2026. Horas en CDMX.*

Agente: Arquitecto-IA-Qualitas
