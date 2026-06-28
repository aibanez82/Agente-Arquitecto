# Flujo de Datos — Dashboard de Leads Qualitas

## Endpoints y sus fuentes

| Endpoint | Fuente | Qué devuelve |
|---|---|---|
| `/api/db-leads` | Heroku Postgres | Leads con estado, cotización, sesión WA, póliza, hitos n8n |
| `/api/analytics` | GA4 | Usuarios, sesiones, dispositivos, campañas, ciudades, hora |
| `/api/meta-analytics` | Meta Business API | Enviados, entregados, leídos, respondidos por plantilla |

## JOIN principal entre tablas

```sql
qualitas_lead l
LEFT JOIN qualitas_cotizacion c ON l.cotizacion_id = c.id
LEFT JOIN whatsapp_sessions ws ON ws.quotation_id = c.id
LEFT JOIN qualitas_polizaemitida p ON p.cotizacion_id = c.id
LEFT JOIN (
  SELECT session_id,
    BOOL_OR(message ILIKE '%confirmó cobertura%') AS confirmo_cobertura,
    BOOL_OR(message ILIKE '%datos personales%')   AS dio_datos_personales,
    COUNT(*) FILTER (WHERE role = 'human')        AS human_msg_count
  FROM n8n_chat_histories
  GROUP BY session_id
) nch ON nch.session_id = ws.session_id
```

## Reglas críticas de columnas

- Usar `l.canal_atencion` (NO `l.canal`)
- Usar `c.codigo_postal` (NO `c.cp`)
- Join cotizacion→lead: `l.cotizacion_id = c.id` (NO `c.lead_id`)

## Timezone

Postgres devuelve `timestamp without time zone`. Al serializar a JSON queda como ISO string con `Z`.
Todas las conversiones usan `America/Mexico_City` (UTC-6, sin horario de verano desde 2023).

Helpers en `lib/dateRanges.js`:
- `toMXDateStr(str)` — convierte a YYYY-MM-DD en CDMX
- `isDateInRange(dateStr, start, end)` — usa toMXDateStr internamente
