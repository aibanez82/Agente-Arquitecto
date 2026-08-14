# Caso de prueba E2E — Descuentos en STG

**14 ago 2026 · Arquitecto · Para: Alberto.** Convierte «encendido» en «funciona».

**Precondiciones ya verificadas** (no hay que hacer nada): módulo y ambas fases en `true` · trigger
`quote_sent:2` → programa **`CHECKPOINT_INTRO_35` (35 %)** · `WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED=true`
(v222) · los 4 workflows publicados · políticas `quote_sent` 1/2/3 activas con **`delay_mins = 1`**.

**Punto de partida limpio:** 0 ofertas, 0 aplicaciones, 0 filas en el ledger de checkpoint, 0 reservas
de outbound. Cualquier fila que aparezca la ha creado esta prueba.

---

## Cómo dispara la Fase 1, para saber qué esperar

Django emite follow-ups del checkpoint `quote_sent` en tres intentos, uno por minuto. **El intento 1 es
un recordatorio normal. El intento 2 es el que lleva la oferta de descuento.** El intento 3 es la
despedida. Así que la prueba consiste en llegar a `quote_sent` y **esperar al segundo mensaje**.

---

## Ejecución

### Paso 1 — crear el lead por el flujo real

Rellena el formulario en la landing de STG con **un móvil tuyo con WhatsApp**:

```
https://hyl-wai-stg-d1085ad74dbf.herokuapp.com
```

Django creará `qualitas_lead` + `qualitas_cotizacion` y te mandará el **primer WhatsApp** desde el
número de STG (`+52 1 56 3030 5518`).

> Usa un teléfono **que no esté ya en `whatsapp_sessions`** — si reutilizas uno, entra el retarget de
> sesión y la prueba mide otra cosa.

**Verificar:**

```sql
SELECT ws.session_id, ws.phone_number, ws.quotation_id, ws.lead_id,
       ws.conversation_phase, ws.status, ws.created_at
FROM public.whatsapp_sessions ws
ORDER BY ws.created_at DESC LIMIT 3;
```

Anota el `session_id` — lo usarás en todas las consultas siguientes.

### Paso 2 — conversar hasta la cotización

Responde por WhatsApp y sigue al bot hasta que **te envíe la cotización**. Ese es el hito
`quote_sent`, el que arma el checkpoint.

**Verificar** (sustituye `<SESSION_ID>`):

```sql
SELECT id, checkpoint, attempt, status, created_at
FROM public.qualitas_leadcheckpointfollowupattempt
WHERE session_id = '<SESSION_ID>'
ORDER BY id;
```

### Paso 3 — esperar al **segundo** follow-up · ⭐ aquí se prueba lo nuevo

Uno por minuto. Cuando llegue el **attempt 2**, debe traer la oferta del **35 %** con dos botones
(aceptar / rechazar). Los textos son los provisionales que puse yo.

**Verificar que se creó la oferta:**

```sql
SELECT o.id, o.state, o.program_id, o.expires_at, o.created_at
FROM public.qualitas_discountoffer o
ORDER BY o.id DESC LIMIT 5;

SELECT id, checkpoint, attempt, status FROM public.qualitas_discountcheckpointledger ORDER BY id DESC LIMIT 5;
```

**Si el attempt 2 llega SIN oferta**, para aquí: el módulo está encendido pero la Fase 1 no engancha, y
es el hallazgo más importante que puede dar esta prueba. Pásame el `attempt` y el `status`.

### Paso 4 — aceptar la oferta

Pulsa el botón de aceptar. Debe desencadenar: recotización en Quálitas (6 llamadas), **un** PDF,
**lead y cotización nuevos**, y una **conversación nueva que hereda el historial**.

**Verificar:**

```sql
-- la aplicación y su resultado
SELECT id, state, offer_id, created_at FROM public.qualitas_discountapplication ORDER BY id DESC LIMIT 3;

-- ¿nacieron lead y cotización nuevos con el 35 %?
SELECT c.id, c.qualitas_percentage, c.precio_total, c.created_at
FROM public.qualitas_cotizacion c ORDER BY c.id DESC LIMIT 3;

-- ¿la conversación nueva heredó el historial?
SELECT session_id, count(*) AS mensajes
FROM public.n8n_chat_histories
WHERE session_id IN (SELECT session_id FROM public.whatsapp_sessions ORDER BY created_at DESC LIMIT 2)
GROUP BY session_id;
```

### Paso 5 — la entrega del PDF

La hace el **worker**, que se despierta cada minuto.

```sql
SELECT id, state, created_at FROM public.n8n_discount_application_poll ORDER BY id DESC LIMIT 3;
SELECT id, outcome, created_at FROM public.n8n_discount_delivery ORDER BY id DESC LIMIT 3;
SELECT dispatch_id, outcome, created_at FROM public.n8n_outbound_dispatch ORDER BY created_at DESC LIMIT 5;
```

**Y la prueba definitiva: que te llegue el PDF por WhatsApp.**

---

## Qué es un PASS

1. Llega el follow-up **2** con la oferta del 35 % y dos botones.
2. Al aceptar: **una** aplicación, **un** PDF, lead y cotización nuevos con `qualitas_percentage = 35`.
3. La conversación nueva **tiene el historial** de la anterior.
4. El PDF **llega por WhatsApp**.
5. `n8n_outbound_dispatch` tiene reservas con outcome terminal — **el fence está trabajando**.

## Qué NO debe pasar, y qué significa si pasa

| Síntoma | Qué significa |
|---|---|
| **Dos PDF** o dos mensajes iguales | falló el «exactamente una vez» del fence |
| La conversación nueva **sin historial** | falló el cutover / herencia (E6) |
| El bot **canta el precio viejo** tras aceptar | el *gotcha* de memoria — se ordenó cerrar el 10 ago; sería una regresión |
| `qualitas_percentage` distinto de 35 | el trigger apunta a otro programa |
| Error de Quálitas `0007 — Descuento fuera de Rango` | **el 35 % no lo acepta Quálitas.** Es el riesgo que quedó fuera al excluir la sonda: no es un fallo del módulo, es el rango real |
| Nada en `n8n_outbound_dispatch` | los envíos no pasan por el fence: el import no quedó como creemos |

## Si algo falla a mitad

No hace falta rollback: **apaga y sigue con lo demás.**

```sql
UPDATE public.qualitas_discountsettings
   SET module_enabled = false, phase_1_checkpoint_enabled = false, phase_2_intent_enabled = false;
```

Todo lo demás (workflows, migraciones, fence) queda como está y no estorba con el módulo apagado.
