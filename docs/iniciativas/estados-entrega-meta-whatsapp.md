# Estados de entrega de Meta WhatsApp → Django (HYL-WAI #126 / #127)

> Estado al 27 jul 2026. Tracker: `aguayo-co/HYL-WAI#126` (lado n8n, asignado a Alberto)
> y `#127` (lado Django, Juan). Abiertos por Juan el 27 jul tras el incidente de la
> cotización 3282 (mensajes "aceptados" por Meta que nunca llegaron al teléfono).

## Objetivo

n8n captura los eventos `entry[].changes[].value.statuses[]` de Meta (sent / delivered /
read / failed), los normaliza a un contrato JSON idempotente y los reenvía a un endpoint
interno de Django. Contrato propuesto completo en el cuerpo del #126.

## Diagnóstico del Arquitecto (verificado 27 jul contra export PROD)

- El bot PROD descarta los estados en la puerta: `WhatsApp Message Trigger` tiene
  `updates: ["messages"]` + `messageStatusUpdates: []`; 0 referencias a `statuses` en los
  113 nodos.
- **Restricción dura:** Meta permite un solo callback por Facebook App (apunta al bot
  PROD) → no puede haber workflow receptor aparte. La solución es habilitar
  `messageStatusUpdates` en el trigger existente y separar estados/mensajes en el PRIMER
  nodo tras el trigger (mismo patrón de inserción temprana que `quoteDocumentAction?`,
  #110).
- Riesgo operativo: cada mensaje saliente genera 2–3 eventos de estado → se multiplican
  las ejecuciones del workflow principal. La separación debe ser robusta a payloads
  malformados para que ningún estado alcance la rama conversacional.

## Puntos pactándose con Juan (comentario del 27 jul en el #126)

1. **Prueba E2E en STG imposible tal como la pide el issue** (un-callback-por-App: STG no
   recibe webhooks reales de Meta). Propuesto: matriz con payloads pineados + Execute
   Workflow en STG, luego E2E real controlada en PROD con rollback — precedente #110.
2. **Congelar contrato JSON antes de construir**: obligatorios vs opcionales; semántica de
   `conversation_id` (alinear con el conversation_id de resolución de sesión de n8n, no el
   `conversation.id` de Meta — o llevar ambos con nombres distintos); versionado
   `schema_version`; ruta y semántica de códigos HTTP del endpoint Django (2xx idempotente,
   4xx permanente, 5xx reintentable). Alinear nombres de campos con la propuesta durmiente
   `docs/architecture/whatsapp-event-canonico-propuesta.md`.

## Seguridad acordada

Secreto NUEVO dedicado n8n→Django (o HMAC), solo en credenciales n8n. Nunca reutilizar el
token de Meta ni `N8N_TOKEN` (ese además pendiente de rotación, HYL-WAI#130). Rotación en
dos fases (Django acepta ambos secretos durante la ventana).

## Próximos pasos

- [ ] OK de Juan a los 2 puntos (esperar respuesta en #126)
- [ ] Congelar contrato con el lado #127
- [ ] Handoff completo al Agente n8n (construcción en STG: rama de estados, idempotencia,
      reintentos con backoff, dead-letter con replay, observabilidad/redacción de PII)
- [ ] Matriz de pruebas pineadas en STG (4 estados, multi-statuses, duplicados, estado
      desconocido, 2xx/4xx/5xx/timeout, replay dead-letter)
- [ ] E2E real controlada en PROD + export a git de los workflows tocados

## Fuera de alcance (definido por Juan en #126)

Persistencia definitiva en BD, UI Wagtail/reportes, reenvío automático de fallidos,
cambios de plantillas.
