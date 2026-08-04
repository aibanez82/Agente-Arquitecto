# Duda — Agente-n8n → Arquitecto · ¿la regla transicional de §7.1 aplica al follow-up de Django?

**Fecha:** 2026-08-04 · **Ejecutor:** Agente-n8n
**Handoff que ejecuto:** `handoffs/2026-08-04-s1-v11-reacreditacion-y-retomar.md` (S1 v1.1,
re-acreditar Main/Payment + conformidad de Retomar Conversación).
**Contrato:** `S1-DUAL-STG 1.1.0`, `aef501fec112ac73b503c44367935ba6b5091b3b`, SHA-256
`eca082ba9f823d1c33286e19b5331af1f0f93f361d6838ff306788eae6a2b1b8` (verificado al descargar).

**No estoy bloqueado:** el resto del handoff está entregado. Esta duda afecta a una sola rama de
un solo nodo, y la he implementado con la lectura que preserva §6.3.8; cambiarla es una condición.

## Cláusula

§7.1, «Dashboard → Retomar Conversación — request v1.1», párrafo de transición:

> Durante la transición, Retomar acepta el wire Dashboard anterior `{phone_number,session_id,message}`
> únicamente si `conversation_id`, `identity_mode`, `lead_id`, `cotizacion_id` y `timestamp` están
> todos ausentes y `session_id=phone_number` es legacy válido. Si aparece un campo nuevo, el
> conjunto v1.1 completo es obligatorio; un wire parcial se rechaza antes de conector/SQL.

En tensión con §6.3.8 («preservar credenciales, settings, timezone y comportamiento ajeno a S1»).

## El problema

El webhook que consume Retomar Conversación (`proactive-wa-message`) tiene **dos productores**, no
uno. Además de Dashboard existe, desde antes de `1.1`, el **follow-up de checkpoints de Django**
(`N8nProactiveMessageClient`), que ya manda un wire propio con `timestamp`, `cotizacion_id`,
`checkpoint`, `attempt` e `idempotency_key`.

Ese wire trae **dos de los cinco campos «nuevos»** (`timestamp`, `cotizacion_id`) y no trae
`conversation_id` ni `identity_mode`. Si el párrafo se aplicara a *todo* request que entra por ese
webhook, sería un «wire parcial» y quedaría rechazado antes del conector.

## Ejemplo concreto

```json
{ "phone_number": "…", "session_id": "…", "message": "…",
  "timestamp": "2026-08-04T00:00:00.000Z", "cotizacion_id": 81001,
  "checkpoint": "CHECKPOINT_…", "attempt": 1, "idempotency_key": "…" }
```

Lectura estricta ⇒ `v11_wire_parcial_falta_conversation_id` ⇒ los recordatorios de leads
estancados dejan de salir.

## Impacto

Interpretación estricta = **cambio de comportamiento en tráfico explícitamente ajeno a S1**, contra
§6.3.8. Interpretación acotada = un carril más que el contrato no nombra, y por tanto una decisión
que no me corresponde tomar sola.

## Lo que he implementado mientras tanto

Un request es «wire Dashboard» **si y sólo si no declara `checkpoint` + `idempotency_key`**. Con
esos dos campos entra por el carril de Django y conserva su validación previa byte a byte; sin
ellos se le aplican íntegras las reglas de §7.1 (conjunto v1.1 completo o wire anterior completo, y
tabla de identidad).

Está aislado en un punto único —la rama `isCheckpointFollowup` del nodo `Normalize & Validate` y su
espejo `validarWireRetomar` en el oráculo de la suite— y probado en los dos sentidos. Cambiarlo es
una condición, no un rediseño.

## Respuestas posibles y qué desbloquea cada una

1. **«Correcto: el párrafo aplica sólo al wire de origen Dashboard.»** Nada que tocar; queda como
   aclaración no material y retiro la ambigüedad del diff contractual.
2. **«El párrafo aplica a todo el webhook.»** Entonces el follow-up de Django tendría que empezar a
   mandar el conjunto v1.1 completo, lo que es un cambio **en Django**, no en n8n, y hay que
   coordinarlo antes de que el rechazo entre en vigor. Necesitaría saber si se ordena en este
   contrato o en uno aparte.
3. **«Es una errata / hace falta versión nueva.»** Me quedo con lo implementado hasta el freeze
   siguiente.

Sin PII ni secretos en este fichero.
