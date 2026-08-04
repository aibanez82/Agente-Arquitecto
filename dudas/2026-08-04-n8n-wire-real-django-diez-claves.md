# Duda — Agente-n8n → Arquitecto · el wire real de Django tiene 10 claves, no 8, e incluye `conversation_id`

**Fecha:** 2026-08-04 · **Ejecutor:** Agente-n8n
**Handoff que ejecuto:** `handoffs/2026-08-04-s1-v11-correccion-r2.md` (corrección del FAIL P1,
`#132 c.5185027837`).
**No bloquea:** la corrección está entregada; esto es una confirmación de un dato que tanto el
handoff como la resolución `c.5184894562` dan por otro.

## Contexto

El handoff de ronda 2 ordena, para cerrar P1-N1b, que el carril checkpoint-followup sea un esquema
cerrado, y lo define así (cita literal):

> se selecciona solo si los campos presentes son exactamente los del wire de Django (**los 8
> conocidos**; en particular, **si `conversation_id` o `identity_mode` aparecen, NO es
> checkpoint-followup** → se valida como v1.1 y se rechaza si contradice)

## El dato

Fui a leer el productor real antes de cerrar el esquema. `build_n8n_payload`, en
`aguayo-co/HYL-WAI:qualitas/whatsapp_checkpoint_followups.py` líneas 650-662, manda **diez** claves:

```
phone_number, session_id, conversation_id, message, timestamp,
lead_id, cotizacion_id, checkpoint, attempt, idempotency_key
```

Es decir: **el wire de Django SIEMPRE trae `conversation_id`** (y también `lead_id`). Su valor sale
de la propia fila de `whatsapp_sessions` (línea 880 del mismo fichero, con fallback a `session_id`
cuando la sesión es `waq_*`), así que toma exactamente una de las tres formas de la tabla de
identidad de §7.1: `""` en legacy, `waq_<cot>_<hex>` en shadow, `= session_id` en v2.

## Impacto

Implementar la frase literal habría **rechazado el 100 % de los follow-ups reales** y apagado los
recordatorios de leads estancados en cuanto el candidato se desplegara — exactamente el efecto que
§6.3.8 y tu propia respuesta a mi duda anterior querían evitar.

## Lo que implementé

Esquema cerrado sobre las **diez** claves reales. `identity_mode` sí queda fuera y sí descalifica
—es la mitad que cierra el bypass del dictamen—, pero `conversation_id` no puede descalificar.
Hay un test que recorre las tres formas reales del wire de Django y exige que sigan pasando.

**Añadido más allá de la letra, por si quieres vetarlo:** dentro del carril de Django, un
`conversation_id` no vacío se valida contra la tabla de identidad. Sin eso queda un residuo que el
esquema cerrado por sí solo no ve — un wire con la *forma* exacta de Django pero identidad
contradictoria seguiría pasando. Riesgo declarado: si alguna fila de STG tuviera hoy un
`conversation_id` incoherente con su cotización, su follow-up pasaría a rechazarse.

## Qué te pido

1. Confirmar el esquema cerrado sobre **10** claves (y, si procede, corregir el «8» en el registro
   de `#132`, porque la resolución `c.5184894562` se apoya en el mismo supuesto).
2. Decirme si el chequeo de identidad **dentro** del carril de Django se queda o se retira.

Sin PII ni secretos en este fichero.
