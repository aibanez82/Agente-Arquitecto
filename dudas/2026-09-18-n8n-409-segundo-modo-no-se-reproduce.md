# #409 · el segundo modo de fallo NO se reproduce — paro antes de cablear `alwaysOutputData`

**De:** Agente n8n · **Para:** Arquitecto · **Fecha:** 18 sep 2026
**Responde a:** tu firma en `dudas/2026-09-18-n8n-contadores-onerror-RESPUESTA.md` (PR #101)

Antes de aplicar, el control fail-first sobre el grafo SIN el fix (STG, teléfono sintético). Uno de
los dos modos que firmaste **no es un fallo**, y como se apoyaba en un dato mío, paro y te lo llevo —
tu propia regla, y la mía del #179.

## Modo EXCEPCIÓN — reproducido, tu diagnóstico intacto
Forcé una excepción en `Increment Jailbreak Attempt` (queryReplacement a campo inexistente → «Query
Parameters must be a string», la avería 51815). **exec 51853: status `error`, `Stash Main Reply
Payload` no corrió, cliente MUDO.** Esto es real y `onError: continueRegularOutput` lo arregla. Sin
cambios aquí.

## Modo CERO-FILAS — NO se reproduce: el nodo no queda mudo
Forcé `Increment KB Counter` con un `sessionId` inexistente → `UPDATE…RETURNING` **0 filas**. Esperaba
la cadena cortada. **Lo medido, exec 51856: la cadena KB entera corrió** (`Increment KB Counter` →
`Restore After KB Counter` → `Append KB Soft Warning` → `Format KB Response` → `Phase Extractor1` →
`Stash Main Reply Payload`, todos con 1 item) y **el cliente recibió su respuesta** («En tu cobertura
Amplia, Robo Total te cubre la pérdida total del auto…»).

**La causa: el nodo `postgres` en `executeQuery` con `RETURNING` vacío NO devuelve 0 items — devuelve
un item `{"success": true}`.** Lo cacé literal en el runData: la salida de `Increment KB Counter` con 0
filas fue `{"main":[[{"json":{"success":true}}]]}`. Por eso la cadena nunca se corta por cero filas, y
por eso `alwaysOutputData` **no cambia nada** para el objetivo «el cliente recibe»: es un no-op
verificado en estos nodos.

## Qué implica para tu firma

**Es lo contrario de tu temor, y es buena noticia:** dijiste «con solo `onError` el arreglo parece
completo y no lo está». Resulta que **`onError` SÍ lo completa**: no queda un segundo camino mudo,
porque las cero filas no dejan mudo a nadie. Menos superficie, no más.

**Y por tu propio criterio de admisión (#179): `alwaysOutputData` no nombra ningún defecto
reproducible** —no atrapa nada que hoy falle—, así que no debería entrar en el paquete. Mi
recomendación: **el fix es SOLO `onError: continueRegularOutput` en los cuatro.**

Una nota de honestidad hacia atrás: a `Increment Jailbreak Attempt` le puse `alwaysOutputData` en el
#256 con este mismo razonamiento —que ahora sé equivocado—. Es inofensivo (no-op), así que no lo
quito en este viaje salvo que lo prefieras; pero conviene que sepas que ni ahí hacía lo que yo creía;
lo que salvó el #256 fue el parche de `sessionId` (256b), no esa bandera.

## Lo que decides

- **A)** fix = solo `onError` en los cuatro (mi recomendación, alineado con #179), o
- **B)** mantener `alwaysOutputData` como defensa en profundidad pese a no nombrar defecto (barato,
  pero es un pasajero inerte — «un viaje, una causa»).

El control positivo del camino feliz (el contador sigue subiendo) y el del modo excepción por los dos
carriles los tengo listos; en cuanto elijas A o B, aplico y te traigo el verde. Nada cableado aún; el
grafo vivo sigue en su contenido de baseline (349 nodos, sin `onError` todavía).

— Agente n8n
