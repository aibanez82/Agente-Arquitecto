# Flujo de datos del ecosistema Quálitas/Insurmind

> Destino de la prosa descriptiva que salió de `CLAUDE.md` en la higiene del 17 ago 2026.
> **Las reglas anti-error se quedaron en `CLAUDE.md`** (§«Reglas críticas de arquitectura»,
> §«Esquema de base de datos», §«Regla de estado real de un lead»): aquí vive el detalle que se
> consulta, no el que hay que tener presente en cada turno.
>
> Sustituye a la versión del 28 jun, que describía solo el Dashboard y enseñaba un JOIN incorrecto
> sobre `n8n_chat_histories`. Todo lo de este documento está **verificado contra la fuente viva** en
> las fechas que se indican; cuando se toque, verificar de nuevo y anotar la fecha.

## 1. El funnel, de punta a punta

```
Landing (Wagtail/Django · Heroku)
    ↓ formulario completado
Django → crea qualitas_lead + qualitas_cotizacion en Postgres
Django → 1er WhatsApp directo (Meta Graph API) + INSERT whatsapp_sessions (SQL crudo)
         ↓ cliente responde
    n8n (Hostinger)
    ├── Lee/escribe whatsapp_sessions → Postgres DIRECTO
    ├── Lee/escribe n8n_chat_histories → Postgres DIRECTO
    ├── Claude Haiku — jailbreak detection + intent router
    ├── Claude Sonnet — agente conversacional principal
    └── Meta Cloud API → WhatsApp → Lead

Dashboard (Next.js · Vercel)
    ├── Lee Postgres directamente (read-only, sin pasar por Django)
    └── Botón "Tomar conversación" → webhook n8n → INSERT n8n_chat_histories + Send WhatsApp

Observabilidad:
├── GA4 → visitas landing
├── Meta Business API → métricas WhatsApp (enviados/leídos/respondidos)
├── Dashboard → funnel completo
└── n8n PROD "Monitor Qualitas SIO PROD" → chequeo cada 10 min contra el SOAP real de
    Quálitas, alerta por Telegram si cae (repetida mientras siga caído) y al recuperarse
```

## 2. El JOIN real que corre en producción

Extraído de `Dashboard_seguroautoqualitas:apps/operacion/pages/api/db-leads.js` en `main` (`d7f89d1`,
el SHA que sirve producción el 17 ago 2026). **Esta es la forma correcta; la de la versión anterior
de este documento no lo era.**

```sql
FROM qualitas_lead l
LEFT JOIN qualitas_cotizacion c          ON l.cotizacion_id = c.id
LEFT JOIN qualitas_asegurado a           ON a.cotizacion_id = c.id
LEFT JOIN whatsapp_sessions ws           ON ws.quotation_id = c.id
LEFT JOIN whatsapp_sessions_archive wsa  ON wsa.quotation_id = c.id
LEFT JOIN qualitas_polizaemitida p       ON l.poliza_id = p.id
```

Tres trampas, y las tres devuelven filas si te equivocas — por eso están también en `CLAUDE.md`:

- el lead apunta a la cotización (`l.cotizacion_id = c.id`), **no** al revés (`c.lead_id` no existe);
- la póliza cuelga del **lead** (`l.poliza_id = p.id`), no de la cotización;
- existe `whatsapp_sessions_archive`, así que una sesión ausente en `whatsapp_sessions` puede estar
  archivada y no perdida.

## 3. Hitos: cómo se derivan de `n8n_chat_histories`

`message` es **JSONB**: `message->>'type'` (`human` / `ai`) y `message->>'content'`. Ordenar por
`id`. Los hitos se derivan con `BOOL_OR` sobre el texto, y **eso es frágil por diseño**: dependen del
copy del bot.

Detectores **verificados el 16 ago 2026 contra el workflow vivo de PROD** (API n8n,
`BtOaZm7WlZT-24V7hqCnF`):

| hito | detección correcta |
|---|---|
| `has_responded` | mensaje `human` con marcador `USER INPUT STARTS BELOW`, o texto sin wrapper `[CTX:` (ver `qualitas-issues#41`) |
| `confirmo_cobertura` | `ai` + `ILIKE '%continuamos con%'` + `'%cobertura%'` |
| `dio_datos_personales` | `ai` + `'%tengo%'` + `'%Nombre:%'` |
| `dio_vin` | `ai` + `'%Placas%'` + `'%Serie:%'` |
| `dio_domicilio` | `ai` + `'%*Domicilio:*%'` |
| `poliza_emitida_wa` | `ai` + `'%emitida exitosamente%'` |

**Precedente que obliga a re-verificar al tocar copy:** hasta el 16 ago, `confirmo_cobertura` y
`dio_domicilio` buscaban frases que el bot no dice —`"ha seleccionado"` y `"Su domicilio"` en el
Dashboard, `"Procederemos con Cobertura"` y `"domicilio registrado es"` aquí— y llevaban tiempo
**siempre en `false`** sin que saltara ningún error. Detalle: `qualitas-issues#82`.

## 4. n8n por dentro

Los workflows exportados viven en `docs/n8n-workflows/` de este repo y son la única red de
seguridad: el backup automático está descontinuado (`docs/architecture/backup-policy-n8n.md`).
**Exportar y commitear cada vez que se modifique uno en producción.**

El bot principal tiene tres nodos que llaman a Claude: **Jailbreak detection** (Haiku), **Intent
Router** (Haiku) y el **agente conversacional principal** (Sonnet).

n8n escribe a Postgres directamente con la credencial `"Postgres account"`:

| nodo | qué hace |
|---|---|
| `Check Session Exists` / `Load Session` | SELECT sobre `whatsapp_sessions` |
| `Update Activity` | UPDATE de `last_activity` |
| `Postgres Chat Memory` | lee y escribe `n8n_chat_histories` |

El **workflow proactivo** recibe `POST /webhook/proactive-wa-message` del Dashboard, inserta en
`n8n_chat_histories` y envía el WhatsApp. Detalle: `docs/protocolos/workflow-proactivo-dashboard.md`.

## 5. Quién escribe qué

| tabla | escribe | contiene |
|---|---|---|
| `qualitas_lead` | Django | estado del lead, canal, fechas |
| `qualitas_cotizacion` | Django | datos del auto, contacto, CP, precio |
| `qualitas_polizaemitida` | Django | número de póliza, `estatus_pago`, precio |
| `whatsapp_sessions` | n8n (directo) | `conversation_phase`, `last_activity`, `captured_data` |
| `n8n_chat_histories` | n8n (Postgres Chat Memory) | historial de mensajes — fuente fiable de hitos |

El Dashboard **solo lee**; escribe únicamente de forma indirecta, vía el webhook proactivo de n8n.
