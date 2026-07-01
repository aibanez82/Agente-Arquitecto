# Spec para Code Agent — Dashboard: mostrar los envíos reales de WhatsApp en el modal del lead

> Autor: Arquitecto-IA-Qualitas · Fecha: 1 julio 2026
> Repo destino: `aibanez82/Dashboard_seguroautoqualitas`
> Ejecutor: Agente Dashboard (Nivel 3)

---

## Problema

El modal de un lead en el Dashboard muestra "Saludo inicial enviado por WhatsApp" y luego
"0 mensajes / el cliente aún no ha respondido" hasta que el cliente contesta. Su panel de
conversación se alimenta de **`n8n_chat_histories`**, que está vacío mientras el cliente no
responde.

**Pero Django sí envía más mensajes** (p. ej. el follow-up `cotizacion_followup_15m`) y los
registra en la tabla **`qualitas_whatsappmessage`**. El Dashboard **no lee esa tabla**, así que
oculta esos envíos. Resultado: un lead que recibió saludo + follow-up aparece como si solo se le
hubiera mandado el saludo. Es imposible auditar qué se le envió a un lead sin entrar a la BD.

### Evidencia (lead 952, cotización 2404)

El Dashboard mostraba solo el saludo. En `qualitas_whatsappmessage` había **dos** envíos, ambos
aceptados por Meta:

```
14:53:56  cotizacion_inicial_con_imagen  status=sent  wamid ...52C9
15:10:56  cotizacion_followup_15m        status=sent  wamid ...97CA  (Meta: "accepted")
```

---

## Solución

Añadir al modal del lead una sección **"Mensajes enviados"** que lea de `qualitas_whatsappmessage`
y liste todos los envíos salientes (y entrantes si los hubiera) para ese lead/cotización, con su
estado real. Es complementaria al historial de conversación de n8n, no lo sustituye.

### Fuente de datos — tabla `qualitas_whatsappmessage`

Columnas relevantes (ya existentes en producción):

| Columna | Tipo | Uso en el Dashboard |
|---|---|---|
| `template_name` | varchar | Nombre de la plantilla (ej. `cotizacion_followup_15m`) |
| `direction` | varchar | `OUTBOUND` / (inbound si existiera) |
| `status` | varchar | `sent` / `failed` |
| `sent_at` | timestamptz | Hora de envío (mostrar en `America/Mexico_City`) |
| `failed_at` | timestamptz | Hora de fallo si aplica |
| `error_code` | varchar | Código de error de Meta (ej. `132018`) |
| `error_message` | text | Mensaje de error legible |
| `provider_message_id` | varchar | `wamid...` — acuse de Meta (prueba de envío) |
| `lead_id` | bigint | FK al lead |
| `cotizacion_id` | bigint | FK a la cotización |

### Query sugerida

```sql
SELECT template_name, direction, status,
       sent_at, failed_at, error_code, error_message, provider_message_id
FROM qualitas_whatsappmessage
WHERE lead_id = $1        -- o cotizacion_id = $2, según cómo abra el modal
ORDER BY COALESCE(sent_at, queued_at) ASC;
```

> Usar `lib/db.js` del Dashboard (nunca conexión ad-hoc). Read-only.

### UI en el modal

- Nueva sección **"Mensajes enviados (WhatsApp)"** encima o al lado del historial de conversación.
- Una fila por envío:
  - Hora en CDMX (`America/Mexico_City`).
  - Etiqueta legible de la plantilla (mapear nombres técnicos → texto humano, ej.
    `cotizacion_followup_15m` → "Recordatorio 15 min").
  - Badge de estado: **sent** (verde) / **failed** (rojo, mostrando `error_message`).
- Si el lead tiene envíos pero 0 respuestas, dejar claro que **le hemos escrito N veces** y sigue
  sin responder (hoy el copy "0 mensajes" da a entender que no se le mandó nada más que el saludo).

### Criterios de aceptación

1. El modal del lead 952 (o cualquiera con follow-up) muestra **los 2 envíos** (inicial + follow-up
   15m), no solo el saludo.
2. Un envío `failed` se muestra en rojo con su `error_message`.
3. La sección funciona aunque `n8n_chat_histories` esté vacío para ese lead.
4. Las horas se muestran en `America/Mexico_City`.
5. No se rompe la vista de conversación existente (n8n) — es aditiva.

### Notas

- Esta tabla es la **fuente de verdad de lo que Django envió**. El historial de n8n sigue siendo la
  fuente de la **conversación con el cliente** una vez responde. Son complementarios.
- No exponer `raw_response` en la UI (puede traer datos crudos de Meta); usar `provider_message_id`
  como prueba de envío si se quiere mostrar algo.
