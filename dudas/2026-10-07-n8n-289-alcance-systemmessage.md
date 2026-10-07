# Duda #289 — el PR #109 también toca el `systemMessage`; el handoff pide «solo los dos consumidores»

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-289-ya-pagada-no-es-sin-liga.md`.
**Estado:** PARO antes de construir. STG sin tocar (`1b55efa8`).

## Lo medido

El builder del PR `#109` (`scripts/207/build-payment-link-ensure.js`, `655095f`) transforma **cuatro** cosas, no dos:

1. `Ensure Payment Link` (httpRequestTool): `toolDescription` con la regla de `already_paid`.
2. `Payment Status Reply` (el consumidor de `Ensure Payment Status`): su `jsCode` reconoce exactamente
   `200 {"status":"already_paid"}` → «Tu pago ya está confirmado y no tienes nada pendiente».
3. **El `systemMessage` del `AI Agent`:** añade una línea `already_paid` al bloque `ASEGURAR LIGA DE PAGO — HYL-WAI #207:`.
   En STG ese bloque está y no menciona `already_paid`.
4. El parser del Intent Router (regla #207). Lo mantiene igual si ya existe.

Tu handoff pide «mismo alcance que el #109» y, a la vez, un diff de «**solo los dos consumidores**». Además, en este plan el
`systemMessage` no se toca. Las dos cosas no caben juntas.

## Opciones

- **(A) Recomendada: sin tocar el `systemMessage`.** La regla de `already_paid` va solo en la `toolDescription` de
  `Ensure Payment Link`. El modelo la ve en cada llamada, porque es el resultado de esa misma tool. `Payment Status Reply` es
  determinista. Diff: los dos nodos. **Riesgo:** sin la línea del prompt, el modelo podría resumir la frase en vez de decirla
  literal; el caso 2 lo mide.
- **(B) Como el #109:** también la línea del `systemMessage`. Es el alcance completo, pero toca el prompt.

## Datos de prueba (BD STG, solo lectura): hay de sobra, no hace falta fabricar nada

- **Caso 2 (pagada):** póliza 1552 (cotización 2382), 0 cuotas pendientes y 1 pagada. Sesión `waq_2382_8b2fed1e7293`
  `open`/`payment_pending` en el teléfono de Alberto. También sirven 1420, 1421 y 1455.
- **Caso 3 (sin pagar):** póliza 1618 (cotización 2189), con 1 cuota pendiente. Su sesión `waq_2189_ece01c1fca28` está
  **cerrada**: la abriría solo para la prueba y la cerraría al terminar. Que haya «liga disponible» depende del calendario
  de cuotas de Django ese día; si da `not_available` o `preparing`, lo reporto tal cual.

¿(A) o (B)? Con tu respuesta construyo e importo.

— Agente n8n
