# Duda #552 — la respuesta del grafo para «mándame la liga» sin póliza: cómo se envía y cómo queda en memoria

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-552-mandame-la-liga-antes-de-emitir.md`. **Estado:** medido, sin construir. STG
`4b1bf2f4` sin tocar.

## Lo medido (STG `4b1bf2f4`)

- **Por dónde entra hoy:** `Parse Router Output` lleva un override `#207` (`esPeticionExplicitaDeLiga`: menciona
  liga/link/enlace + pago, o fase `payment_pending`, + verbo de entrega) que pone `intent='contracting'` → `AI Agent` →
  tool `Ensure Payment Link`. Es lo que pasó en `waq_4316`. **El punto de intercepción es ese mismo nodo:** si la petición
  es explícita y `sessionData.policyData.numero_poliza` está vacío, el grafo contesta el texto de Alberto **sin pasar por el
  agente**. El caso (b), con póliza, no cambia.
- **El problema de la memoria:** si el agente no corre, ni la fila `human` del cliente ni la `ai` del bot llegan a
  `n8n_chat_histories`. `Sync Memory With Sent Reply` solo **ajusta** la última fila `ai` existente. Sin memoria, en el turno
  siguiente el modelo no sabría que el cliente pidió la liga ni qué le dijimos, y «la conversación sigue capturando» quedaría
  coja. Le pasa hoy también a `Guardrail Error Safe Reply` y al aviso de jailbreak; no lo toco.

## Dos formas

- **(A) Recomendada: calcar el carril del guard del descuento.** Un carril propio con el mismo patrón que `Normal Guard`:
  copy → `Claim … Outbound` (reserva del fence, `dispatch_id` propio, p. ej. `d552.reply`) → `IF Send?` →
  **`Persist Human Row (552)`** (la fuente única del #342 **verbatim**: sería su 12.º consumidor) → envío → `Settle Sent` →
  **`Build AI Row`/`Insert Turn History`**: la fila `ai` solo si el envío salió, como hace el guard → `Buffer Mark Done`.
  Son unos 10 nodos copiados de un carril ya probado; el nombre y el texto cambian. Memoria completa y rastro en el fence.
- **(B) Más corta: reutilizar la cadena principal de respuesta.** Copy → `Stash Main Reply Payload`, que pasa por las
  guardas de salida: Leak, Figure y Email. La memoria iría por una **rama lateral** (`Persist Human Row` + fila `ai`). Pero la
  fila `ai` se escribiría **antes** de saber si el envío salió: si Meta falla, la memoria dice algo que el cliente no leyó.
  Lo que el #500 B quiso evitar.

En los dos casos el resto no se toca: el `systemMessage`, Django, el caso (b) y la tool.

## Lo que hago sin preguntar (te lo cuento)

- **Texto literal de Alberto** como único mensaje del turno. «La conversación sigue» significa el turno siguiente: en
  `greeting` el agente retoma la selección con la memoria completa. No añado una segunda burbuja ni una pregunta que no
  esté en su texto.
- **Detección:** reutilizo **exactamente** `esPeticionExplicitaDeLiga` y le añado `sin póliza`. No es una regex nueva.

¿(A) o (B)?

— Agente n8n
