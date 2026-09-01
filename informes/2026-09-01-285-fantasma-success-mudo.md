# `#285` — tercera vuelta, alcance corregido: el teléfono sin sesión muere en un `success` MUDO; la guarda sigue sin correr

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas
> Responde a: tu corrección de alcance en `aguayo-co/HYL-WAI#285` (comentario 19:16Z):
> *«Reproducción correcta, y no necesita fixture: un turno de texto desde un teléfono que no
> exista en whatsapp_sessions»*.
> Grafo vivo STG: `dNqtM20ij6ecZYAX`, **`versionId 9d98ed2e`**, 305 nodos, updatedAt 22:40:09Z
> (posterior a los imports del `#273`).

## Resultado en una línea

Turno de texto desde **`QA-285-FANTASMA`** (sin dígitos, **0 filas** en `whatsapp_sessions`,
verificado antes): la ejecución **26913** recorre **la misma ruta que tu `22537` hasta
`Fallback Flag` incluido**, el `AI Agent` **compone una respuesta de fallback válida**… y
`Authority Lost?` la manda a **`Terminal 240 → Terminal Sink`**. Termina en **`status=success`**.
**Ningún nodo `Claim*` corre → `GUARDA_DELIBERADA_285` no aparece. El bigint tampoco — porque el
nodo que lo producía ya ni se alcanza.** Distinción del §4: **NO corrió** — no es *corrió y se
abstuvo*, y no es el fence.

## La medición, por nodo (exec 26913, `success`, último nodo `Buffer Purge Done`)

| Nodo | Salida literal |
|---|---|
| `Resolve Session` | `{"match_count":0,"matches":[]}` — **idéntico a tu 22537** |
| `Fallback Flag` | `{"quotationId":null,"hasQuotationId":false,"shouldShowFallback":true,"isNewSession":true,"conversationPhase":"fallback","sessionData":null}` — **idéntico a tu 22537** |
| `Get Quotation Data` | ⛔ `Bad request - please check your parameters` (tool llamada con `quotationId=null`; error visible solo dentro de `runData`, la ejecución global es `success`) |
| `AI Agent` | compuso: *«Tuve un problema técnico al consultar tu información… te atiende una persona por Whatsapp… [enlace]»* `[phase:fallback]` — **una respuesta razonable que jamás sale** |
| `Update Phase in DB` | `{"writer_rows":0}` (no hay fila que actualizar) |
| `Authority Lost?` | `writerRows=0` → OUT0 |
| `Route Terminal 240` | `{"ruta":"silencio","motivo":"authority_lost_sin_sesion"}` |
| `Claim Main Reply Outbound` (y los otros 5 `Claim*`) | **AUSENTES de la traza** |
| Envíos / Meta | **cero nodos de envío ejecutados** |

## Dónde diverge de tu 22537 — y es la divergencia que importa

En tu 22537 (PROD, grafo de entonces): `Update Phase in DB` **NO corrió**, `Authority Lost?`
**NO corrió**, y el turno **llegó a `Claim`** y reventó con `bigint: "conector:whatsapp"` —
ruidoso, pero visible.

En el grafo actual de STG (`9d98ed2e`): el mismo turno **sí pasa por `Update Phase in DB`**
(`writer_rows=0`) y `Authority Lost?` lo desvía a `Terminal 240` **antes** del carril de salida.
Consecuencia medida, no dictamen:

- **El corrimiento de binds ya no ocurre** — pero *vacuamente*: el nodo que lo sufría ya no corre
  para este caso.
- **La guarda del paso 1 es inalcanzable también por la vía corregida.** Está viva en el grafo
  (los 6 `Claim * Outbound` llevan `GUARDA_DELIBERADA_285` y el centinela `__NULO__` está en 7
  nodos — **el paso 1 sobrevivió a los imports del `#273`, no hay regresión de artefacto**), pero
  ningún camino de «teléfono sin sesión viva» pasa hoy por ellos.
- **El caso patológico cambió de forma: de error ruidoso a `success` mudo.** Hoy un teléfono sin
  sesión viva produce una ejecución verde, con una respuesta compuesta y tirada en `Terminal Sink`,
  cero error, cero rastro operativo. Contra el criterio del handoff — *«PASS es que el fallo se
  vea»* — **esto es lo contrario: el fallo dejó de verse**.

Nota al margen, ya conocida, no la reabro: la respuesta de fallback lleva el número de atención
humana en el copy (`aguayo-co/HYL-WAI#257`).

## Residuo declarado

| Qué | Estado |
|---|---|
| `whatsapp_sessions` / `n8n_chat_histories` / `n8n_outbound_dispatch` de `QA-285-FANTASMA` | **0 / 0 / 0 filas** — nada que limpiar |
| Ejecución | 26913 (`success`, `Buffer Purge Done`; el buffer se purga solo) |
| Meta / envíos | **cero** |
| Sesiones reales | **intactas** (cero UPDATE; sin fixture, como pediste) |
| `QA-SUITE-285` (vuelta 1) | sigue conservada, sin tocar |

```
🧪 QA REPORT — 1 sep 2026 · #285 acreditación vía teléfono inexistente (STG, versionId 9d98ed2e)
Triggered by: fix verificado (alcance corregido del Arquitecto, 19:16Z)

❌ FAIL  1   ✅ PASS 0   ⚠️ WARN 0

FALLOS:
❌ [n8n STG] La guarda GUARDA_DELIBERADA_285 no corre para el ámbito real del #285
   Query/Check: inyección firmada, texto plano, from=QA-285-FANTASMA (0 filas en whatsapp_sessions) → exec 26913
   Resultado: success mudo — AI Agent compone respuesta, Authority Lost? (writerRows=0) → Terminal 240
              {ruta:silencio, motivo:authority_lost_sin_sesion}; ningún Claim* en la traza;
              ni bigint ni GUARDA_DELIBERADA_285 en ninguna salida
   Esperado: NO bigint (se cumple, vacuamente) y SÍ error visible con la guarda (NO se cumple)

Distinción §4: NO corrió (nodos ausentes de la traza) — no es abstención, no es el fence.
Artefacto del paso 1 intacto en el grafo (6 Claim* con guarda, __NULO__ en 7) — inalcanzable, no ausente.
```

No dictamino si el `#285` está resuelto — no lo está: el cliente sigue sin respuesta, y ahora
además sin error que lo delate. La vía para que el fallo «se vea» en el grafo actual —mover la
visibilidad a `Route Terminal 240`/`Terminal Sink`, o dejar que el carril de fallback con
`isNewSession=true` llegue a un `Claim`— la decides tú.

— Agente QA & Testing
