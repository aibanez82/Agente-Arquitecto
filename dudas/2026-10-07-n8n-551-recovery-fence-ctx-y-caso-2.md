# Duda #551 — Recovery con sesión propuesta: tres puntos de diseño antes de importar en STG

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-551-recovery-sesion-propuesta-405.md` (`d3f86e59`).
**Estado:** construyo en la rama con la opción que recomiendo en cada punto. **No importo en STG hasta tu respuesta.**
STG sin tocar: bot `9481dc31`.

## Lo medido (bot STG `9481dc31`, BD STG, HYL-WAI `origin/main` `d66696e6`)

- **Contrato §8.1** (`customer-recovery-api-v1.2.0.md`): leído en `origin/main`. Cuadra con tu resumen.
- **El carril hoy** sigue esta cadena:
  `Route Recovery Response` → `IF Recovery Success?` → `Recovery Quote Ready` → `Download Recovery PDF` →
  `Resolve Recovery Control` → `Claim Recovery Outbound` (fence #481) → `Upload` / `Send`.
  `Route Recovery Response` descarta `session_id` y `conversation_id`.
- **Quién crea las sesiones:** ningún workflow de STG inserta en `whatsapp_sessions` (barridos los 8 activos y los inactivos por
  API). Las crea Django (`qualitas/whatsapp_conversations.py`, `_upsert_whatsapp_session_with_cursor`) con
  `conversation_phase='greeting'`, `status='open'` y `captured_data={}`. El único INSERT de n8n está en la función
  `n8n_discount_conversation_activate` (#156), y hereda fase y captura del source.
- **Vista `conversation_control_v1`:** una fila nueva con `session_id = conversation_id = waq_<q>_<hex>`, lead y quote
  resultado, sin claims y `human_takeover=false` con su control y epoch a NULL da `identity_mode=v2`,
  `handoff_state=stable_automation`, `automation_gate=eligible` y `authority_epoch=0`. El fence la admite.

## Punto 1 — el fence del #481 tiene que reservar sobre la sesión propuesta (recomiendo hacerlo)

`Resolve Recovery Control` busca la sesión por `source_lead_id`, el lead de **origen**. Con el diseño nuevo:
- Si se deja así, un participante frío (sin conversación previa, como el 67 de Juan) **no tiene fila**. El reserve devuelve
  `puede_intentar=false` y **el PDF no sale nunca**. Rompe el caso 1.
- Si el teléfono tuviera una sesión vieja del lead de origen, el envío se reservaría sobre **otra** conversación, no sobre la
  recién activada.

**Propuesta:** `Resolve Recovery Control` lee `conversation_control_v1` por el `session_id` **propuesto**, ya validado y
activado. El fence sigue integrado y con la misma reserva; solo cambia la identidad que se le pasa. No lo leo como «tocar el
#481», pero cambia su entrada, así que te lo digo.

## Punto 2 — `previous_policy` visible sin tocar el `systemMessage` (recomiendo `[CTX:]`)

Hoy `captured_data` llega al AI Agent por dos sitios:
- `Merge Session Data`, en `sessionData.capturedData`;
- el prefijo `[CTX: … ]` del campo `text` del AI Agent. Ahí ya viaja `serie=` cuando existe `discount_serie`.

**Propuesta:**
- `Merge Session Data` añade `polizaAnterior`, una cadena con los cinco campos de Django tal cual, sin reinterpretar:
  `numero=POL-… | vigencia=2025-09-01→2026-09-01 | cobertura=AMPLIA | pago=MONTHLY`. Solo si `captured_data.previous_policy`
  existe.
- `AI Agent.text` añade `| poliza_anterior=…` **solo** en ese caso. Mismo patrón que `serie=`.
- El `systemMessage` no se toca.

**Pregunta:** el `RAG IA Agent` tiene su propio `[CTX:]`, más corto: sin checkpoint, sin `serie` y sin `descuento`. ¿Le añado
también `poliza_anterior`? Por la regla de «dos agentes, mismas preguntas» diría que sí. Pero hasta hoy su `[CTX:]` no ha
llevado datos de captura, y no lo extiendo sin tu visto bueno.

## Punto 3 — el caso 2 de la aceptación no es contestable con lo que entrega Django

`previous_policy` trae `policy_number`, `valid_from`, `valid_to`, `coverage` y `payment_term`. **No trae ningún importe.**
«¿Cuánto pagaba antes?» no se puede contestar con ese dato, y el bot **no debe** inventarlo (#500).

**Propuesta:** el caso 2 pasa a ser «¿qué cobertura tenía antes?» o «¿hasta cuándo me cubría?». Así se acredita la lectura
de `previous_policy` en la sesión nueva. Añado un caso 2b, «¿cuánto pagaba antes?», que debe contestar que no tiene ese dato,
sin cifra.

## El resto, decidido por mí (lo verás en el informe)

- **Orden:** `Recovery Quote Ready` → **validar el sobre** → **control humano + crear y activar** (un solo SQL, con advisory
  lock por teléfono canónico) → `Download Recovery PDF` → `Resolve Recovery Control` (por la sesión propuesta) → fence → envío.
  Nada se activa si el sobre no valida. Nada se envía si la activación no queda exacta.
- **Fila nueva:** teléfono canónico (`n8n_port132_canonical_phone`, `52`+10), `greeting`/`open` como Django,
  `captured_data = {previous_policy: <de Django>}` y `lead_id`/`quotation_id` resultado. Después se promociona a `active` con
  la semántica de `Apply Affinity Update`: misma allowlist, las demás del teléfono a `open`.
- **Idempotencia:** si la fila existe con los mismos valores, no duplica. Con valores distintos, o con el `conversation_id`
  asignado a otra sesión, **falla cerrado**.
- **Control humano:** si cualquier sesión del teléfono tiene `human_takeover`, no se crea, no se activa y no se envía. Queda
  anotado como en `Recovery Fence Denied`.
- **Replay** (`replayed=true`): mismo par, misma fila, sin duplicar. Vuelve a enviar el PDF solo si el fence lo permite, como hoy.

— Agente n8n
