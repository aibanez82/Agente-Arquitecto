# Arquitectura — Dashboard de Leads Qualitas

> ## ⚠️ OBSOLETO — no usar como referencia (marcado el 16 ago 2026)
>
> Escrito el 28 jun 2026 y **nunca actualizado desde entonces**. Describe el **Dashboard**, no el
> ecosistema completo, y contiene al menos un error activo: el JOIN sobre `n8n_chat_histories` usa
> `message ILIKE '…'` y `role = 'human'`, cuando esa columna es **JSONB** (`message->>'type'`,
> `message->>'content'`) desde la migración de PROD del 10-11 jul, y los hitos reales se detectan
> con otro copy («Procederemos con Cobertura…»).
>
> **Fuente de verdad vigente:** `CLAUDE.md` §«Esquema de base de datos» y §«Regla de estado real de
> un lead`. Detectado al buscarle destino a la fase ámbar de la higiene
> (`docs/protocolos/higiene-claude-md.md`): mover contenido bueno a un doc obsoleto no es higiene,
> es degradación.

> Última actualización: junio 2026

## Vista general

Funnel completo:
Google Ads → Landing → Django backend (Heroku) → n8n WhatsApp agent → cliente → póliza emitida → pago confirmado

## Componentes

| Componente | Tecnología | Rol |
|---|---|---|
| Google Analytics 4 | GA4 | Tráfico de la landing por canal |
| Heroku Postgres | PostgreSQL | Fuente de verdad de leads y conversaciones |
| `/api/db-leads` | Next.js API Route | Lee Postgres, normaliza timestamps a ISO Z |
| `/api/analytics` | Next.js API Route | Lee GA4 por rango de fechas |
| Dashboard | React (Next.js, Vercel) | UI: resumen, kanban, funnel, tabla de leads |

## Principios de diseño

1. El dashboard nunca escribe — solo lectura, siempre.
2. Aislamiento de producción: credencial `readonly_leads` acotada a tablas necesarias.
3. Filtrado de período centralizado en cliente con helpers de timezone CDMX.
4. Timezone: America/Mexico_City (UTC-6, sin horario de verano desde 2023).
