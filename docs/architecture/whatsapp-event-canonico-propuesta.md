# Propuesta de arquitectura — tabla canónica `whatsapp_event`

> Autor: Arquitecto-IA-Qualitas · Fecha: 1 julio 2026
> Estado: **plan de destino documentado, sin decisión de implementar** — no bloquea nada activo.
> Origen: discusión sobre por qué seguir una conversación de WhatsApp en el Dashboard es tedioso
> (hay que cruzar `n8n_chat_histories` + `qualitas_whatsappmessage` a mano).

## Problema de fondo

Cada sistema que toca WhatsApp mantiene su propia tabla, sin contrato compartido:

- Django escribe `qualitas_whatsappmessage` (con `sent_at` real).
- n8n escribe `n8n_chat_histories` (sin timestamp — ver pendiente de `ALTER TABLE created_at`).
- El Dashboard ya escribe directo a `n8n_chat_histories` para mensajes proactivos.
- Kommo (en integración) va a sumar otra fuente más el día que se implemente.

Cada canal nuevo obliga al Dashboard (y a cualquier otro consumidor, como el Agente Mejoras
Conversación) a aprender un join nuevo. Además, los hitos de conversación (`confirmó cobertura`,
`dio VIN`, etc.) se detectan hoy con `BOOL_OR + ILIKE` sobre texto libre — frágil ante cualquier
cambio de copy en el bot.

## Propuesta

Una sola tabla de eventos de negocio, append-only, dueña del dominio "conversación WhatsApp de un
lead" (no de n8n, no de Django):

```sql
CREATE TABLE whatsapp_event (
  id              bigserial PRIMARY KEY,
  lead_id         bigint NOT NULL REFERENCES qualitas_lead(id),
  cotizacion_id   bigint REFERENCES qualitas_cotizacion(id),
  occurred_at     timestamptz NOT NULL DEFAULT now(),
  direction       varchar NOT NULL,   -- inbound | outbound
  source          varchar NOT NULL,   -- django | n8n | dashboard_proactive | kommo
  event_type      varchar NOT NULL,   -- message_sent, message_received, template_sent,
                                      -- milestone_coverage_confirmed, milestone_vin_captured...
  content         text,
  template_name   varchar,
  status          varchar,            -- sent | failed | received
  provider_message_id varchar,        -- wamid
  metadata        jsonb NOT NULL DEFAULT '{}'
);
```

Ya existe un precedente parcial de este patrón en `qualitas_leadactionevent` (usado hoy para
`whatsapp_initial_sent`, `whatsapp_followup_15m_sent`, con campo `source`). La propuesta es
generalizarlo para que sea el destino único de todo evento de WhatsApp, no solo los de Django.

## Qué gana

- Elimina el `ILIKE` frágil sobre texto libre — el propio nodo de n8n emite el `event_type`
  explícito al detectar un hito, en vez de inferirlo del contenido del mensaje después.
- El Dashboard y el Agente Mejoras Conversación leen una sola tabla, con orden real y semántica
  explícita — dejan de necesitar saber que existen `n8n_chat_histories` ni
  `qualitas_whatsappmessage` por separado.
- Escala a canales nuevos (Kommo, lo que sea) sin tocar al consumidor — solo agregan filas con su
  propio `source`.
- No rompe la memoria interna de n8n: `n8n_chat_histories` se queda como detalle de implementación
  del nodo de memoria de LangChain (el AI Agent la sigue necesitando en ese formato para su
  contexto); se le agrega un paso adicional en el workflow que además escribe al `whatsapp_event`
  canónico — patrón *outbox*, no reemplazo.

## Costo

Cambio de arquitectura real, no una migración de una tarde: toca el workflow de n8n (nodo nuevo de
escritura), el modelo de Django (Juan), y decidir si se hace backfill de datos históricos. Se deja
como plan de destino a evaluar más adelante — el parche de corto plazo (`ALTER TABLE
n8n_chat_histories ADD COLUMN created_at`) resuelve el dolor inmediato sin este costo.
