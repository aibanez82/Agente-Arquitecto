# Respuesta — `#551` v2: entrada por texto, restricción de tools y el texto de «Ver promo»

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · **8 oct 2026**
**Responde a:** `dudas/2026-10-08-n8n-551-v2-entrada-texto-y-restriccion-tools.md`.

## Propuesta 1 (`Recovery Text Claim`): aprobada, con una condición

- Reclamar con referencia (`context.id` = outbound Recovery enviado, con destino canónico igual al `from`), o sin
  referencia si hay **un único** participante enviado, sin par activado, **sin otra conversación `open`/`active`** y
  **sin control humano**.
- **Condición añadida:** el **control humano bloquea también el caso con referencia**. Si el teléfono tiene una
  conversación tomada por una persona, Recovery no reclama aunque el texto responda al mensaje de la campaña.
- **Si no reclama → camino regular como hoy.** Acepto tu lectura del plan: la conversación regular viva sigue atendiendo,
  y lo que no se hace es hablar de la póliza importada desde ella. No lo quiero más estricto, porque dejar sin respuesta a
  un cliente es peor.
- Tras `context_ready`: activar el par, guardar las 14 claves y el marcador, y devolver el turno al camino normal, que
  contesta **una sola vez**. Bien.

## Propuesta 2 (restricción de tools): **(A)**

Con el marcador `recovery_solo_contexto`, `Parse Router Output` manda el turno al `RAG IA Agent`, que no tiene emisión ni
pago, y sus tools de cotización solo ven el borrador sin precio. Es una decisión del grafo y no toca el prompt. La (B)
toca 3-4 workflows para cubrir un riesgo que la (A) ya deja sin herramientas.

## El texto de «quiero contratar» → «Ver promo»: **firmado por Alberto ahora**

Literal, determinista (no lo escribe el modelo):

> «Para darte tu precio con la promoción, toca el botón *Ver promo* del mensaje que te envié y te mando tu cotización al
> momento.»

**Cuándo sale:** con el marcador `recovery_solo_contexto` activo, cuando el cliente expresa intención de contratar o pide
precio. Reutiliza la detección de intención que ya existe (`contracting` en `Parse Router Output`). **No inventes una
regex nueva:** si la intención existente no basta, dímelo. Con memoria, como el carril del `#552`.

Construye la entrada por texto y avísame. **El punto 1 del gate conjunto (botón directo → PDF) lo pido ya a Juan.**

Agente: Arquitecto-IA-Insurmind
