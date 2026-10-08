# Duda #551 v2 — la entrada por texto y la restricción de tools mientras solo hay contexto

**De:** Agente n8n · **Para:** Arquitecto · **8 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-08-551-recovery-contrato-v2.md` (`04ce0b76`) y al plan de Juan (§3 y §5).
**Estado:** construyo ya el camino del **botón** contra el contrato v2. No depende de esto y es lo que rompía la campaña 101: DTO
de 11 claves sin `conversation_id`, `event_id` estable, 14 claves y teléfonos. **La entrada por texto espera tu respuesta.**

## Lo medido (bot STG `f2c599f1`)

- **Hoy el botón es exclusivo por la forma del payload.** `Recovery Terminal?` (entre `QC Terminal?` y `Resolve Session`) corta el
  camino normal si el payload empieza por `recovery-`. Con un texto no hay forma sintáctica de saberlo: hay que mirar la BD antes
  de que el camino normal resuelva la sesión.
- **Tools del `AI Agent` (14):** `Issue Policy`, `Get Quotation Data`, `Ensure Payment Link`, `Save Quotation Selection`,
  `Get Emission Record`, `Save Policy Data`, `Listar/Cambiar Cotizacion`, `Save Group1/2/3`, etc.
  **`RAG IA Agent` (5):** `Get Quotation Data`, las dos de KB y `Listar/Cambiar Cotizacion`. **No tiene emisión ni pago.**

## Propuesta 1 — la entrada por texto (§3 del plan, «resolver sin adivinar»)

Un nodo **`Recovery Text Claim`** en el camino normal, en el mismo punto que `Recovery Terminal?` y **antes** de `Resolve Session`.
Es una consulta de solo lectura, bajo el teléfono canónico y solo para mensajes de texto. **Reclama el turno solo si:**

1. **El texto trae referencia:** `context.id` de Meta = `provider_message_id` de un outbound Recovery enviado, con destino
   canónico igual al `from`. Si no coincide → no reclama.
2. **O no trae referencia, pero** hay **exactamente un** participante Recovery enviado a ese teléfono canónico **cuyo par no esté
   ya activado en n8n**, **ninguna otra conversación `open`/`active`** del teléfono y **ningún control humano**.

**Si no reclama, el turno sigue por el camino regular como hoy.** No se termina sin respuesta: un lead que recibió campaña y tiene
una conversación regular viva sigue atendido por esa conversación, que no habla de la póliza importada. Es mi lectura de «no se
responde sobre la póliza desde una sesión vieja». **Si la quieres más estricta** (no responder nada ante la ambigüedad), dímelo.

**Si reclama:**
- entra al carril Recovery con `action = prepare_context` y `reply_to_message_id` = `context.id`, o null;
- tras `context_ready`, activa el par (mismo SQL que ya existe), guarda las 14 claves y el marcador;
- **devuelve el turno al camino normal**, que ahora resuelve la sesión nueva (única `active`) y contesta el texto real **una sola
  vez**. La memoria se guarda como siempre.

Una sesión Recovery ya activada no se reclama otra vez: la resuelve `Resolve Session`.

**Botón:** como hoy, más el DTO v2. Texto → botón reutiliza el par, porque Django devuelve el mismo.

## Propuesta 2 — restricción de tools solo con contexto (§5.5): aquí necesito tu decisión

**Marcador:** `captured_data.recovery_solo_contexto = true`, que pone el `prepare_context` y quita el `success` del botón.

- **(A) Recomendada: forzar el camino consultivo.** `Parse Router Output` manda al `RAG IA Agent` todo turno con el marcador. El RAG
  **no tiene** emisión ni pago. Sus tools de cotización solo ven el **borrador** de Django, sin precios (es la `result_quote`), así
  que no pueden dar una prima.
  - Es una decisión del grafo, no del prompt.
  - **Límite:** `Get Quotation Data` sigue expuesta, aunque sobre un borrador sin precio.
- **(B) Bloqueo en cada tool:** un chequeo del marcador dentro de los sub-workflows guarda (`Quotation Data Guard`, `Issue Policy
  Guard`, `Quotation Selection Guard`…), devolviendo `recovery_solo_contexto`. Más estricta, pero toca 3-4 workflows y deja
  `Ensure Payment Link` (httpRequestTool) fuera: la cubre el #552 sin póliza.

**Y una consecuencia de copy:** con el marcador, «quiero contratar» tiene que llevar al botón «Ver promo» (§5.5). Ese texto **no lo
tengo**. Si lo escribe el modelo, es prompt; si es determinista, es copy de Mejoras o de Alberto. **¿Cuál?**

¿(A) o (B), y quién pone el texto de «pulsa Ver promo»?

— Agente n8n
