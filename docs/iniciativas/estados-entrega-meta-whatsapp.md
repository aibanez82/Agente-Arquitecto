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

---

## Revisión del 25 ago 2026 — medido en vivo, y el proyecto es más barato de lo que parecía

**Encargo de Alberto:** cómo capturarlos, **dónde guardarlos con la restricción de que n8n deje de
escribir en la BD**, y qué estados da Meta realmente, para decidir si vale la pena.

### Lo que sigue igual (reconfirmado contra el bot vivo de PROD, 229 nodos)

`WhatsApp Message Trigger`: `updates: ["messages"]`, `options.messageStatusUpdates: []`.
**Los estados siguen llegando a la puerta y tirándose.** Cero referencias a `statuses` en el grafo.

### Lo nuevo, y es lo que cambia la ecuación: **Django ya tiene la tabla**

Medido en la BD de PROD. `qualitas_whatsappmessage` tiene hoy:

| columna | contenido medido |
|---|---|
| `provider_message_id` | el **wamid** — **1.927 de 1.928 filas poblado** |
| `status` | `sent` 1.927 · `failed` 1 |
| `direction`, `phone_number`, `message_key`, `template_name` | poblados |

**Conclusión: `#127` no es «construir persistencia», es alimentar una columna que ya existe.** Y la
clave de idempotencia tampoco hay que inventarla: el `wamid` que Meta manda en cada evento de estado
es el mismo `provider_message_id` que Django ya guarda al enviar. El `JOIN` es directo.

Lo único que hoy hace `status` es registrarse **una vez**, en el momento del envío. Nunca avanza.

### Dónde se guardan: n8n no guarda nada, y eso ya era el diseño

La partición `#126` (capturar y reenviar) / `#127` (Django persiste) **ya deja a n8n sin estado**.
El deseo de desacoplar no obliga a rediseñar: obliga a **no ceder** durante la construcción.

**Y aquí está la tensión real, que hay que decidir antes de construir:** si n8n no escribe en la BD,
**no hay dónde poner la cola de reintentos**. Si Django está caído cuando llega un `failed`, ese
estado se pierde — Meta no reintenta indefinidamente y no hay replay.

| Opción | Coste |
|---|---|
| **A · Aceptar la pérdida** + dejar rastro en la ejecución de n8n | Gratis. Un estado de entrega perdido no descuadra dinero |
| B · Reintentos con backoff dentro de la ejecución | Acotados; se pierden si el proceso muere |
| C · Cola persistente (Redis, dead-letter con replay) | **Reintroduce por la puerta de atrás el acoplamiento que se quiere quitar** |

**Recomendación: A.** Estos eventos son informativos, no financieros. Montar infraestructura de cola
para no perder un `delivered` es pagar el precio del acoplamiento sin el beneficio.

### Qué estados da Meta, y cuáles valen

En `entry[].changes[].value.statuses[]`, cada evento trae `id` (wamid), `recipient_id`, `timestamp`,
`conversation{id, origin.type, expiration_timestamp}` y `pricing{billable, pricing_model, category}`.

| Estado | Qué significa | ¿Vale? |
|---|---|---|
| **`failed`** | No se entregó, con `errors[]`: código, título, detalle | **Sí, el más valioso.** Hoy si un mensaje falla nadie se entera y el bot cree que habló |
| **`delivered`** | Llegó al dispositivo | **Sí.** Distingue «Meta lo aceptó» de «llegó al teléfono» — es literalmente el incidente de la cotización 3282 que abrió el issue |
| `read` | El cliente lo abrió | **No.** Depende de que tenga activadas las confirmaciones de lectura; **su ausencia no prueba nada**. No construir métrica encima |
| `sent` | Meta lo aceptó | Redundante: ya lo sabemos, es lo que hoy escribe `status` |
| `conversation` + `pricing` | Coste por conversación y categoría | **Interesante y nadie lo ha pedido.** Hoy tenemos cero visibilidad del coste de WhatsApp |

### El coste operativo, con número

Cada saliente genera 2-3 eventos de estado, y todos entran por el workflow principal.

| Momento | Salientes | Ejecuciones extra estimadas |
|---|---|---|
| Pico de julio | **473 / semana** | ~1.000-1.400 / semana |
| Hoy (PROD tranquilo) | **7 / semana** | ~20 / semana |

Total histórico: 1.928 mensajes.

**Consecuencia de calendario: construirlo ahora es barato y construirlo con la landing abierta no.**
Con 7 mensajes por semana, un fallo en la separación estados/mensajes se nota y no hace daño. Con
473, multiplica ejecuciones del bot en producción.

### Veredicto

**Sí vale la pena, recortado a `failed` y `delivered`, y la ventana es ahora.**

- `read` fuera desde el diseño, no «para más adelante».
- `pricing` se captura y se guarda aunque todavía no se use: llega gratis en el mismo payload y hoy
  no tenemos ni idea de lo que cuesta cada conversación.
- El resto del plan de arriba (contrato congelado, secreto dedicado, matriz pineada en STG) sigue
  vigente sin cambios.
